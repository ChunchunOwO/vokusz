/// Pure decision logic for the voice stack, extracted so it can be unit-tested
/// without a native LiveKit `Room`. `VoiceSession`/`VoiceController` call these
/// directly, and the tests in `test/features/voice/voice_logic_test.dart` lock
/// the behaviour in so a future change to the voice layer fails loudly rather
/// than in a live call.
library;

import 'dart:math' as math;

import 'package:bonfire/l10n/ui_copy.dart';
import 'package:bonfire/features/voice/services/voice_session.dart'
    show VoiceSessionState;

/// Converts a 0–200% volume preference into a WebRTC gain multiplier (0.0–2.0),
/// clamping out-of-range input. LiveKit has no per-track volume, so gain is
/// applied via `Helper.setVolume`; 100% is unity.
double voiceGain(num volumePercent) =>
    (volumePercent / 100).clamp(0.0, 2.0).toDouble();

/// Whether the local microphone track should be capturing right now.
///
/// Push-to-talk and the mute button are separate. In push-to-talk the key is
/// the only switch, and [selfMute] is ignored until that mode is turned off.
bool microphoneLive({
  required bool selfMute,
  required bool pushToTalk,
  required bool pushToTalkHeld,
}) {
  if (pushToTalk) return pushToTalkHeld;
  return !selfMute;
}

/// Normalises a selected audio/video device id: a null or empty id means
/// "system default" and is represented as null (what the capture options
/// expect).
String? normalizeDeviceId(String? deviceId) =>
    (deviceId == null || deviceId.isEmpty) ? null : deviceId;

/// Frame rate used for a screen share when the caller doesn't pass one (the
/// settings-derived value normally does). Matches
/// `AccordSettings.defaultScreenShareFps`: an unspecified rate means "the
/// resource-friendly default", never LiveKit's 15 fps slideshow preset.
const int defaultScreenShareFps = 30;

/// Send-bitrate ceiling used for a screen share when the caller doesn't pass
/// one. Matches `AccordSettings.screenShareBitrate` at its 720p30 default.
const int defaultScreenShareBitrate = 2100000;

/// Whether a `RoomDisconnected` should be treated as an *unintentional* drop
/// (so the controller proactively reconnects), versus an intentional teardown
/// (leave / channel-swap / dispose) which must NOT auto-reconnect.
///
/// [intentional] is the session's own `_intentionalDisconnect` flag (set around
/// every deliberate teardown); [clientInitiated] is LiveKit's
/// `DisconnectReason.clientInitiated`. A drop is unintentional only when neither
/// holds.
bool isUnintentionalDisconnect({
  required bool intentional,
  required bool clientInitiated,
}) => !intentional && !clientInitiated;

/// Whether the controller should attempt an auto-reconnect after a session
/// disconnect: only for an unintentional drop while we still believe we're
/// connected, and only once per drop (the one-shot guard, re-checked on the
/// serialized queue by `_reconnectLocked`).
bool shouldAutoReconnect({
  required bool intentional,
  required bool stillConnected,
  required bool alreadyAttempted,
}) => !intentional && stillConnected && !alreadyAttempted;

/// Whether a session state transition from [current] to [next] should fire the
/// `onStateChanged` callback — i.e. only on an actual change.
bool shouldEmitStateChange(VoiceSessionState current, VoiceSessionState next) =>
    current != next;

/// Whether a connection state counts as "live" for the purposes of the
/// reconnect/credential-refresh path (a token refresh / SFU move only reconnects
/// when the session has actually dropped).
bool needsReconnect(VoiceSessionState state) =>
    state == VoiceSessionState.disconnected ||
    state == VoiceSessionState.failed ||
    state == VoiceSessionState.reconnecting;

/// A 0–1 level from one WebRTC stats sample.
///
/// [reported] is the `audioLevel` field when the report has one. Otherwise the
/// level is the RMS of the energy added since the previous sample. The first
/// energy sample has nothing to subtract, so it returns null and the caller
/// keeps the previous indicator for that one tick.
double? liveAudioLevel({
  double? reported,
  double? energy,
  double? duration,
  double? previousEnergy,
  double? previousDuration,
}) {
  final rms = _energyRms(
    energy: energy,
    duration: duration,
    previousEnergy: previousEnergy,
    previousDuration: previousDuration,
  );
  if (reported != null && !reported.isNaN && reported > 0) {
    return reported.clamp(0.0, 1.0);
  }
  if (rms != null) return rms;
  if (reported != null) return reported.isNaN ? 0 : reported.clamp(0.0, 1.0);
  return null;
}

double? _energyRms({
  required double? energy,
  required double? duration,
  required double? previousEnergy,
  required double? previousDuration,
}) {
  if (energy == null ||
      duration == null ||
      previousEnergy == null ||
      previousDuration == null) {
    return null;
  }
  final span = duration - previousDuration;
  final added = energy - previousEnergy;
  if (span <= 0.0001 || added <= 0) return 0;
  final rms = math.sqrt(added / span);
  if (rms.isNaN || rms.isInfinite) return 0;
  return rms.clamp(0.0, 1.0);
}

/// Whether [level] counts as talking.
///
/// A measured level wins over [serverSpeaking]. LiveKit's speaking flag trails
/// the audio by a noticeable gap; it is only the fallback before the first
/// local sample arrives.
bool levelSaysSpeaking({
  required double? level,
  required double threshold,
  required bool serverSpeaking,
}) => level == null ? serverSpeaking : level >= threshold;

/// How long after a click on a voice channel row a second click still counts as
/// a double-click (fast path: double-click joins). Deliberately a
/// touch longer than Material's 300ms so the gesture is forgiving — it's the
/// only join affordance that costs no extra pointer travel.
const Duration voiceDoubleTapWindow = Duration(milliseconds: 400);

/// Whether a click at [now] following a previous click at [lastTapAt] on the
/// same row should be treated as the join gesture.
///
/// The channel row detects this itself instead of adding an `onDoubleTap` to its
/// `InkWell`: with a double-tap recognizer in the arena Flutter delays every
/// single tap until the double-tap timer expires, which would make simply
/// *selecting* a channel feel laggy. Selection stays instant; the second click
/// joins.
bool isVoiceDoubleTap(DateTime? lastTapAt, DateTime now) =>
    lastTapAt != null &&
    !now.isBefore(lastTapAt) &&
    now.difference(lastTapAt) <= voiceDoubleTapWindow;

/// The voice-bar message shown when the microphone could not be captured
/// because the OS denied (or has not granted) microphone access.
const String micPermissionDeniedMessage =
    'Microphone access is unavailable — enable it in Settings';

/// Whether a failed microphone capture/publish was a *permission* failure, as
/// opposed to a device/transport problem.
///
/// The error surfaces differently per platform: iOS and web reject
/// `getUserMedia` with a DOMException named `NotAllowedError`
/// (`FlutterRTCMediaStream.m`, "step 10 Permission Failure"), Android's
/// `GetUserMediaImpl` fails with a `PermissionDenied`-style message, and
/// flutter_webrtc's Dart layer wraps both in a plain
/// `'Unable to getUserMedia: …'` string — so this matches on the message text
/// rather than on a type.
bool isMicPermissionError(Object error) {
  final text = '$error'.toLowerCase();
  return text.contains('notallowederror') ||
      text.contains('permissiondenied') ||
      text.contains('permission');
}

/// The user-facing message for a microphone that could not be published at
/// join/unmute time. A permission failure gets the actionable Settings hint;
/// anything else keeps the platform's reason so the voice bar says *why*.
String describeMicFailure(Object error) {
  if (isMicPermissionError(error)) return micPermissionDeniedMessage;
  final reason = '$error'.replaceFirst('Unable to getUserMedia: ', '').trim();
  return reason.isEmpty
      ? UiCopy.microphoneUnavailable()
      : UiCopy.microphoneUnavailable2(arg0: reason);
}

/// Result of publishing the microphone during fast-connect.
///
/// LiveKit publishes that track from the join-response handler, which is not
/// awaited by [Room.connect]. [publishError] is the handler's failure;
/// [published] is whether a microphone publication exists once connect returns.
/// A miss must become a user-visible mute, not a bar that still says the mic
/// is live.
String? fastConnectMicFailure({
  required bool offeredMic,
  required bool published,
  Object? publishError,
}) {
  if (!offeredMic) return null;
  if (publishError != null) return describeMicFailure(publishError);
  if (!published) {
    return describeMicFailure('microphone track was not published');
  }
  return null;
}
