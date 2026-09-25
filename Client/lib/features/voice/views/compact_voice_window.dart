import 'dart:async';

import 'package:accordkit/accordkit.dart' show AccordVoiceState;
import 'package:bonfire/features/member/controllers/accord_members.dart';
import 'package:bonfire/features/member/utils/member_display.dart';
import 'package:bonfire/features/member/views/accord_member_avatar.dart';
import 'package:bonfire/features/settings/controllers/settings.dart';
import 'package:bonfire/features/user/controllers/accord_users.dart';
import 'package:bonfire/features/voice/controllers/voice.dart';
import 'package:bonfire/features/voice/controllers/voice_states.dart';
import 'package:bonfire/features/voice/utils/participant_display.dart';
import 'package:bonfire/features/voice/utils/voice_logic.dart';
import 'package:bonfire/features/voice/views/compact_voice_mode.dart';
import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/shared/components/desktop_window_bar.dart';
import 'package:bonfire/shared/components/horizontal_wheel_scroll.dart';
import 'package:bonfire/shared/utils/client_access.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

/// Whether the microphone is actually transmitting. Push-to-talk updates this
/// from the key poll without rebuilding the whole shell.
final transmitLive = ValueNotifier<bool>(false);

/// Icon button that does not keep the default 48px slot. The microphone sits
/// against the talk-mode label; the other controls stay a normal tap size.
class _CompactIcon extends StatelessWidget {
  const _CompactIcon({
    required this.onPressed,
    required this.icon,
    this.width = 32,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        fixedSize: Size(width, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: icon,
    );
  }
}

const double _barHeight = CompactVoiceMode.barHeight;
const double _barRule = CompactVoiceMode.rule;
const double _avatarStrip = CompactVoiceMode.stripHeight;
const Color _speakingBlue = Color(0xFF4DA3FF);

class CompactVoiceWindow extends ConsumerWidget {
  const CompactVoiceWindow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BonfireThemeExtension.of(context);
    final voice = ref.watch(voiceControllerProvider);
    final pushToTalk = ref.watch(
      settingsControllerProvider.select((settings) => settings.voicePushToTalk),
    );
    final faces = _faces(ref, voice);
    final height = faces.isEmpty
        ? _barHeight + _barRule
        : _barHeight + _barRule + _avatarStrip;
    final stripReady =
        faces.isNotEmpty &&
        CompactVoiceMode.instance.appliedHeight + 0.5 >= height;
    if (CompactVoiceMode.instance.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(CompactVoiceMode.instance.fit(height));
      });
    }
    final connected = voice.isConnected;
    final mode = pushToTalk
        ? AppStrings.choose('Push to talk', '按键说话', context: context)
        : AppStrings.choose('Open mic', '自由发言', context: context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Material(
        color: colors.background,
        child: Column(
          children: [
            SizedBox(
              height: _barHeight,
              child: Row(
                children: [
                  Expanded(
                    child: DragToMoveArea(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onDoubleTap: CompactVoiceMode.instance.exit,
                        child: const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: VokuszShimmerTitle(fontSize: 17),
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onSecondaryTap: () => ref
                        .read(settingsControllerProvider.notifier)
                        .setVoicePushToTalk(!pushToTalk),
                    child: _CompactIcon(
                      width: 26,
                      onPressed: () {
                        if (!connected || pushToTalk) return;
                        ref.read(voiceControllerProvider.notifier).toggleMute();
                      },
                      icon: Icon(
                        pushToTalk
                            ? Icons.keyboard
                            : (connected && !voice.selfMute
                                  ? Icons.mic
                                  : Icons.mic_off),
                        size: 18,
                        color: pushToTalk
                            ? colors.dirtyWhite
                            : (connected && !voice.selfMute
                                  ? colors.dirtyWhite
                                  : colors.red),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => ref
                        .read(settingsControllerProvider.notifier)
                        .setVoicePushToTalk(!pushToTalk),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(2, 6, 8, 6),
                      child: Text(
                        mode,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.dirtyWhite,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  _CompactIcon(
                    onPressed: connected
                        ? () => ref
                              .read(voiceControllerProvider.notifier)
                              .toggleDeafen()
                        : null,
                    icon: Icon(
                      voice.selfDeaf ? Icons.headset_off : Icons.headset,
                      size: 18,
                      color: voice.selfDeaf ? colors.red : colors.dirtyWhite,
                    ),
                  ),
                  _CompactIcon(
                    onPressed: connected
                        ? () => ref.read(voiceControllerProvider.notifier).leave()
                        : null,
                    icon: Icon(Icons.call_end, size: 18, color: colors.red),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _CompactIcon(
                      onPressed: CompactVoiceMode.instance.exit,
                      icon: Icon(
                        Icons.open_in_full,
                        size: 16,
                        color: colors.gray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: _barRule,
              color: colors.dirtyWhite.withValues(alpha: 0.16),
            ),
            if (stripReady)
              SizedBox(
                height: _avatarStrip,
                child: _AvatarStrip(faces: faces),
              ),
          ],
        ),
      ),
    );
  }

  List<({String id, String name, String? avatarUrl, Color color, bool serverSpeaking})>
  _faces(WidgetRef ref, VoiceConnection voice) {
    final channelId = voice.channelId;
    if (channelId == null) return const [];
    final serverKey = voice.serverKey ?? '';
    final states = ref.watch(
      voiceStatesControllerProvider(serverKey).select(
        (cache) => voiceStatesFor(cache, channelId),
      ),
    );
    final spaceId = voice.spaceId;
    final members = spaceId == null
        ? null
        : ref.watch(accordMembersControllerProvider(serverKey, spaceId));
    final users = ref.watch(accordUsersControllerProvider(serverKey));
    final cdn = ref.watchCdnUrl();
    final speaking = voice.speakingUserIds;
    final faces = [
      for (final AccordVoiceState state in states)
        () {
          final display = participantDisplay(
            state.userId,
            members: members,
            users: users,
            cdnUrl: cdn,
          );
          return (
            id: state.userId,
            name: display.name,
            avatarUrl: display.avatarUrl,
            color: display.color,
            serverSpeaking: speaking.contains(state.userId),
          );
        }(),
    ];
    faces.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return faces;
  }
}

/// Avatars under the compact title. Speaking is sampled from local audio
/// levels so the ring tracks the voice instead of the server's delayed flag.
class _AvatarStrip extends ConsumerStatefulWidget {
  const _AvatarStrip({required this.faces});

  final List<
    ({
      String id,
      String name,
      String? avatarUrl,
      Color color,
      bool serverSpeaking,
    })
  >
  faces;

  @override
  ConsumerState<_AvatarStrip> createState() => _AvatarStripState();
}

class _AvatarStripState extends ConsumerState<_AvatarStrip> {
  static const _hold = Duration(milliseconds: 140);

  Timer? _timer;
  Set<String> _speaking = const {};
  final Map<String, DateTime> _releaseAt = {};

  @override
  void initState() {
    super.initState();
    _speaking = _sample();
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) => _sync());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _sync() {
    if (!mounted) return;
    final next = _sample();
    if (next.length == _speaking.length && next.containsAll(_speaking)) return;
    setState(() => _speaking = next);
  }

  Set<String> _sample() {
    final levels = ref.read(voiceControllerProvider.notifier).audioLevels;
    final threshold = ref.read(settingsControllerProvider).speakingThreshold;
    final now = DateTime.now();
    final speaking = <String>{};
    final present = <String>{};
    for (final face in widget.faces) {
      present.add(face.id);
      final hot = levelSaysSpeaking(
        level: levels[face.id],
        threshold: threshold,
        serverSpeaking: face.serverSpeaking,
      );
      if (hot) {
        _releaseAt[face.id] = now.add(_hold);
        speaking.add(face.id);
      } else if (_releaseAt[face.id]?.isAfter(now) ?? false) {
        speaking.add(face.id);
      }
    }
    _releaseAt.removeWhere((id, _) => !present.contains(id));
    return speaking;
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _DragScroll(),
      child: HorizontalWheelScroll(
      builder: (context, controller) => ListView.separated(
        controller: controller,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        itemCount: widget.faces.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final face = widget.faces[index];
          return Semantics(
            label: face.name,
            child: _SpeakingAvatar(
              avatarUrl: face.avatarUrl,
              initial: accordInitial(face.name),
              backgroundColor: face.color,
              speaking: _speaking.contains(face.id),
            ),
          );
        },
      ),
      ),
    );
  }
}

/// Lets a mouse drag the compact avatar strip sideways. Desktop scrolling
/// otherwise ignores mouse drags.
class _DragScroll extends MaterialScrollBehavior {
  const _DragScroll();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class _SpeakingAvatar extends StatelessWidget {
  const _SpeakingAvatar({
    required this.avatarUrl,
    required this.initial,
    required this.backgroundColor,
    required this.speaking,
  });

  final String? avatarUrl;
  final String initial;
  final Color backgroundColor;
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    // 48px face inside a 52px ring, centered in the 56px slot so the glow
    // stays on the same circle as the picture.
    return SizedBox(
      width: 56,
      height: 56,
      child: Center(
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: speaking ? _speakingBlue : const Color(0x00000000),
              width: 2,
            ),
            boxShadow: speaking
                ? const [
                    BoxShadow(
                      color: Color(0xB34DA3FF),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: AccordMemberAvatar(
            avatarUrl: avatarUrl,
            initial: initial,
            radius: 24,
            backgroundColor: backgroundColor,
            initialStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
