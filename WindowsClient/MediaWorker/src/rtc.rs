use chat_media_worker::devices::parse_device_id;
use livekit::options::{AudioEncoding, TrackPublishOptions};
use livekit::prelude::*;
use livekit::{AudioProcessingOptions, PlatformAudio, PlayoutDeviceId, RecordingDeviceId};
use serde_json::json;
use std::io::{self, Write};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;
use tokio::task::JoinHandle;

pub struct JoinConfig {
    pub url: String,
    pub token: String,
    pub input_device: Option<String>,
    pub output_device: Option<String>,
    pub muted: bool,
    pub deafened: bool,
    pub bitrate_bps: u32,
    pub dtx: bool,
    pub fec: bool,
}

pub struct Session {
    room: Arc<Room>,
    audio: PlatformAudio,
    publication: LocalTrackPublication,
    deaf: Arc<AtomicBool>,
    events: JoinHandle<()>,
    bitrate_bps: u32,
    dtx: bool,
    fec: bool,
}

impl Session {
    pub async fn connect(config: JoinConfig) -> Result<Self, String> {
        let url = config.url.trim();
        let token = config.token.trim();
        if url.is_empty() || token.is_empty() {
            return Err("missing LiveKit url or token".into());
        }
        let audio = PlatformAudio::new().map_err(|err| err.to_string())?;
        select_devices(&audio, config.input_device.as_deref(), config.output_device.as_deref())?;
        let _ = audio.configure_audio_processing(AudioProcessingOptions {
            echo_cancellation: true,
            noise_suppression: true,
            auto_gain_control: true,
            prefer_hardware_processing: false,
        });
        let mut options = RoomOptions::default();
        options.join_retries = 1;
        options.connect_timeout = Duration::from_secs(8);
        let (room, events) = Room::connect(url, token, options)
            .await
            .map_err(|err| format!("LiveKit connect failed: {err}"))?;
        let room = Arc::new(room);
        let track = LocalAudioTrack::create_audio_track("microphone", audio.rtc_source());
        let publication = room
            .local_participant()
            .publish_track(
                LocalTrack::Audio(track),
                publish_options(config.bitrate_bps, config.dtx, config.fec),
            )
            .await
            .map_err(|err| format!("publish microphone failed: {err}"))?;
        if config.muted {
            publication.mute();
        } else {
            publication.unmute();
        }
        let _ = audio.start_recording();
        let deaf = Arc::new(AtomicBool::new(config.deafened));
        if config.deafened {
            set_remote_audio_enabled(&room, false);
        }
        let events = spawn_events(Arc::clone(&room), Arc::clone(&deaf), events);
        Ok(Self {
            room,
            audio,
            publication,
            deaf,
            events,
            bitrate_bps: config.bitrate_bps,
            dtx: config.dtx,
            fec: config.fec,
        })
    }

    pub fn set_mute(&self, muted: bool) {
        if muted {
            self.publication.mute();
        } else {
            self.publication.unmute();
        }
    }

    pub fn set_deaf(&self, deafened: bool) {
        self.deaf.store(deafened, Ordering::Relaxed);
        set_remote_audio_enabled(&self.room, !deafened);
    }

    pub fn set_devices(&self, input: Option<&str>, output: Option<&str>) -> Result<(), String> {
        select_devices(&self.audio, input, output)
    }

    pub async fn set_quality(&mut self, bitrate_bps: u32, dtx: bool, fec: bool) -> Result<(), String> {
        if self.bitrate_bps == bitrate_bps && self.dtx == dtx && self.fec == fec {
            return Ok(());
        }
        let muted = self.publication.is_muted();
        let sid = self.publication.sid();
        let _ = self.room.local_participant().unpublish_track(&sid).await;
        let track = LocalAudioTrack::create_audio_track("microphone", self.audio.rtc_source());
        let publication = self
            .room
            .local_participant()
            .publish_track(
                LocalTrack::Audio(track),
                publish_options(bitrate_bps, dtx, fec),
            )
            .await
            .map_err(|err| format!("update microphone bitrate failed: {err}"))?;
        if muted {
            publication.mute();
        }
        self.publication = publication;
        self.bitrate_bps = bitrate_bps;
        self.dtx = dtx;
        self.fec = fec;
        Ok(())
    }

    pub async fn close(self) {
        self.events.abort();
        let _ = self.audio.stop_recording();
        let _ = self.room.close().await;
    }
}

fn publish_options(bitrate_bps: u32, dtx: bool, fec: bool) -> TrackPublishOptions {
    TrackPublishOptions {
        source: TrackSource::Microphone,
        audio_encoding: Some(AudioEncoding {
            max_bitrate: u64::from(bitrate_bps.max(16_000)),
        }),
        dtx,
        red: fec,
        simulcast: false,
        ..Default::default()
    }
}

fn select_devices(
    audio: &PlatformAudio,
    input: Option<&str>,
    output: Option<&str>,
) -> Result<(), String> {
    if let Some(id) = match_recording(audio, input) {
        audio
            .switch_recording_device(&id)
            .or_else(|_| audio.set_recording_device(&id))
            .map_err(|err| err.to_string())?;
    }
    if let Some(id) = match_playout(audio, output) {
        audio
            .switch_playout_device(&id)
            .or_else(|_| audio.set_playout_device(&id))
            .map_err(|err| err.to_string())?;
    }
    Ok(())
}

fn match_recording(audio: &PlatformAudio, id: Option<&str>) -> Option<RecordingDeviceId> {
    let (name, index) = parse_device_id(id?, "in")?;
    let mut seen = 0u32;
    for device in audio.recording_devices() {
        if device.id.as_str() == name || device.name == name {
            seen += 1;
            if seen == index {
                return Some(device.id);
            }
        }
    }
    None
}

fn match_playout(audio: &PlatformAudio, id: Option<&str>) -> Option<PlayoutDeviceId> {
    let (name, index) = parse_device_id(id?, "out")?;
    let mut seen = 0u32;
    for device in audio.playout_devices() {
        if device.id.as_str() == name || device.name == name {
            seen += 1;
            if seen == index {
                return Some(device.id);
            }
        }
    }
    None
}

fn set_remote_audio_enabled(room: &Room, enabled: bool) {
    for participant in room.remote_participants().values() {
        for publication in participant.track_publications().values() {
            if publication.kind() == TrackKind::Audio {
                publication.set_enabled(enabled);
            }
        }
    }
}

fn emit_event(name: &str, mut payload: serde_json::Value) {
    payload["event"] = json!(name);
    let _ = writeln!(io::stdout(), "{payload}");
    let _ = io::stdout().flush();
}

fn spawn_events(
    room: Arc<Room>,
    deaf: Arc<AtomicBool>,
    mut events: tokio::sync::mpsc::UnboundedReceiver<RoomEvent>,
) -> JoinHandle<()> {
    tokio::spawn(async move {
        while let Some(event) = events.recv().await {
            match event {
                RoomEvent::TrackSubscribed { publication, .. }
                    if publication.kind() == TrackKind::Audio
                        && deaf.load(Ordering::Relaxed) =>
                {
                    publication.set_enabled(false);
                }
                RoomEvent::ActiveSpeakersChanged { speakers } => {
                    let ids: Vec<String> = speakers
                        .iter()
                        .map(|speaker| speaker.identity().to_string())
                        .collect();
                    emit_event("speaking", json!({ "ids": ids }));
                }
                RoomEvent::Disconnected { reason } => {
                    emit_event(
                        "fault",
                        json!({ "error": format!("LiveKit disconnected: {reason:?}") }),
                    );
                }
                _ => {}
            }
            let _ = &room;
        }
    })
}


