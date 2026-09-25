use crate::models::voice::VoiceState;
use crate::state::AppState;

/// Join a voice channel. Returns the new VoiceState and the previous channel_id if the user moved.
/// `space_id` is `None` for DM/group DM calls, which have no parent space.
#[allow(clippy::too_many_arguments)]
pub fn join_voice_channel(
    state: &AppState,
    user_id: &str,
    space_id: Option<&str>,
    channel_id: &str,
    session_id: &str,
    self_mute: bool,
    self_deaf: bool,
    self_video: bool,
    self_stream: bool,
) -> (VoiceState, Option<String>) {
    let previous_channel = state
        .voice_states
        .get(user_id)
        .and_then(|vs| vs.channel_id.clone());

    let voice_state = VoiceState {
        user_id: user_id.to_string(),
        space_id: space_id.map(|s| s.to_string()),
        channel_id: Some(channel_id.to_string()),
        session_id: session_id.to_string(),
        deaf: false,
        mute: false,
        self_deaf,
        self_mute,
        self_stream,
        self_video,
        suppress: false,
    };

    state
        .voice_states
        .insert(user_id.to_string(), voice_state.clone());

    (voice_state, previous_channel)
}

/// Update an existing voice state's flags in-place without changing channel or session.
/// Returns the updated VoiceState, or None if the user is not in voice.
pub fn update_voice_state(
    state: &AppState,
    user_id: &str,
    self_mute: bool,
    self_deaf: bool,
    self_video: bool,
    self_stream: bool,
) -> Option<VoiceState> {
    let mut entry = state.voice_states.get_mut(user_id)?;
    let vs = entry.value_mut();
    vs.self_mute = self_mute;
    vs.self_deaf = self_deaf;
    vs.self_video = self_video;
    vs.self_stream = self_stream;
    Some(vs.clone())
}

/// Leave voice. Returns the old VoiceState if the user was in voice.
pub fn leave_voice_channel(state: &AppState, user_id: &str) -> Option<VoiceState> {
    take_membership(&state.voice_states, user_id, None)
}

/// Drop [user_id] only when they are still in [channel_id].
///
/// REST leave names the channel it is leaving. Join of the next channel updates
/// the same map entry first, so a leave that arrives afterwards must not remove
/// the new membership or the LiveKit cleanup will evict the room just joined.
pub fn leave_voice_channel_if_current(
    state: &AppState,
    user_id: &str,
    channel_id: &str,
) -> Option<VoiceState> {
    take_membership(&state.voice_states, user_id, Some(channel_id))
}

/// [only_if_channel] set: no-op unless that is still the user's channel.
/// Unset: remove whatever membership they have (gateway disconnect).
pub fn take_membership(
    states: &dashmap::DashMap<String, VoiceState>,
    user_id: &str,
    only_if_channel: Option<&str>,
) -> Option<VoiceState> {
    if let Some(channel_id) = only_if_channel {
        return states
            .remove_if(user_id, |_, vs| vs.channel_id.as_deref() == Some(channel_id))
            .map(|(_, vs)| vs);
    }
    states.remove(user_id).map(|(_, vs)| vs)
}

/// Get all voice states for a given channel.
pub fn get_channel_voice_states(state: &AppState, channel_id: &str) -> Vec<VoiceState> {
    state
        .voice_states
        .iter()
        .filter(|entry| entry.value().channel_id.as_deref() == Some(channel_id))
        .map(|entry| entry.value().clone())
        .collect()
}

/// Get all voice states for a given space.
pub fn get_space_voice_states(state: &AppState, space_id: &str) -> Vec<VoiceState> {
    state
        .voice_states
        .iter()
        .filter(|entry| entry.value().space_id.as_deref() == Some(space_id))
        .map(|entry| entry.value().clone())
        .collect()
}

/// Get a single user's voice state.
pub fn get_user_voice_state(state: &AppState, user_id: &str) -> Option<VoiceState> {
    state.voice_states.get(user_id).map(|vs| vs.clone())
}

#[cfg(test)]
mod tests {
    use super::*;
    use dashmap::DashMap;

    fn membership(channel: &str) -> VoiceState {
        VoiceState {
            user_id: "user".to_string(),
            space_id: Some("space".to_string()),
            channel_id: Some(channel.to_string()),
            session_id: "sess".to_string(),
            deaf: false,
            mute: false,
            self_deaf: false,
            self_mute: false,
            self_stream: false,
            self_video: false,
            suppress: false,
        }
    }

    #[test]
    fn delayed_leave_for_the_previous_channel_keeps_the_new_one() {
        let states = DashMap::new();
        states.insert("user".to_string(), membership("a"));
        // Join of B lands first. The REST leave of A is still in flight.
        states.insert("user".to_string(), membership("b"));

        assert!(take_membership(&states, "user", Some("a")).is_none());
        assert_eq!(
            states.get("user").unwrap().channel_id.as_deref(),
            Some("b")
        );

        let left = take_membership(&states, "user", Some("b")).unwrap();
        assert_eq!(left.channel_id.as_deref(), Some("b"));
        assert!(states.get("user").is_none());
    }
}
