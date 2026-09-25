---
title: Voice and Video
description: Join voice channels for real-time audio and video conversations.
order: 1
section: voice-and-video
---

# Voice and Video

Voice channels let you talk to other people in real time using your microphone, camera, or screen share. Screen sharing is included for everyone — it is not a paid upgrade. Vokusz is built so that voice stays smooth and stable in everyday use.

## Joining a Voice Channel

1. In the channel list, click a **voice channel** (marked with a speaker icon).
2. vokusz connects you to the voice room.
3. A **voice bar** appears at the bottom of the channel panel showing the channel name, a green status dot, and control buttons.

Other participants in the channel are shown with their avatar, display name, and status indicators (muted, deafened, camera on, sharing screen).

## Voice Controls

The voice bar provides these controls:

- **Mute** -- Toggle your microphone on/off
- **Deafen** -- Mute all incoming audio (also mutes your mic)
- **Camera** -- Toggle your camera on/off
- **Screen Share** -- Share your screen or a specific window
- **Soundboard** -- Play audio clips into the channel
- **Settings** -- Open voice settings
- **Disconnect** -- Leave the voice channel

## Speaking Indicator

When someone is speaking, a green ring appears around their avatar in the participant list.

## Screen Sharing

1. Click the **Screen Share** button in the voice bar.
2. Choose which screen or window to share from the picker.
3. Your screen share appears as a video tile for other participants.
4. Click the button again to stop sharing.

## Video

Click the **Camera** button to share your camera feed. Other participants see your video as a tile in the voice channel view.

## Voice Settings

Access voice and video settings from the voice bar settings button or from **App Settings > Voice & Video**. Here you can configure your input/output devices and other audio preferences.

The **Output device** picker is shown on desktop and Android, where the platform can honour an explicit choice. iOS routes call audio itself — use Control Centre, the AirPlay picker, or plug in a headset — so the app does not offer a picker that iOS would ignore.

### Relay-only connections

Enable **Relay-only voice** in **Voice & Video** settings to require a TURN relay
for voice, video and screen sharing. Leave and rejoin to apply it to a current
call. The option is off by default, can add latency, and requires the server's
LiveKit deployment to provide reachable TURN. Failed relay connections report an
error and do not fall back to direct media. See [network privacy](../privacy-network.md).

Screen sharing: choose resolution (480p–1440p) and frame rate (5–60 FPS) in the desktop source picker or Voice & Video settings. New profiles default to 720p/30 FPS; existing saved choices are retained. Changes apply to the next share. Use 480p/10–15 FPS for lower resource usage, or 60 FPS for motion. Windows x64 uses bundled OBS core with Windows Graphics Capture for GPU scaling and color conversion before WebRTC encoding. No separate OBS installation is required. Web and other platforms retain their existing backends.

OBS capture build, lifecycle and native verification: [obs-capture.md](obs-capture.md).
