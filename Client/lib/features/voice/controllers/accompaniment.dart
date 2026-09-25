import 'dart:async';

import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/features/settings/controllers/settings.dart';
import 'package:bonfire/features/voice/controllers/voice.dart';
import 'package:bonfire/features/voice/services/voice_session.dart';
import 'package:bonfire/features/voice/utils/voice_logic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

class AccompanimentState {
  const AccompanimentState({
    this.sourceId = '',
    this.sourceName = '',
    this.active = false,
    this.busy = false,
    this.error,
  });

  final String sourceId;
  final String sourceName;
  final bool active;
  final bool busy;
  final String? error;

  AccompanimentState copyWith({
    String? sourceId,
    String? sourceName,
    bool? active,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return AccompanimentState(
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      active: active ?? this.active,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Plays one application's audio into the current voice channel.
final accompanimentControllerProvider =
    NotifierProvider<AccompanimentController, AccompanimentState>(
      AccompanimentController.new,
    );

class AccompanimentController extends Notifier<AccompanimentState> {
  @override
  AccompanimentState build() {
    ref.keepAlive();
    ref.listen(voiceControllerProvider.select((voice) => voice.isConnected), (
      previous,
      next,
    ) {
      if (previous == true && next == false && state.active) {
        state = state.copyWith(active: false, busy: false);
      }
    });
    ref.listen(voiceControllerProvider.select((voice) => voice.sessionState), (
      previous,
      next,
    ) {
      if (previous == VoiceSessionState.connected &&
          next == VoiceSessionState.reconnecting &&
          state.active) {
        state = state.copyWith(active: false, busy: false);
      }
    });
    ref.listen(
      settingsControllerProvider.select((settings) => settings.accompanimentVolume),
      (previous, next) {
        if (!state.active || previous == next) return;
        final session = ref.read(voiceControllerProvider.notifier).session;
        unawaited(session?.setAccompanimentVolume(voiceGain(next)));
      },
    );
    return const AccompanimentState();
  }

  void remember(String sourceId, String sourceName) {
    state = state.copyWith(
      sourceId: sourceId,
      sourceName: sourceName,
      clearError: true,
    );
  }

  Future<void> start() async {
    final sourceId = state.sourceId;
    if (sourceId.isEmpty) {
      state = state.copyWith(
        error: AppStrings.choose('Choose an application first', '请先选择一个应用'),
      );
      return;
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) {
      state = state.copyWith(
        error: AppStrings.choose(
          'Application audio is available on Windows',
          '应用伴奏目前只在 Windows 上可用',
        ),
      );
      return;
    }
    final voice = ref.read(voiceControllerProvider);
    final session = ref.read(voiceControllerProvider.notifier).session;
    if (!voice.isConnected || session == null) {
      state = state.copyWith(
        error: AppStrings.choose('Join a voice channel first', '请先加入语音频道'),
      );
      return;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      final stream = await rtc.navigator.mediaDevices.getDisplayMedia(<String, dynamic>{
        'video': false,
        'audio': <String, dynamic>{
          'deviceId': <String, dynamic>{'exact': sourceId},
        },
      });
      if (stream.getAudioTracks().isEmpty) {
        await _stopCapture();
        state = state.copyWith(
          busy: false,
          active: false,
          error: AppStrings.choose(
            'Could not capture audio from that application',
            '无法捕获这个应用的声音',
          ),
        );
        return;
      }
      final volume = ref.read(settingsControllerProvider).accompanimentVolume;
      final error = await session.publishAccompaniment(
        stream,
        volume: voiceGain(volume),
      );
      final message = error == null ? null : _startError(error);
      if (message != null) await _stopCapture();
      state = state.copyWith(
        busy: false,
        active: message == null,
        error: message,
        clearError: message == null,
      );
    } catch (error) {
      await _stopCapture();
      state = state.copyWith(
        busy: false,
        active: false,
        error: _startError(error),
      );
    }
  }

  Future<void> stop() async {
    state = state.copyWith(busy: true);
    final session = ref.read(voiceControllerProvider.notifier).session;
    await session?.stopAccompaniment();
    await _stopCapture();
    state = state.copyWith(active: false, busy: false);
  }

  String _startError(Object error) {
    final text = '$error'.toLowerCase();
    if (text.contains('trackpublishexception') ||
        text.contains('failed to publish')) {
      return AppStrings.choose(
        'Could not send the accompaniment into the voice channel',
        '伴奏没能送进语音频道',
      );
    }
    return '$error';
  }

  Future<void> _stopCapture() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;
    try {
      await rtc.navigator.mediaDevices.getDisplayMedia(<String, dynamic>{
        'video': false,
        'audio': false,
      });
    } catch (_) {}
  }
}
