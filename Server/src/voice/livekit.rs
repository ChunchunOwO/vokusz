use crate::error::AppError;
use futures_util::StreamExt;
use livekit_api::access_token::{AccessToken, VideoGrants};
use livekit_api::services::room::{CreateRoomOptions, RoomClient, UpdateParticipantOptions};
use std::sync::Arc;

#[derive(Clone)]
pub struct LiveKitClient {
    internal_url: String,
    external_url: String,
    api_key: String,
    api_secret: String,
    room_client: Arc<RoomClient>,
}

impl LiveKitClient {
    pub fn new(internal_url: &str, external_url: &str, api_key: &str, api_secret: &str) -> Self {
        Self {
            internal_url: internal_url.to_string(),
            external_url: external_url.to_string(),
            api_key: api_key.to_string(),
            api_secret: api_secret.to_string(),
            room_client: Arc::new(RoomClient::with_api_key(internal_url, api_key, api_secret)),
        }
    }

    pub fn internal_url(&self) -> &str {
        &self.internal_url
    }

    pub fn external_url(&self) -> &str {
        &self.external_url
    }

    pub fn room_name(channel_id: &str) -> String {
        format!("channel_{channel_id}")
    }

    pub async fn generate_token(
        &self,
        pool: &sqlx::AnyPool,
        auth: &crate::middleware::auth::AuthUser,
        display_name: &str,
        channel_id: &str,
    ) -> Result<String, AppError> {
        let (speak, stream) = publishing_permissions(pool, channel_id, auth).await;
        let sources = publishing_sources(speak, stream);
        let room_name = Self::room_name(channel_id);
        AccessToken::with_api_key(&self.api_key, &self.api_secret)
            .with_ttl(std::time::Duration::from_secs(6 * 60 * 60))
            .with_identity(&auth.user_id)
            .with_name(display_name)
            .with_grants(VideoGrants {
                room_join: true,
                room: room_name,
                can_publish: !sources.is_empty(),
                can_publish_sources: sources.iter().map(|(_, name)| name.to_string()).collect(),
                can_subscribe: true,
                can_publish_data: true,
                ..Default::default()
            })
            .to_jwt()
            .map_err(|e| AppError::Internal(format!("failed to generate livekit token: {}", e)))
    }

    pub async fn refresh_channel_permissions(
        &self,
        state: &crate::state::AppState,
        channel_id: &str,
    ) {
        let users: Vec<String> = state
            .voice_states
            .iter()
            .filter(|v| v.channel_id.as_deref() == Some(channel_id))
            .map(|v| v.user_id.clone())
            .collect();
        futures_util::stream::iter(users)
            .for_each_concurrent(8, |user_id| async move {
                let is_admin = crate::db::users::get_user(&state.db, &user_id)
                    .await
                    .map(|user| user.is_admin && !user.disabled)
                    .unwrap_or(false);
                let auth = crate::middleware::auth::AuthUser {
                    user_id: user_id.clone(),
                    is_admin,
                    is_bot: false,
                    is_guest: false,
                    guest_space_id: None,
                };
                let (speak, stream) = publishing_permissions(&state.db, channel_id, &auth).await;
                let sources = publishing_sources(speak, stream);
                let mut options = UpdateParticipantOptions::default();
                let permission = options.permission.get_or_insert_with(Default::default);
                permission.can_subscribe = true;
                permission.can_publish_data = true;
                permission.can_publish = !sources.is_empty();
                permission.can_publish_sources =
                    sources.iter().map(|(source, _)| *source).collect();
                if !matches!(
                    tokio::time::timeout(
                        std::time::Duration::from_secs(5),
                        self.room_client.update_participant(
                            &Self::room_name(channel_id),
                            &user_id,
                            options
                        )
                    )
                    .await,
                    Ok(Ok(_))
                ) {
                    // Fail closed: reconnecting obtains a fresh token with the new grants.
                    crate::security::revoke_channel_voice_access(state, channel_id, Some(&user_id))
                        .await;
                }
            })
            .await;
    }

    /// Preflight connectivity check — called at startup to verify the server
    /// can reach LiveKit's Twirp API. Fails fast with a clear error instead of
    /// silently timing out on the first voice join.
    pub async fn check_connectivity(&self) -> Result<(), String> {
        // List rooms is a lightweight read-only Twirp call.
        match tokio::time::timeout(
            std::time::Duration::from_secs(5),
            self.room_client.list_rooms(Vec::new()),
        )
        .await
        {
            Ok(Ok(_)) => Ok(()),
            Ok(Err(e)) => Err(format!("LiveKit API error at {}: {}", self.internal_url, e)),
            Err(_) => Err(format!(
                "LiveKit unreachable at {} (timed out after 5s)",
                self.internal_url
            )),
        }
    }

    pub async fn ensure_room(&self, channel_id: &str) -> Result<(), AppError> {
        let room_name = Self::room_name(channel_id);
        self.room_client
            .create_room(
                &room_name,
                CreateRoomOptions {
                    empty_timeout: 300,
                    ..Default::default()
                },
            )
            .await
            .map_err(|e| AppError::Internal(format!("failed to create livekit room: {}", e)))?;
        Ok(())
    }

    pub async fn try_remove_participant(&self, channel_id: &str, user_id: &str) -> bool {
        let room_name = Self::room_name(channel_id);
        match tokio::time::timeout(
            std::time::Duration::from_secs(5),
            self.room_client.remove_participant(&room_name, user_id),
        )
        .await
        {
            Ok(Ok(_)) => true,
            Ok(Err(livekit_api::services::ServiceError::Twirp(
                livekit_api::services::TwirpError::Twirp(error),
            ))) if error.code == "not_found" => true,
            result => {
                tracing::warn!(
                    "LiveKit eviction failed for {user_id} from {room_name}: {result:?}"
                );
                false
            }
        }
    }

    pub async fn delete_room_if_empty(&self, channel_id: &str) {
        let room_name = Self::room_name(channel_id);
        match self.room_client.list_participants(&room_name).await {
            Ok(participants) => {
                if participants.is_empty() {
                    if let Err(e) = self.room_client.delete_room(&room_name).await {
                        tracing::warn!("Failed to delete empty room {}: {}", room_name, e);
                    } else {
                        tracing::debug!("Deleted empty LiveKit room {}", room_name);
                    }
                }
            }
            Err(e) => {
                tracing::warn!("Failed to list participants for room {}: {}", room_name, e);
            }
        }
    }
}

async fn publishing_permissions(
    pool: &sqlx::AnyPool,
    channel_id: &str,
    auth: &crate::middleware::auth::AuthUser,
) -> (bool, bool) {
    use crate::middleware::permissions::require_channel_permission;
    let speak = require_channel_permission(pool, channel_id, auth, "speak")
        .await
        .is_ok();
    let stream = require_channel_permission(pool, channel_id, auth, "stream")
        .await
        .is_ok();
    if let Ok(channel) = crate::db::channels::get_channel_row(pool, channel_id).await {
        if let Some(space_id) = channel.space_id {
            if let Ok(member) =
                crate::db::members::get_member_row(pool, &space_id, &auth.user_id).await
            {
                if crate::middleware::permissions::is_timed_out(member.timed_out_until.as_deref()) {
                    return (false, false);
                }
                return (speak && !member.mute, stream);
            }
        }
    }
    (speak, stream)
}

// LiveKit TrackSource values and JWT source names from the LiveKit protocol.
fn publishing_sources(speak: bool, stream: bool) -> Vec<(i32, &'static str)> {
    let mut sources = Vec::new();
    if speak {
        sources.push((2, "microphone"));
    }
    if stream {
        sources.extend([
            (1, "camera"),
            (3, "screen_share"),
            (4, "screen_share_audio"),
        ]);
    }
    sources
}
