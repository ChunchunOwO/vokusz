use axum::extract::{Path, State};
use axum::Json;

use crate::db;
use crate::error::AppError;
use crate::gateway::events::GatewayBroadcast;
use crate::middleware::auth::AuthUser;
use crate::middleware::permissions::{
    require_channel_permission, require_dm_access, require_membership, require_not_timed_out,
};
use crate::models::voice::VoiceState;
use crate::state::AppState;
use crate::voice;

/// Whether a channel type is a DM or group DM (no parent space).
pub(crate) fn is_dm_channel(channel_type: &str) -> bool {
    channel_type == "dm" || channel_type == "group_dm"
}

pub async fn list_voice_regions(
    state: State<AppState>,
    Path(space_id): Path<String>,
    auth: AuthUser,
) -> Result<Json<serde_json::Value>, AppError> {
    require_membership(&state.db, &space_id, &auth.user_id).await?;
    let regions = vec![serde_json::json!({
        "id": "livekit",
        "name": "LiveKit",
        "optimal": true,
        "custom": false
    })];
    Ok(Json(serde_json::json!({ "data": regions })))
}

pub async fn get_voice_status(
    state: State<AppState>,
    Path(channel_id): Path<String>,
    auth: AuthUser,
) -> Result<Json<serde_json::Value>, AppError> {
    require_channel_permission(&state.db, &channel_id, &auth, "view_channel").await?;
    let states = voice::state::get_channel_voice_states(&state, &channel_id);
    Ok(Json(serde_json::json!({ "data": states })))
}

#[derive(serde::Deserialize)]
pub struct JoinVoiceRequest {
    pub self_mute: Option<bool>,
    pub self_deaf: Option<bool>,
}

pub async fn join_voice(
    state: State<AppState>,
    Path(channel_id): Path<String>,
    auth: AuthUser,
    Json(input): Json<JoinVoiceRequest>,
) -> Result<Json<serde_json::Value>, AppError> {
    // Participant access (DM) or channel `connect` permission (space) is
    // enforced here; for DMs this returns an empty space_id.
    require_channel_permission(&state.db, &channel_id, &auth, "connect").await?;

    // Look up channel to confirm it exists and get space_id
    let channel = db::channels::get_channel_row(&state.db, &channel_id).await?;

    // DM/group DM calls have no parent space and aren't a "voice" channel type;
    // space channels must be voice and gate on the member's timeout status.
    let space_id: Option<String> = if is_dm_channel(&channel.channel_type) {
        None
    } else {
        if channel.channel_type != "voice" {
            return Err(AppError::BadRequest("channel_not_voice".to_string()));
        }
        let sid = channel
            .space_id
            .clone()
            .ok_or_else(|| AppError::BadRequest("channel_has_no_space".to_string()))?;
        require_not_timed_out(&state.db, &sid, &auth).await?;
        Some(sid)
    };

    let session_id = crate::snowflake::generate();
    let self_mute = input.self_mute.unwrap_or(false);
    let self_deaf = input.self_deaf.unwrap_or(false);

    let (voice_state, previous_channel) = voice::state::join_voice_channel(
        &state,
        &auth.user_id,
        space_id.as_deref(),
        &channel_id,
        &session_id,
        self_mute,
        self_deaf,
        false,
        false,
    );

    let lk = state
        .livekit_client
        .as_ref()
        .ok_or_else(|| AppError::BadRequest("voice_not_configured".to_string()))?;

    // The previous room is already gone from voice state. Cleaning it up
    // must not sit on the join response — that HTTP round trip is what
    // makes switching channels feel slow.
    if let Some(prev_ch) = previous_channel.filter(|previous| previous != &channel_id) {
        if !state.test_mode {
            let lk = lk.clone();
            let user_id = auth.user_id.clone();
            tokio::spawn(async move {
                lk.try_remove_participant(&prev_ch, &user_id).await;
                lk.delete_room_if_empty(&prev_ch).await;
            });
        }
    }

    // Broadcast voice.state_update to the space (space channels) or to the DM
    // participants (DM/group DM calls).
    broadcast_voice_state_update(&state, &channel_id, space_id.as_deref(), &voice_state).await;

    let user_fut = db::users::get_user(&state.db, &auth.user_id);
    let user = if state.test_mode {
        user_fut.await?
    } else {
        let (room, user) = tokio::join!(lk.ensure_room(&channel_id), user_fut);
        room?;
        user?
    };
    let display_name = user.display_name.as_deref().unwrap_or(&user.username);
    let token = lk.generate_token(&state.db, &auth, display_name, &channel_id).await?;
    Ok(Json(serde_json::json!({
        "data": {
            "voice_state": voice_state,
            "backend": "livekit",
            "livekit_url": lk.external_url(),
            "token": token
        }
    })))
}

pub async fn leave_voice(
    state: State<AppState>,
    Path(channel_id): Path<String>,
    auth: AuthUser,
) -> Result<Json<serde_json::Value>, AppError> {
    require_channel_permission(&state.db, &channel_id, &auth, "connect").await?;
    let old_state =
        voice::state::leave_voice_channel_if_current(&state, &auth.user_id, &channel_id);

    if let Some(ref vs) = old_state {
        if let Some(ref left_channel) = vs.channel_id {
            let left_state = VoiceState {
                user_id: auth.user_id.clone(),
                space_id: vs.space_id.clone(),
                channel_id: None,
                session_id: vs.session_id.clone(),
                deaf: false,
                mute: false,
                self_deaf: false,
                self_mute: false,
                self_stream: false,
                self_video: false,
                suppress: false,
            };
            // Notify the space, or the DM participants when there's no space.
            broadcast_voice_state_update(&state, left_channel, vs.space_id.as_deref(), &left_state)
                .await;

            // Drop the participant after the client has already been told
            // the leave succeeded.
            if !state.test_mode {
                if let Some(lk) = state.livekit_client.clone() {
                    let channel = left_channel.clone();
                    let user_id = auth.user_id.clone();
                    tokio::spawn(async move {
                        lk.try_remove_participant(&channel, &user_id).await;
                        lk.delete_room_if_empty(&channel).await;
                    });
                }
            }

            // For DM calls, if no participants remain in voice the call is over;
            // emit a `call.end` so ringing/active-call UI can clear.
            if vs.space_id.is_none()
                && voice::state::get_channel_voice_states(&state, left_channel).is_empty()
            {
                broadcast_call_event(
                    &state,
                    left_channel,
                    "call.end",
                    serde_json::json!({
                        "channel_id": left_channel,
                        "user_id": auth.user_id,
                    }),
                )
                .await;
            }
        }
    }

    Ok(Json(serde_json::json!({ "data": { "ok": true } })))
}

#[derive(serde::Deserialize, Default)]
pub struct CallSignalBody {
    /// Optional free-form payload echoed to recipients (e.g. ringtone hints).
    pub metadata: Option<serde_json::Value>,
}

/// Shared guard for call-signaling endpoints: the channel must be a DM/group DM
/// and the caller must be a participant. Returns the participant IDs.
async fn require_dm_call_channel(
    state: &AppState,
    channel_id: &str,
    user_id: &str,
) -> Result<Vec<String>, AppError> {
    let channel = db::channels::get_channel_row(&state.db, channel_id).await?;
    if !is_dm_channel(&channel.channel_type) {
        return Err(AppError::BadRequest("channel_not_dm".to_string()));
    }
    require_dm_access(&state.db, channel_id, user_id).await?;
    db::dm_participants::list_participant_ids(&state.db, channel_id).await
}

/// POST /channels/{channel_id}/call/ring — start ringing the other DM
/// participant(s) with an incoming-call notification.
pub async fn ring_call(
    state: State<AppState>,
    Path(channel_id): Path<String>,
    auth: AuthUser,
    body: Option<Json<CallSignalBody>>,
) -> Result<Json<serde_json::Value>, AppError> {
    let participants = require_dm_call_channel(&state, &channel_id, &auth.user_id).await?;
    let metadata = body.and_then(|b| b.0.metadata);
    broadcast_call_event(
        &state,
        &channel_id,
        "call.ring",
        serde_json::json!({
            "channel_id": channel_id,
            "caller_id": auth.user_id,
            "participants": participants,
            "metadata": metadata,
        }),
    )
    .await;
    Ok(Json(serde_json::json!({ "data": { "ok": true } })))
}

/// POST /channels/{channel_id}/call/decline — decline an incoming call.
pub async fn decline_call(
    state: State<AppState>,
    Path(channel_id): Path<String>,
    auth: AuthUser,
) -> Result<Json<serde_json::Value>, AppError> {
    require_dm_call_channel(&state, &channel_id, &auth.user_id).await?;
    broadcast_call_event(
        &state,
        &channel_id,
        "call.decline",
        serde_json::json!({
            "channel_id": channel_id,
            "user_id": auth.user_id,
        }),
    )
    .await;
    Ok(Json(serde_json::json!({ "data": { "ok": true } })))
}

/// POST /channels/{channel_id}/call/cancel — the caller cancels before the
/// callee answers.
pub async fn cancel_call(
    state: State<AppState>,
    Path(channel_id): Path<String>,
    auth: AuthUser,
) -> Result<Json<serde_json::Value>, AppError> {
    require_dm_call_channel(&state, &channel_id, &auth.user_id).await?;
    broadcast_call_event(
        &state,
        &channel_id,
        "call.cancel",
        serde_json::json!({
            "channel_id": channel_id,
            "user_id": auth.user_id,
        }),
    )
    .await;
    Ok(Json(serde_json::json!({ "data": { "ok": true } })))
}

/// Broadcasts a `call.*` signaling event to all participants of a DM channel.
pub(crate) async fn broadcast_call_event(
    state: &AppState,
    channel_id: &str,
    event_type: &str,
    data: serde_json::Value,
) {
    let participant_ids = db::dm_participants::list_participant_ids(&state.db, channel_id)
        .await
        .unwrap_or_default();
    if participant_ids.is_empty() {
        return;
    }
    let event = serde_json::json!({
        "op": 0,
        "type": event_type,
        "data": data,
    });
    if let Some(ref tx) = *state.gateway_tx.read().await {
        let _ = tx.send(GatewayBroadcast {
            space_id: None,
            target_user_ids: Some(participant_ids),
            event,
            intent: "voice_states".to_string(),
            required_permission: None,
        });
    }
}

pub async fn voice_info(state: State<AppState>) -> Json<serde_json::Value> {
    let backend = if state.livekit_client.is_some() {
        "livekit"
    } else {
        "none"
    };
    Json(serde_json::json!({ "backend": backend }))
}

/// Broadcasts a `voice.state_update`. For space channels (`space_id` set) it
/// fans out to the space; for DM/group DM calls (`space_id` is `None`) it
/// targets the channel's participants directly.
pub(crate) async fn broadcast_voice_state_update(
    state: &AppState,
    channel_id: &str,
    space_id: Option<&str>,
    voice_state: &VoiceState,
) {
    let event = serde_json::json!({
        "op": 0,
        "type": "voice.state_update",
        "data": voice_state
    });

    let (space, targets) = match space_id {
        Some(sid) => (Some(sid.to_string()), None),
        None => {
            let ids = db::dm_participants::list_participant_ids(&state.db, channel_id)
                .await
                .unwrap_or_default();
            (None, Some(ids))
        }
    };

    if let Some(ref tx) = *state.gateway_tx.read().await {
        let _ = tx.send(GatewayBroadcast {
            space_id: space,
            target_user_ids: targets,
            event,
            intent: "voice_states".to_string(),
            required_permission: None,
        });
    }
}

#[derive(serde::Deserialize)]
pub struct MoveMemberRequest {
    pub user_id: String,
    pub source_channel_id: String,
}

pub async fn move_member(
    state: State<AppState>, Path(channel_id): Path<String>, auth: AuthUser,
    Json(input): Json<MoveMemberRequest>,
) -> Result<Json<serde_json::Value>, AppError> {
    if state.livekit_client.is_none() {
        return Err(AppError::BadRequest("voice_not_configured".into()));
    }
    let space_id = require_channel_permission(&state.db, &channel_id, &auth, "move_members").await?;
    let destination = db::channels::get_channel_row(&state.db, &channel_id).await?;
    if destination.channel_type != "voice" || space_id.is_empty() {
        return Err(AppError::BadRequest("destination must be a domain voice channel".into()));
    }
    let source = state.voice_states.get(&input.user_id).map(|v| v.value().clone())
        .ok_or_else(|| AppError::BadRequest("member is not in voice".into()))?;
    if source.space_id.as_deref() != Some(&space_id) || source.channel_id.as_deref() != Some(&input.source_channel_id) {
        return Err(AppError::BadRequest("member moved or belongs to another domain".into()));
    }
    require_channel_permission(&state.db, &input.source_channel_id, &auth, "move_members").await?;
    if input.user_id != auth.user_id {
        crate::middleware::permissions::require_hierarchy(&state.db, &space_id, &auth, &input.user_id).await?;
    }
    let user = db::users::get_user(&state.db, &input.user_id).await?;
    if user.disabled { return Err(AppError::Forbidden("account disabled".into())); }
    let target = AuthUser { user_id: input.user_id, is_admin: user.is_admin, is_bot: user.bot, is_guest: false, guest_space_id: None };
    // Reuse normal join authorization, timeout checks, room cleanup and broadcasting.
    let _ = join_voice(state, Path(channel_id), target, Json(JoinVoiceRequest {
        self_mute: Some(source.self_mute), self_deaf: Some(source.self_deaf),
    })).await?;
    Ok(Json(serde_json::json!({"data": null})))
}
