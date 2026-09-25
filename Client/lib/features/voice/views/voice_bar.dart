import 'package:bonfire/shared/utils/client_access.dart';
import 'dart:async';

import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/channels/controllers/accord_channels.dart';
import 'package:bonfire/features/member/utils/permissions.dart';
import 'package:bonfire/features/settings/controllers/settings.dart';
import 'package:bonfire/features/spaces/controllers/spaces.dart';
import 'package:bonfire/features/spaces/views/accord_soundboard.dart';
import 'package:bonfire/features/voice/controllers/voice.dart';
import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/features/voice/services/voice_session.dart';
import 'package:bonfire/features/voice/views/mic_level_meter.dart';
import 'package:bonfire/features/voice/views/screen_share_picker.dart';
import 'package:bonfire/features/voice/views/voice_settings_screen.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The voice-connection panel shown above the user controls while connected to
/// a channel. Ports the reference client's `voice_bar.gd`: a status row
/// (channel name + pulsing connection dot, with transient errors) over a row of
/// mute / deafen / video / screen-share / disconnect buttons.
class VoiceBar extends ConsumerStatefulWidget {
  const VoiceBar({super.key, this.onTapStatus});

  /// Called when the status row is tapped — the host opens the voice view for
  /// the connected channel.
  final VoidCallback? onTapStatus;

  @override
  ConsumerState<VoiceBar> createState() => _VoiceBarState();
}

class _VoiceBarState extends ConsumerState<VoiceBar> {
  Timer? _errorTimer;

  @override
  void dispose() {
    _errorTimer?.cancel();
    super.dispose();
  }

  void _scheduleErrorClear() {
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) ref.read(voiceControllerProvider.notifier).clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final voice = ref.watch(voiceControllerProvider);
    if (!voice.isConnected) return const SizedBox.shrink();

    // Drive the 4s error auto-dismiss off the current state.
    if (voice.error != null) {
      _scheduleErrorClear();
    }

    final channelName = voice.spaceId == null
        ? null
        : ref
              .watch(
                accordChannelsControllerProvider(
                  voice.serverKey ?? ref.readActiveServerKey() ?? '',
                  voice.spaceId!,
                ),
              )
              ?.firstWhereOrNull((c) => c.id == voice.channelId)
              ?.name;

    final spaceId = voice.spaceId;
    var canUseSoundboard = false;
    var canManageSoundboard = false;
    if (spaceId != null) {
      final space = ref.watch(
        spacesControllerProvider.select(
          (s) => s?.firstWhereOrNull((sp) => sp.id == spaceId),
        ),
      );
      final perms = ref.watchAccordPermissions(space, spaceId);
      canUseSoundboard = accordHasPermission(
        perms,
        AccordPermission.useSoundboard,
      );
      canManageSoundboard = accordHasPermission(
        perms,
        AccordPermission.manageSoundboard,
      );
    }

    final (statusText, statusColor) = _status(voice, colors, channelName);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.darkGray)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: widget.onTapStatus,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        statusText,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium!.copyWith(color: statusColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _VoiceButton(
                  icon: _micIcon(ref, voice.selfMute),
                  tooltip: _micTooltip(context, ref, voice.selfMute),
                  active: _micActive(ref, voice.selfMute),
                  activeColor: colors.red,
                  onPressed: () {
                    if (ref.read(settingsControllerProvider).voicePushToTalk) {
                      return;
                    }
                    ref.read(voiceControllerProvider.notifier).toggleMute();
                  },
                  onSecondaryPressed: () => _toggleTalkMode(ref),
                ),
                _VoiceButton(
                  icon: voice.selfDeaf ? Icons.headset_off : Icons.headset,
                  tooltip: voice.selfDeaf
                      ? AppStrings.of(context).undeafen
                      : AppStrings.of(context).deafen,
                  active: voice.selfDeaf,
                  activeColor: colors.red,
                  onPressed: () =>
                      ref.read(voiceControllerProvider.notifier).toggleDeafen(),
                ),
                _VoiceButton(
                  icon: voice.selfVideo ? Icons.videocam_off : Icons.videocam,
                  tooltip: voice.selfVideo
                      ? AppStrings.of(context).stopCamera
                      : AppStrings.of(context).camera,
                  active: voice.selfVideo,
                  activeColor: colors.green,
                  onPressed: () =>
                      ref.read(voiceControllerProvider.notifier).toggleVideo(),
                ),
                if (!kIsWeb)
                  _VoiceButton(
                    icon: voice.selfStream
                        ? Icons.stop_screen_share
                        : Icons.screen_share,
                    tooltip: voice.selfStream
                        ? AppStrings.of(context).stopShare
                        : AppStrings.of(context).screenShare,
                    active: voice.selfStream,
                    activeColor: colors.green,
                    onPressed: () => toggleScreenShareWithPicker(context, ref),
                  ),
                if (canUseSoundboard && spaceId != null)
                  _VoiceButton(
                    icon: Icons.graphic_eq,
                    tooltip: AppStrings.of(context).soundboard,
                    active: false,
                    activeColor: colors.primary,
                    onPressed: () => showAccordSoundboard(
                      context,
                      spaceId: spaceId,
                      canManage: canManageSoundboard,
                    ),
                  ),
                const Spacer(),
                _VoiceButton(
                  icon: Icons.settings,
                  tooltip: AppStrings.of(context).voiceSettings,
                  active: false,
                  activeColor: colors.primary,
                  onPressed: () => showVoiceSettings(context),
                ),
                _VoiceButton(
                  icon: Icons.call_end,
                  tooltip: AppStrings.of(context).disconnect,
                  active: false,
                  activeColor: colors.red,
                  iconColor: colors.red,
                  onPressed: () =>
                      ref.read(voiceControllerProvider.notifier).leave(),
                ),
              ],
            ),
            // Live mic-activity meter — shows the user their input is picked up.
            if (!voice.selfMute) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: MicLevelMeter(
                  height: 4,
                  threshold: ref.watch(
                    settingsControllerProvider.select(
                      (s) => s.speakingThreshold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (String, Color) _status(
    VoiceConnection voice,
    BonfireThemeExtension colors,
    String? channelName,
  ) {
    if (voice.error != null) return (voice.error!, colors.red);
    // Tell the user *why* they've dimmed out in the participant list — an AFK
    // badge nobody explains is just a mystery.
    final text = AppStrings.of(context);
    if (voice.isAfk && voice.sessionState == VoiceSessionState.connected) {
      return (text.awayIn(channelName), colors.yellow);
    }
    switch (voice.sessionState) {
      case VoiceSessionState.connected:
        return (channelName ?? text.voiceConnected, colors.green);
      case VoiceSessionState.connecting:
        return (text.connecting, colors.yellow);
      case VoiceSessionState.reconnecting:
        return (text.reconnecting, colors.yellow);
      case VoiceSessionState.failed:
        return (text.connectionFailed, colors.red);
      case VoiceSessionState.disconnected:
        return (channelName ?? text.voice, colors.gray);
    }
  }
}

bool _pushToTalk(WidgetRef ref) => ref.watch(
  settingsControllerProvider.select((settings) => settings.voicePushToTalk),
);

void _toggleTalkMode(WidgetRef ref) {
  final enabled = ref.read(settingsControllerProvider).voicePushToTalk;
  ref.read(settingsControllerProvider.notifier).setVoicePushToTalk(!enabled);
}

IconData _micIcon(WidgetRef ref, bool muted) =>
    _pushToTalk(ref) ? Icons.keyboard : (muted ? Icons.mic_off : Icons.mic);

String _micTooltip(BuildContext context, WidgetRef ref, bool muted) {
  if (_pushToTalk(ref)) {
    return AppStrings.choose(
      'Push to talk',
      '按键说话',
      context: context,
    );
  }
  return muted
      ? AppStrings.of(context).unmute
      : AppStrings.of(context).mute;
}

bool _micActive(WidgetRef ref, bool muted) => !_pushToTalk(ref) && muted;

class _VoiceButton extends StatelessWidget {
  const _VoiceButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.activeColor,
    required this.onPressed,
    this.onSecondaryPressed,
    this.iconColor,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final Color activeColor;
  final Color? iconColor;
  final VoidCallback onPressed;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: GestureDetector(
        onSecondaryTap: onSecondaryPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: active ? activeColor : Colors.transparent,
            ),
          ),
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(icon, size: 18, color: iconColor ?? colors.dirtyWhite),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ),
      ),
    );
  }
}
