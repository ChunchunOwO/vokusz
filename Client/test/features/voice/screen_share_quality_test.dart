import 'package:bonfire/features/settings/controllers/settings.dart';
import 'package:bonfire/features/settings/models/accord_settings.dart';
import 'package:bonfire/features/voice/controllers/voice.dart';
import 'package:bonfire/features/voice/services/voice_session.dart';
import 'package:bonfire/features/voice/utils/voice_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter/material.dart';
import 'package:bonfire/features/voice/views/screen_share_picker.dart';
import 'package:bonfire/theme/app_theme.dart';

/// Captures the arguments the controller hands the LiveKit session, so the
/// screen-share quality path can be asserted without a native room.
class _RecordingSession extends VoiceSession {
  bool? enabled;
  int? width;
  int? height;
  int? fps;
  int? bitrate;
  bool? motionPriority;
  int calls = 0;
  bool failCapture = false;

  // Camera capture, recorded separately so a test can prove the two toggles
  // read different settings.
  int? cameraWidth;
  int? cameraHeight;
  int? cameraFps;
  int? cameraBitrate;

  @override
  Future<void> setScreenShareEnabled(
    bool enabled, {
    String? sourceId,
    int? width,
    int? height,
    int? fps,
    int? bitrate,
    bool motionPriority = true,
    bool shareSystemAudio = false,
  }) async {
    if (failCapture) throw StateError('OBS capture failed');
    calls++;
    this.enabled = enabled;
    this.width = width;
    this.height = height;
    this.fps = fps;
    this.bitrate = bitrate;
    this.motionPriority = motionPriority;
  }

  @override
  Future<bool> setCameraEnabled(
    bool enabled, {
    int? width,
    int? height,
    int? fps,
    int? bitrate,
    String? deviceId,
  }) async {
    cameraWidth = width;
    cameraHeight = height;
    cameraFps = fps;
    cameraBitrate = bitrate;
    return true;
  }
}

/// A [VoiceController] that starts out "connected" (so the media toggles run)
/// without ever touching LiveKit or the gateway.
class _ConnectedVoiceController extends VoiceController {
  @override
  VoiceConnection build() => const VoiceConnection(channelId: 'c1');
}

class _FixedSettingsController extends SettingsController {
  _FixedSettingsController(this._settings);
  final AccordSettings _settings;
  @override
  AccordSettings build() => _settings;

  @override
  void setScreenShareResolution(int index) {
    state = state.copyWith(screenShareResolution: index);
  }

  @override
  void setScreenShareFps(int fps) {
    state = state.copyWith(screenShareFps: fps);
  }
}

({ProviderContainer container, _RecordingSession session}) _harness(
  AccordSettings settings,
) {
  final container = ProviderContainer(
    overrides: [
      settingsControllerProvider.overrideWith(
        () => _FixedSettingsController(settings),
      ),
      voiceControllerProvider.overrideWith(_ConnectedVoiceController.new),
    ],
  );
  addTearDown(container.dispose);
  final session = _RecordingSession();
  container.read(voiceControllerProvider.notifier).debugSession = session;
  return (container: container, session: session);
}

void main() {
  testWidgets('share dialog lets users select low-resource quality', (
    tester,
  ) async {
    final h = _harness(const AccordSettings());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp(
          theme: buildAppTheme(AppThemePreset.dark),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showScreenShareSourcePicker(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('480p').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('10 fps').last);
    await tester.pumpAndSettle();
    final settings = h.container.read(settingsControllerProvider);
    expect(settings.screenShareResolution, 3);
    expect(settings.screenShareFps, 10);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  group('toggleScreenShare quality', () {
    test('a failed capture does not advertise a running share', () async {
      final h = _harness(const AccordSettings());
      h.session.failCapture = true;
      await expectLater(
        h.container.read(voiceControllerProvider.notifier).toggleScreenShare(),
        throwsStateError,
      );
      expect(h.container.read(voiceControllerProvider).selfStream, isFalse);
    });

    test('passes the screen-share settings, not the camera ones', () async {
      // Camera deliberately set to something different from screen share, so a
      // regression that reads `videoDimensions`/`videoFps`/`videoBitrate`
      // again fails here.
      const settings = AccordSettings(
        videoResolution: 0, // 854x480 camera
        videoFps: 15,
        screenShareResolution: 1, // 1920x1080 share
        screenShareFps: 60,
      );
      final h = _harness(settings);

      await h.container
          .read(voiceControllerProvider.notifier)
          .toggleScreenShare();

      expect(h.session.enabled, isTrue);
      expect(h.session.width, 1920);
      expect(h.session.height, 1080);
      expect(h.session.fps, 60);
      expect(h.session.bitrate, settings.screenShareBitrate);
      expect(h.session.motionPriority, isTrue);

      // The camera values it used to send.
      expect(h.session.width, isNot(854));
      expect(h.session.fps, isNot(settings.videoFps));
      expect(h.session.bitrate, isNot(settings.videoBitrate));
    });

    test('the default install shares at resource-friendly 720p30', () async {
      final h = _harness(const AccordSettings());

      await h.container
          .read(voiceControllerProvider.notifier)
          .toggleScreenShare();

      expect(h.session.width, 1280);
      expect(h.session.height, 720);
      expect(h.session.fps, 30);
      expect(h.session.bitrate, 2100000);
    });

    test('the motion-priority preference is forwarded', () async {
      final h = _harness(
        const AccordSettings(screenShareMotionPriority: false),
      );

      await h.container
          .read(voiceControllerProvider.notifier)
          .toggleScreenShare();

      expect(h.session.motionPriority, isFalse);
    });

    test('toggling again stops the share', () async {
      final h = _harness(const AccordSettings());
      final notifier = h.container.read(voiceControllerProvider.notifier);

      await notifier.toggleScreenShare();
      expect(h.container.read(voiceControllerProvider).selfStream, isTrue);

      await notifier.toggleScreenShare();
      expect(h.session.enabled, isFalse);
      expect(h.session.calls, 2);
      expect(h.container.read(voiceControllerProvider).selfStream, isFalse);
    });

    test('the camera toggle still uses the camera settings', () async {
      const settings = AccordSettings(
        videoResolution: 2, // 1920x1080 camera
        videoFps: 30,
        screenShareResolution: 0,
        screenShareFps: 60,
      );
      final h = _harness(settings);

      await h.container.read(voiceControllerProvider.notifier).toggleVideo();

      expect(h.session.cameraWidth, 1920);
      expect(h.session.cameraHeight, 1080);
      expect(h.session.cameraFps, 30);
      expect(h.session.cameraBitrate, settings.videoBitrate);
    });
  });

  test('desktop capture forwards size and fps to native constraints', () {
    const options = ScreenShareCaptureOptions(
      sourceId: 'screen:1',
      maxFrameRate: 10,
      params: VideoParameters(dimensions: VideoDimensions(854, 480)),
    );
    final constraints = options.toMediaConstraintsMap();
    expect(constraints['mandatory'], {
      'maxWidth': 854,
      'maxHeight': 480,
      'frameRate': 10.0,
    });
    expect(constraints['deviceId'], {'exact': 'screen:1'});
  });

  test('low-resource choices persist and reach the session', () async {
    for (final fps in AccordSettings.screenShareFpsOptions) {
      final settings = AccordSettings.fromJson(
        AccordSettings(screenShareResolution: 3, screenShareFps: fps).toJson(),
      );
      final h = _harness(settings);
      await h.container
          .read(voiceControllerProvider.notifier)
          .toggleScreenShare();
      expect(h.session.width, 854);
      expect(h.session.height, 480);
      expect(h.session.fps, fps);
      expect(h.session.bitrate, lessThanOrEqualTo(1500000));
    }
  });

  group('screen-share fallbacks', () {
    test('an unspecified frame rate uses the balanced default', () {
      expect(defaultScreenShareFps, 30);
      expect(defaultScreenShareFps, AccordSettings.defaultScreenShareFps);
    });

    test('the fallback bitrate matches the 720p30 setting', () {
      expect(
        defaultScreenShareBitrate,
        const AccordSettings().screenShareBitrate,
      );
    });
  });
}
