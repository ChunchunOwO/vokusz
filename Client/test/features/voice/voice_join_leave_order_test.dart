import 'dart:async';
import 'dart:convert';

import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/authentication/models/accord_auth_state.dart';
import 'package:bonfire/features/authentication/repositories/accord_auth.dart';
import 'package:bonfire/features/notifications/services/sound.dart';
import 'package:bonfire/features/server/controllers/connections.dart';
import 'package:bonfire/features/settings/controllers/settings.dart';
import 'package:bonfire/features/settings/models/accord_settings.dart';
import 'package:bonfire/features/voice/controllers/voice.dart';
import 'package:bonfire/features/voice/services/voice_session.dart';
import 'package:bonfire/features/voice/views/voice_bar.dart';
import 'package:bonfire/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:livekit_client/livekit_client.dart';

/// Stand-in session. [connect] reports connected the way the real session does
/// after the socket is up. [disconnect] waits so the test can see the bar
/// clear first.
class _OrderSession extends VoiceSession {
  final disconnects = <Completer<void>>[];

  @override
  Future<LocalAudioTrack?> captureMic(String? deviceId) async => null;

  @override
  Future<void> releaseMic(LocalAudioTrack? track) async {}

  @override
  Future<void> connect(
    String url,
    String token, {
    bool selfMute = false,
    bool selfDeaf = false,
    String? audioInputDeviceId,
    String? audioOutputDeviceId,
    int outputVolume = 100,
    int inputVolume = 100,
    bool relayOnly = false,
    LocalAudioTrack? preparedMic,
  }) async {
    onStateChanged?.call(VoiceSessionState.connected);
  }

  @override
  Future<void> disconnect() {
    final gate = Completer<void>();
    disconnects.add(gate);
    return gate.future;
  }

  @override
  Future<void> dispose() async {}
}

class _FakeAccordAuth extends AccordAuth {
  _FakeAccordAuth(this._client);
  final AccordClient _client;

  @override
  AccordAuthState build() => const AccordAuthLoggedOut();

  @override
  AccordClient? clientForKey(String key) =>
      key == 'server-key' ? _client : null;
}

class _ActiveConnections extends ConnectionsController {
  @override
  ConnectionsState build() => const ConnectionsState(activeKey: 'server-key');
}

class _FixedSettingsController extends SettingsController {
  @override
  AccordSettings build() => const AccordSettings();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => soundManager.setVoiceSessionActive(false));

  testWidgets('join shows connecting before the request, leave clears first', (
    tester,
  ) async {
    final joins = <Completer<void>>[];
    final leaves = <Completer<void>>[];
    final responder = MockClient((request) async {
      final path = request.url.path;
      if (request.method == 'POST' && path.endsWith('/voice/join')) {
        final gate = Completer<void>();
        joins.add(gate);
        await gate.future;
        return http.Response(
          jsonEncode({
            'backend': 'livekit',
            'livekit_url': 'wss://livekit.example',
            'token': 'lk-token',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'DELETE' && path.endsWith('/voice/leave')) {
        final gate = Completer<void>();
        leaves.add(gate);
        await gate.future;
        return http.Response(
          '{"ok":true}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        '[]',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final client = AccordClient(
      token: 'test-token',
      tokenType: 'Bearer',
      baseUrl: 'https://accord.example',
      gatewayUrl: 'wss://accord.example/ws',
      httpClient: responder,
    );
    addTearDown(client.dispose);
    final session = _OrderSession();
    final container = ProviderContainer(
      overrides: [
        accordAuthProvider.overrideWith(() => _FakeAccordAuth(client)),
        connectionsControllerProvider.overrideWith(_ActiveConnections.new),
        settingsControllerProvider.overrideWith(_FixedSettingsController.new),
      ],
    );
    addTearDown(container.dispose);
    container.read(voiceControllerProvider.notifier).debugSession = session;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(AppThemePreset.dark),
          home: const Scaffold(body: VoiceBar()),
        ),
      ),
    );

    final notifier = container.read(voiceControllerProvider.notifier);
    VoiceConnection read() => container.read(voiceControllerProvider);

    expect(read().isConnected, isFalse);
    expect(find.text('Connecting…'), findsNothing);

    for (var cycle = 0; cycle < 2; cycle++) {
      final joinFuture = notifier.join('c1', null);
      await tester.pump();
      await tester.pump();

      expect(joins, hasLength(cycle + 1));
      expect(joins[cycle].isCompleted, isFalse);
      expect(read().sessionState, VoiceSessionState.connecting);
      expect(read().channelId, 'c1');
      expect(find.text('Connecting…'), findsOneWidget);

      joins[cycle].complete();
      await joinFuture;
      await tester.pump();

      expect(read().sessionState, VoiceSessionState.connected);
      expect(read().isConnected, isTrue);
      expect(find.text('Connecting…'), findsNothing);
      expect(find.text('Voice connected'), findsOneWidget);

      final leaveFuture = notifier.leave();
      await tester.pump();
      await tester.pump();

      expect(read().isConnected, isFalse);
      expect(read().channelId, isNull);
      expect(read().sessionState, VoiceSessionState.disconnected);
      expect(session.disconnects, hasLength(cycle + 1));
      expect(session.disconnects[cycle].isCompleted, isFalse);
      expect(leaves, hasLength(cycle + 1));
      expect(leaves[cycle].isCompleted, isFalse);
      expect(find.text('Voice connected'), findsNothing);
      expect(find.text('Connecting…'), findsNothing);

      session.disconnects[cycle].complete();
      leaves[cycle].complete();
      await leaveFuture;
      await tester.pump();

      expect(read().isConnected, isFalse);
      expect(read().sessionState, isNot(VoiceSessionState.connecting));
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('switching channels keeps the new room when leave of the old one is late', (
    tester,
  ) async {
    final leaves = <Completer<void>>[];
    final joins = <Completer<void>>[];
    final responder = MockClient((request) async {
      final path = request.url.path;
      if (request.method == 'POST' && path.endsWith('/voice/join')) {
        final gate = Completer<void>();
        joins.add(gate);
        await gate.future;
        final channel = path.contains('/c2/') ? 'c2' : 'c1';
        return http.Response(
          jsonEncode({
            'channel_id': channel,
            'backend': 'livekit',
            'livekit_url': 'wss://livekit.example',
            'token': 'lk-$channel',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'DELETE' && path.endsWith('/voice/leave')) {
        final gate = Completer<void>();
        leaves.add(gate);
        await gate.future;
        return http.Response(
          '{"ok":true}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        '[]',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final client = AccordClient(
      token: 'test-token',
      tokenType: 'Bearer',
      baseUrl: 'https://accord.example',
      gatewayUrl: 'wss://accord.example/ws',
      httpClient: responder,
    );
    addTearDown(client.dispose);
    final session = _SwitchSession();
    final container = ProviderContainer(
      overrides: [
        accordAuthProvider.overrideWith(() => _FakeAccordAuth(client)),
        connectionsControllerProvider.overrideWith(_ActiveConnections.new),
        settingsControllerProvider.overrideWith(_FixedSettingsController.new),
      ],
    );
    addTearDown(container.dispose);
    container.read(voiceControllerProvider.notifier).debugSession = session;
    final notifier = container.read(voiceControllerProvider.notifier);
    VoiceConnection read() => container.read(voiceControllerProvider);

    final joinA = notifier.join('c1', 's1');
    await tester.pump();
    joins.single.complete();
    await joinA;

    final joinB = notifier.join('c2', 's1');
    await tester.pump();
    await tester.pump();

    expect(leaves, hasLength(1));
    expect(leaves.single.isCompleted, isFalse);
    expect(joins, hasLength(2));
    expect(joins.last.isCompleted, isFalse);
    expect(read().channelId, 'c2');
    expect(read().sessionState, VoiceSessionState.connecting);

    joins.last.complete();
    await joinB;

    expect(read().channelId, 'c2');
    expect(read().sessionState, VoiceSessionState.connected);
    expect(leaves.single.isCompleted, isFalse);

    leaves.single.complete();
    await tester.pump();

    expect(read().channelId, 'c2');
    expect(read().isConnected, isTrue);
    expect(read().sessionState, VoiceSessionState.connected);

    final done = notifier.leave();
    await tester.pump();
    await tester.pump();
    expect(read().isConnected, isFalse);
    leaves.last.complete();
    await done;
  });
}

class _SwitchSession extends VoiceSession {
  @override
  Future<LocalAudioTrack?> captureMic(String? deviceId) async => null;

  @override
  Future<void> releaseMic(LocalAudioTrack? track) async {}

  @override
  Future<void> connect(
    String url,
    String token, {
    bool selfMute = false,
    bool selfDeaf = false,
    String? audioInputDeviceId,
    String? audioOutputDeviceId,
    int outputVolume = 100,
    int inputVolume = 100,
    bool relayOnly = false,
    LocalAudioTrack? preparedMic,
  }) async {
    onStateChanged?.call(VoiceSessionState.connected);
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() async {}
}
