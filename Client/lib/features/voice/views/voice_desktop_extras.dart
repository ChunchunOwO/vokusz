import 'dart:async';

import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/member/controllers/accord_members.dart';
import 'package:bonfire/features/profiles/controllers/profiles_controller.dart';
import 'package:bonfire/features/profiles/views/profile_gate.dart';
import 'package:bonfire/features/settings/controllers/settings.dart';
import 'package:bonfire/features/settings/models/accord_settings.dart';
import 'package:bonfire/features/user/controllers/accord_users.dart';
import 'package:bonfire/features/voice/controllers/accompaniment.dart';
import 'package:bonfire/features/voice/controllers/voice.dart';
import 'package:bonfire/features/voice/controllers/voice_states.dart';
import 'package:bonfire/features/voice/services/speaker_overlay.dart';
import 'package:bonfire/features/voice/services/speaker_overlay_avatars.dart';
import 'package:bonfire/features/voice/utils/desktop_keys.dart';
import 'package:bonfire/features/voice/utils/participant_display.dart';
import 'package:bonfire/features/voice/utils/voice_logic.dart';
import 'package:bonfire/features/voice/views/compact_voice_mode.dart';
import 'package:bonfire/features/voice/views/compact_voice_window.dart';
import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/shared/utils/client_access.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps push-to-talk, the speaker overlay and compact-mode lockout running
/// for the whole session. It takes no space.
class VoiceDesktopExtras extends ConsumerStatefulWidget {
  const VoiceDesktopExtras({super.key});

  @override
  ConsumerState<VoiceDesktopExtras> createState() => _VoiceDesktopExtrasState();
}

class _VoiceDesktopExtrasState extends ConsumerState<VoiceDesktopExtras> {
  Timer? _keys;
  bool _overlayWasDown = false;
  bool _muteWasDown = false;
  String _overlaySignature = '';
  final Map<String, String?> _avatarUrls = {};
  final Map<String, Uint8List?> _avatars = {};
  final Set<String> _avatarLoading = {};
  final Set<String> _avatarsSent = {};

  @override
  void initState() {
    super.initState();
    SpeakerOverlay.onFrame = _saveFrame;
    _keys = Timer.periodic(const Duration(milliseconds: 32), (_) => _tick());
  }

  @override
  void dispose() {
    _keys?.cancel();
    if (SpeakerOverlay.onFrame == _saveFrame) SpeakerOverlay.onFrame = null;
    super.dispose();
  }

  void _saveFrame(Rect frame) {
    final settings = ref.read(settingsControllerProvider);
    final same =
        settings.voiceOverlayPlaced &&
        (settings.voiceOverlayX - frame.left).abs() < 1 &&
        (settings.voiceOverlayY - frame.top).abs() < 1 &&
        (settings.voiceOverlayWidth - frame.width).abs() < 1 &&
        (settings.voiceOverlayHeight - frame.height).abs() < 1;
    if (same) return;
    ref.read(settingsControllerProvider.notifier).setVoiceOverlayFrame(
      x: frame.left,
      y: frame.top,
      width: frame.width,
      height: frame.height,
    );
  }

  void _tick() {
    if (!mounted || DesktopKeys.capturing) return;
    final settings = ref.read(settingsControllerProvider);
    final overlayDown = DesktopKeys.isDown(settings.voiceOverlayHotkey);
    if (overlayDown && !_overlayWasDown) {
      ref
          .read(settingsControllerProvider.notifier)
          .setVoiceOverlayEnabled(!settings.voiceOverlayEnabled);
    }
    _overlayWasDown = overlayDown;
    final muteKey = settings.voiceMuteHotkey;
    final muteIsTalkKey =
        settings.voicePushToTalk && muteKey == settings.voicePushToTalkKey;
    if (!muteIsTalkKey) {
      final muteDown = DesktopKeys.isDown(muteKey);
      if (muteDown && !_muteWasDown) {
        ref.read(voiceControllerProvider.notifier).toggleMute();
      }
      _muteWasDown = muteDown;
    } else {
      _muteWasDown = false;
    }
    final held = DesktopKeys.isDown(settings.voicePushToTalkKey);
    ref.read(voiceControllerProvider.notifier).syncTransmit(
      pushToTalk: settings.voicePushToTalk,
      held: held,
    );
    final voice = ref.read(voiceControllerProvider);
    final live = voice.isConnected &&
        microphoneLive(
          selfMute: voice.selfMute,
          pushToTalk: settings.voicePushToTalk,
          pushToTalkHeld: held,
        );
    if (transmitLive.value != live) transmitLive.value = live;
  }

  bool _locked() {
    ref.watch(profilesControllerProvider);
    final active = ref.read(profilesControllerProvider.notifier).active;
    final unlocked = ref.watch(profileUnlockedProvider);
    return active != null && active.hasPin && !unlocked;
  }

  @override
  Widget build(BuildContext context) {
    final locked = _locked();
    CompactVoiceMode.instance.allowEnter = !locked;
    if (locked && CompactVoiceMode.instance.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (CompactVoiceMode.instance.active) {
          CompactVoiceMode.instance.exit();
        }
      });
    }
    ref.watch(accompanimentControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final voice = ref.watch(voiceControllerProvider);
    final serverKey = voice.serverKey ?? '';
    final channelId = voice.channelId;
    final spaceId = voice.spaceId;
    final List<AccordVoiceState> states;
    final Map<String, AccordMember>? members;
    if (!voice.isConnected || channelId == null) {
      states = const [];
      members = null;
    } else {
      states = ref.watch(
        voiceStatesControllerProvider(serverKey).select(
          (cache) => voiceStatesFor(cache, channelId),
        ),
      );
      members = spaceId == null
          ? null
          : ref.watch(accordMembersControllerProvider(serverKey, spaceId));
    }
    final users = ref.watch(accordUsersControllerProvider(serverKey));
    _pushOverlay(
      settings,
      voice,
      states: states,
      members: members,
      users: users,
      cdnUrl: ref.watchCdnUrl(),
    );
    return const SizedBox.shrink();
  }

  void _ensureAvatar(String id, String? url) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;
    if (_avatarUrls[id] == url &&
        (_avatars.containsKey(id) || _avatarLoading.contains(id))) {
      return;
    }
    _avatarUrls[id] = url;
    _avatars.remove(id);
    _avatarsSent.remove(id);
    if (url == null || url.isEmpty) {
      _avatars[id] = null;
      return;
    }
    _avatarLoading.add(id);
    unawaited(() async {
      final bytes = await loadOverlayAvatar(url);
      if (!mounted) return;
      _avatarLoading.remove(id);
      if (_avatarUrls[id] != url) return;
      _avatars[id] = bytes;
      setState(() {});
    }());
  }

  void _pushOverlay(
    AccordSettings settings,
    VoiceConnection voice, {
    required List<AccordVoiceState> states,
    required Map<String, AccordMember>? members,
    required Map<String, AccordUser> users,
    required String? cdnUrl,
  }) {
    final inChannel = voice.isConnected && voice.channelId != null;
    final speaking = voice.speakingUserIds;
    final roster = [
      for (final state in states)
        (
          state: state,
          display: participantDisplay(
            state.userId,
            members: members,
            users: users,
            cdnUrl: cdnUrl,
          ),
        ),
    ]..sort(
      (a, b) =>
          a.display.name.toLowerCase().compareTo(b.display.name.toLowerCase()),
    );
    final shownStates = settings.voiceOverlaySpeakersOnly
        ? roster.where((row) => speaking.contains(row.state.userId)).toList()
        : roster;
    for (final row in shownStates) {
      _ensureAvatar(row.state.userId, row.display.avatarUrl);
    }
    final shown = <SpeakerOverlayUser>[
      for (final row in shownStates)
        (
          id: row.state.userId,
          name: row.display.name,
          speaking: speaking.contains(row.state.userId),
          avatar: null,
        ),
    ];
    final visible =
        settings.voiceOverlayEnabled &&
        inChannel &&
        (settings.voiceOverlayEdit ||
            !settings.voiceOverlaySpeakersOnly ||
            shown.isNotEmpty);
    final payload = <SpeakerOverlayUser>[
      for (final person in shown)
        (
          id: person.id,
          name: person.name,
          speaking: person.speaking,
          avatar:
              _avatars[person.id] != null && !_avatarsSent.contains(person.id)
              ? _avatars[person.id]
              : null,
        ),
    ];
    final signature = [
      visible,
      settings.voiceOverlayEdit,
      settings.voiceOverlayMoved,
      settings.voiceOverlayX,
      settings.voiceOverlayY,
      for (final person in shown)
        '${person.id}:${person.speaking}:${person.name}:${_avatars.containsKey(person.id) ? (_avatars[person.id]?.length ?? 0) : -1}',
    ].join('|');
    if (signature == _overlaySignature) return;
    _overlaySignature = signature;
    final sending = [
      for (final person in payload)
        if (person.avatar != null) person.id,
    ];
    unawaited(() async {
      final ok = await SpeakerOverlay.update(
        visible: visible,
        editing: settings.voiceOverlayEdit,
        applyFrame: settings.voiceOverlayMoved,
        frame: Rect.fromLTWH(
          settings.voiceOverlayX,
          settings.voiceOverlayY,
          settings.voiceOverlayWidth,
          settings.voiceOverlayHeight,
        ),
        empty: '',
        hint: AppStrings.choose('Drag to move', '拖动即可移动'),
        users: payload,
      );
      if (!ok || !mounted) return;
      _avatarsSent.addAll(sending);
    }());
  }
}
