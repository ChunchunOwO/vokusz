mod rtc;

use chat_media_worker::devices;
use chat_media_worker::engine;

use serde_json::{Value, json};
use std::io::{self, BufRead, Write};
use tokio::sync::mpsc;

#[tokio::main]
async fn main() {
    let _ = env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("warn"))
        .target(env_logger::Target::Stderr)
        .try_init();
    let (tx, mut rx) = mpsc::unbounded_channel::<String>();
    std::thread::spawn(move || {
        let stdin = io::stdin();
        for line in stdin.lock().lines() {
            let Ok(line) = line else { break };
            if line.trim().is_empty() {
                continue;
            }
            if tx.send(line).is_err() {
                break;
            }
        }
    });
    let mut prefs = Prefs::default();
    let mut loopback: Option<engine::Loopback> = None;
    let mut session: Option<rtc::Session> = None;
    while let Some(line) = rx.recv().await {
        let request: Value = serde_json::from_str(&line).unwrap_or(Value::Null);
        let id = request.get("id").cloned().unwrap_or(Value::from(0));
        let op = request
            .get("op")
            .and_then(Value::as_str)
            .unwrap_or_default();
        let reply = match op {
            "join" => {
                loopback = None;
                if let Some(current) = session.take() {
                    current.close().await;
                }
                match prefs.apply(&request) {
                    Ok(()) => {
                        let url = request
                            .get("url")
                            .and_then(Value::as_str)
                            .unwrap_or_default()
                            .to_string();
                        let token = request
                            .get("token")
                            .and_then(Value::as_str)
                            .unwrap_or_default()
                            .to_string();
                        match rtc::Session::connect(rtc::JoinConfig {
                            url,
                            token,
                            input_device: prefs.input_device.clone(),
                            output_device: prefs.output_device.clone(),
                            muted: prefs.muted,
                            deafened: prefs.deafened,
                            bitrate_bps: prefs.bitrate_bps,
                            dtx: prefs.dtx,
                            fec: prefs.fec,
                        })
                        .await
                        {
                            Ok(connected) => {
                                session = Some(connected);
                                json!({
                                    "id": id,
                                    "ok": true,
                                    "frame_ms": engine::FRAME_MS,
                                    "jitter_frames": engine::JITTER_FRAMES
                                })
                            }
                            Err(error) => json!({ "id": id, "ok": false, "error": error }),
                        }
                    }
                    Err(error) => json!({ "id": id, "ok": false, "error": error }),
                }
            }
            "devices" => match devices::list() {
                Ok(list) => json!({
                    "id": id,
                    "ok": true,
                    "inputs": list["inputs"],
                    "outputs": list["outputs"]
                }),
                Err(error) => json!({ "id": id, "ok": false, "error": error }),
            },
            "device" => match prefs.apply(&request) {
                Ok(()) => {
                    let rtc_result = if let Some(current) = session.as_ref() {
                        current.set_devices(prefs.input_device.as_deref(), prefs.output_device.as_deref())
                    } else {
                        Ok(())
                    };
                    match rtc_result.and_then(|()| prefs.restart_loopback(&mut loopback)) {
                        Ok(()) => json!({
                            "id": id,
                            "ok": true,
                            "input_device": prefs.input_device,
                            "output_device": prefs.output_device
                        }),
                        Err(error) => json!({ "id": id, "ok": false, "error": error }),
                    }
                }
                Err(error) => json!({ "id": id, "ok": false, "error": error }),
            },
            "mute" => {
                prefs.muted = request
                    .get("muted")
                    .and_then(Value::as_bool)
                    .unwrap_or(prefs.muted);
                if let Some(engine) = &loopback {
                    engine.set_mute(prefs.muted);
                }
                if let Some(current) = session.as_ref() {
                    current.set_mute(prefs.muted);
                }
                json!({"id": id, "ok": true})
            }
            "deafen" => {
                prefs.deafened = request
                    .get("deafened")
                    .and_then(Value::as_bool)
                    .unwrap_or(prefs.deafened);
                if let Some(engine) = &loopback {
                    engine.set_deaf(prefs.deafened);
                }
                if let Some(current) = session.as_ref() {
                    current.set_deaf(prefs.deafened);
                }
                json!({"id": id, "ok": true})
            }
            "quality" => match prefs.apply(&request) {
                Ok(()) => {
                    let rtc_result = if let Some(current) = session.as_mut() {
                        current
                            .set_quality(prefs.bitrate_bps, prefs.dtx, prefs.fec)
                            .await
                    } else {
                        Ok(())
                    };
                    match rtc_result.and_then(|()| prefs.restart_loopback(&mut loopback)) {
                        Ok(()) => json!({
                            "id": id,
                            "ok": true,
                            "jitter_frames": engine::JITTER_FRAMES,
                            "frame_ms": engine::FRAME_MS
                        }),
                        Err(error) => json!({ "id": id, "ok": false, "error": error }),
                    }
                }
                Err(error) => json!({ "id": id, "ok": false, "error": error }),
            },
            "loopback" => {
                if let Some(current) = session.take() {
                    current.close().await;
                }
                loopback = None;
                match prefs.apply(&request) {
                    Ok(()) => match engine::start(
                        prefs.input_device.as_deref(),
                        prefs.output_device.as_deref(),
                        prefs.channels,
                        prefs.muted,
                        prefs.deafened,
                    ) {
                        Ok(engine) => {
                            loopback = Some(engine);
                            json!({
                                "id": id,
                                "ok": true,
                                "frame_ms": engine::FRAME_MS,
                                "jitter_frames": engine::JITTER_FRAMES
                            })
                        }
                        Err(error) => json!({ "id": id, "ok": false, "error": error }),
                    },
                    Err(error) => json!({ "id": id, "ok": false, "error": error }),
                }
            }
            "loopback_stop" | "leave" => {
                loopback = None;
                if let Some(current) = session.take() {
                    current.close().await;
                }
                devices::invalidate();
                json!({"id": id, "ok": true})
            }
            "shutdown" => {
                drop(loopback);
                if let Some(current) = session.take() {
                    current.close().await;
                }
                let _ = writeln!(io::stdout(), "{}", json!({"id": id, "ok": true}));
                return;
            }
            _ => json!({"id": id, "ok": false, "error": "unknown op"}),
        };
        if writeln!(io::stdout(), "{reply}").is_err() {
            break;
        }
        let _ = io::stdout().flush();
    }
}

struct Prefs {
    input_device: Option<String>,
    output_device: Option<String>,
    muted: bool,
    deafened: bool,
    channels: u16,
    bitrate_bps: u32,
    dtx: bool,
    fec: bool,
}

impl Default for Prefs {
    fn default() -> Self {
        Self {
            input_device: None,
            output_device: None,
            muted: false,
            deafened: false,
            channels: 2,
            bitrate_bps: 510_000,
            dtx: false,
            fec: true,
        }
    }
}

impl Prefs {
    fn apply(&mut self, request: &Value) -> Result<(), String> {
        if let Some(value) = request.get("muted").and_then(Value::as_bool) {
            self.muted = value;
        }
        if let Some(value) = request.get("deafened").and_then(Value::as_bool) {
            self.deafened = value;
        }
        if let Some(value) = request.get("channels").and_then(Value::as_u64) {
            self.channels = value.clamp(1, 2) as u16;
        }
        if let Some(value) = request.get("bitrate_bps").and_then(Value::as_u64) {
            self.bitrate_bps = value.clamp(16_000, 510_000) as u32;
        }
        if let Some(value) = request.get("dtx").and_then(Value::as_bool) {
            self.dtx = value;
        }
        if let Some(value) = request.get("fec").and_then(Value::as_bool) {
            self.fec = value;
        }
        let input = request.get("input_device").and_then(Value::as_str);
        let output = request.get("output_device").and_then(Value::as_str);
        devices::validate("in", input)?;
        devices::validate("out", output)?;
        if request.get("input_device").is_some() {
            self.input_device = input
                .map(str::trim)
                .filter(|value| !value.is_empty())
                .map(str::to_string);
        }
        if request.get("output_device").is_some() {
            self.output_device = output
                .map(str::trim)
                .filter(|value| !value.is_empty())
                .map(str::to_string);
        }
        Ok(())
    }

    fn restart_loopback(&self, loopback: &mut Option<engine::Loopback>) -> Result<(), String> {
        if loopback.is_none() {
            return Ok(());
        }
        *loopback = None;
        *loopback = Some(engine::start(
            self.input_device.as_deref(),
            self.output_device.as_deref(),
            self.channels,
            self.muted,
            self.deafened,
        )?);
        Ok(())
    }
}
