import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/l10n/ui_copy.dart';
import 'package:bonfire/features/settings/controllers/settings.dart';
import 'package:bonfire/shared/components/settings_scaffold.dart';
import 'package:bonfire/shared/components/section_header.dart';
import 'package:bonfire/features/settings/models/accord_settings.dart';
import 'package:bonfire/features/voice/controllers/voice.dart';
import 'package:bonfire/features/voice/views/key_bind_tile.dart';
import 'package:bonfire/features/voice/utils/afk_logic.dart';
import 'package:bonfire/features/voice/utils/audio_output_support.dart';
import 'package:bonfire/features/voice/views/mic_level_meter.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';

/// Opens the Voice & Video settings page (input/output devices, volumes,
/// sensitivity + live mic test, camera). Ports the reference client's
/// `app_settings` Voice & Video page reached from the voice bar's gear.
Future<void> showVoiceSettings(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const VoiceSettingsScreen()));
}

class VoiceSettingsScreen extends ConsumerStatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  ConsumerState<VoiceSettingsScreen> createState() =>
      _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends ConsumerState<VoiceSettingsScreen> {
  List<MediaDevice> _audioInputs = const [];
  List<MediaDevice> _audioOutputs = const [];
  List<MediaDevice> _videoInputs = const [];
  bool _loadingDevices = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final inputs = await Hardware.instance.audioInputs();
      final outputs = await Hardware.instance.audioOutputs();
      final cameras = await Hardware.instance.videoInputs();
      if (!mounted) return;
      setState(() {
        _audioInputs = inputs;
        _audioOutputs = outputs;
        _videoInputs = cameras;
        _loadingDevices = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDevices = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final connected = ref.watch(
      voiceControllerProvider.select((v) => v.isConnected),
    );

    return SettingsScaffold(
      title: UiCopy.voiceVideo(context: context),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          SwitchListTile(
            title: Text(UiCopy.relayOnlyVoice(context: context)),
            subtitle: Text(
              UiCopy.routeVoiceVideoAndScreenSharingThrough(context: context),
            ),
            value: settings.voiceRelayOnly,
            onChanged: controller.setVoiceRelayOnly,
          ),
          SectionHeader(UiCopy.inputDevice(context: context)),
          _DeviceDropdown(
            devices: _audioInputs,
            loading: _loadingDevices,
            selectedId: settings.audioInputDeviceId,
            fallbackLabel: UiCopy.microphone(context: context),
            onChanged: controller.setAudioInputDevice,
          ),
          _PercentSlider(
            label: UiCopy.inputVolume(context: context),
            value: settings.inputVolume,
            onChanged: controller.setInputVolume,
          ),
          SectionHeader(UiCopy.micTest(context: context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MicLevelMeter(
                  height: 10,
                  threshold: settings.speakingThreshold,
                ),
                const SizedBox(height: 6),
                Text(
                  connected
                      ? UiCopy.speakTheBarLightsUpGreenWhen(context: context)
                      : UiCopy.joinAVoiceChannelToTestYour(context: context),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(color: colors.gray),
                ),
              ],
            ),
          ),
          _PercentSlider(
            label: UiCopy.inputSensitivity(context: context),
            value: settings.inputSensitivity,
            max: 100,
            onChanged: controller.setInputSensitivity,
          ),
          const Divider(height: 24),
          if (canPickAudioOutputDevice) ...[
            SectionHeader(UiCopy.outputDevice(context: context)),
            _DeviceDropdown(
              key: const Key('audio-output-dropdown'),
              devices: _audioOutputs,
              loading: _loadingDevices,
              selectedId: settings.audioOutputDeviceId,
              fallbackLabel: UiCopy.speaker(context: context),
              onChanged: controller.setAudioOutputDevice,
            ),
          ],
          _PercentSlider(
            label: UiCopy.outputVolume(context: context),
            value: settings.outputVolume,
            onChanged: controller.setOutputVolume,
          ),
          const Divider(height: 24),
          const _TalkModeSection(),
          const Divider(height: 24),
          const _SpeakerOverlaySection(),
          const Divider(height: 24),
          SectionHeader(UiCopy.away(context: context)),
          ListTile(
            title: Text(UiCopy.markMeAwayAfter(context: context)),
            subtitle: Text(
              UiCopy.whileInAVoiceChannelWithNo(context: context),
              style: theme.textTheme.bodySmall!.copyWith(color: colors.gray),
            ),
            trailing: DropdownButton<int>(
              key: const Key('afk-timeout-dropdown'),
              value:
                  afkTimeoutOptionsMinutes.contains(
                    settings.voiceAfkTimeoutMinutes,
                  )
                  ? settings.voiceAfkTimeoutMinutes
                  : defaultAfkTimeoutMinutes,
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) {
                  controller.setVoiceAfkTimeoutMinutes(value);
                }
              },
              items: [
                for (final minutes in afkTimeoutOptionsMinutes)
                  DropdownMenuItem(
                    value: minutes,
                    child: Text(afkTimeoutLabel(minutes)),
                  ),
              ],
            ),
          ),
          SwitchListTile(
            key: const Key('afk-auto-move-switch'),
            title: Text(UiCopy.moveMeToTheAfkChannel(context: context)),
            subtitle: Text(
              UiCopy.whenTheSpaceHasOneSetYou(context: context),
              style: theme.textTheme.bodySmall!.copyWith(color: colors.gray),
            ),
            value: settings.voiceAfkAutoMove,
            onChanged: settings.voiceAfkTimeoutMinutes > 0
                ? controller.setVoiceAfkAutoMove
                : null,
          ),
          const Divider(height: 24),
          SectionHeader(UiCopy.camera(context: context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              UiCopy.qualityOfYourWebcamWhenYouTurn(context: context),
              style: theme.textTheme.bodySmall!.copyWith(color: colors.gray),
            ),
          ),
          _DeviceDropdown(
            devices: _videoInputs,
            loading: _loadingDevices,
            selectedId: settings.videoInputDeviceId,
            fallbackLabel: UiCopy.camera(context: context),
            onChanged: controller.setVideoInputDevice,
          ),
          ListTile(
            key: const Key('camera-resolution-dropdown'),
            title: Text(UiCopy.cameraResolution(context: context)),
            trailing: DropdownButton<int>(
              value: settings.videoResolution,
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) controller.setVideoResolution(value);
              },
              items: [
                for (
                  var i = 0;
                  i < AccordSettings.videoResolutionLabels.length;
                  i++
                )
                  DropdownMenuItem(
                    value: i,
                    child: Text(AccordSettings.videoResolutionLabels[i]),
                  ),
              ],
            ),
          ),
          ListTile(
            key: const Key('camera-fps-dropdown'),
            title: Text(UiCopy.cameraFrameRate(context: context)),
            trailing: DropdownButton<int>(
              value: settings.videoFps,
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) controller.setVideoFps(value);
              },
              items: [
                for (final fps in AccordSettings.videoFpsOptions)
                  DropdownMenuItem(
                    value: fps,
                    child: Text(UiCopy.fps(context: context, arg0: fps)),
                  ),
              ],
            ),
          ),
          const Divider(height: 24),
          SectionHeader(UiCopy.screenShare(context: context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              UiCopy.separateFromTheCameraSettingsAboveThese(context: context),
              style: theme.textTheme.bodySmall!.copyWith(color: colors.gray),
            ),
          ),
          ListTile(
            key: const Key('screen-share-resolution-dropdown'),
            title: Text(UiCopy.screenShareResolution(context: context)),
            subtitle: Text(
              UiCopy.higherResolutionsNeedMoreUploadAndCpu(context: context),
              style: theme.textTheme.bodySmall!.copyWith(color: colors.gray),
            ),
            trailing: DropdownButton<int>(
              value: settings.screenShareResolution,
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) controller.setScreenShareResolution(value);
              },
              items: [
                for (
                  var i = 0;
                  i < AccordSettings.screenShareResolutionLabels.length;
                  i++
                )
                  DropdownMenuItem(
                    value: i,
                    child: Text(AccordSettings.screenShareResolutionLabels[i]),
                  ),
              ],
            ),
          ),
          ListTile(
            key: const Key('screen-share-fps-dropdown'),
            title: Text(UiCopy.screenShareFrameRate(context: context)),
            subtitle: Text(
              UiCopy.message60FpsForGamesAndVideo30(context: context),
              style: theme.textTheme.bodySmall!.copyWith(color: colors.gray),
            ),
            trailing: DropdownButton<int>(
              value: settings.screenShareFps,
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) controller.setScreenShareFps(value);
              },
              items: [
                for (final fps in AccordSettings.screenShareFpsOptions)
                  DropdownMenuItem(
                    value: fps,
                    child: Text(UiCopy.fps(context: context, arg0: fps)),
                  ),
              ],
            ),
          ),
          SwitchListTile(
            key: const Key('screen-share-motion-switch'),
            title: Text(UiCopy.prioritiseSmoothMotion(context: context)),
            subtitle: Text(
              UiCopy.keepsTheFrameRateUpOnA(context: context),
              style: theme.textTheme.bodySmall!.copyWith(color: colors.gray),
            ),
            value: settings.screenShareMotionPriority,
            onChanged: controller.setScreenShareMotionPriority,
          ),
        ],
      ),
    );
  }
}

/// A device picker with a leading "System default" option (empty id).
class _DeviceDropdown extends StatelessWidget {
  const _DeviceDropdown({
    super.key,
    required this.devices,
    required this.loading,
    required this.selectedId,
    required this.fallbackLabel,
    required this.onChanged,
  });

  final List<MediaDevice> devices;
  final bool loading;
  final String selectedId;
  final String fallbackLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    // Only offer the saved id if it still exists; otherwise fall back to
    // default so the dropdown has a valid value.
    final ids = devices.map((d) => d.deviceId).toSet();
    final value = ids.contains(selectedId) ? selectedId : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        onChanged: loading ? null : (v) => onChanged(v ?? ''),
        items: [
          DropdownMenuItem(
            value: '',
            child: Text(UiCopy.systemDefault(context: context)),
          ),
          for (var i = 0; i < devices.length; i++)
            DropdownMenuItem(
              value: devices[i].deviceId,
              child: Text(
                devices[i].label.isNotEmpty
                    ? devices[i].label
                    : '$fallbackLabel ${i + 1}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

/// A labelled 0–[max]% slider showing the current percentage.
class _PercentSlider extends StatelessWidget {
  const _PercentSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.max = 200,
  });

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text('$value%')],
      ),
      subtitle: Slider(
        value: value.toDouble().clamp(0, max.toDouble()),
        max: max.toDouble(),
        divisions: max,
        onChanged: (v) => onChanged(v.round()),
      ),
    );
  }
}

class _TalkModeSection extends ConsumerWidget {
  const _TalkModeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BonfireThemeExtension.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(AppStrings.choose('Talk mode', '说话方式', context: context)),
        SwitchListTile(
          title: Text(AppStrings.choose('Push to talk', '按键说话', context: context)),
          subtitle: Text(
            AppStrings.choose(
              'The microphone opens only while the key is held.',
              '只有按住按键时才会说话。',
              context: context,
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.gray,
            ),
          ),
          value: settings.voicePushToTalk,
          onChanged: controller.setVoicePushToTalk,
        ),
        KeyBindTile(
          title: AppStrings.choose('Push-to-talk key', '按键说话快捷键', context: context),
          virtualKey: settings.voicePushToTalkKey,
          onChanged: controller.setVoicePushToTalkKey,
        ),
      ],
    );
  }
}

class _SpeakerOverlaySection extends ConsumerWidget {
  const _SpeakerOverlaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BonfireThemeExtension.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          AppStrings.choose('Screen overlay', '屏幕覆盖', context: context),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            AppStrings.choose(
              'Appears above other windows after you join a voice channel.',
              '加入语音频道后，才会显示在屏幕最上方。',
              context: context,
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: colors.gray),
          ),
        ),
        SwitchListTile(
          title: Text(
            AppStrings.choose('Overlay switch', '屏幕覆盖开关', context: context),
          ),
          value: settings.voiceOverlayEnabled,
          onChanged: controller.setVoiceOverlayEnabled,
        ),
        KeyBindTile(
          title: AppStrings.choose('Overlay shortcut', '覆盖快捷键', context: context),
          virtualKey: settings.voiceOverlayHotkey,
          onChanged: controller.setVoiceOverlayHotkey,
        ),
        SwitchListTile(
          title: Text(AppStrings.choose('Edit mode', '编辑模式', context: context)),
          subtitle: Text(
            AppStrings.choose(
              'Drag the overlay to move it.',
              '拖动覆盖窗口即可移动位置。',
              context: context,
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: colors.gray),
          ),
          value: settings.voiceOverlayEdit,
          onChanged: settings.voiceOverlayEnabled
              ? controller.setVoiceOverlayEdit
              : null,
        ),
        SwitchListTile(
          title: Text(
            AppStrings.choose(
              'Speaking users only',
              '只显示正在说话的用户',
              context: context,
            ),
          ),
          subtitle: Text(
            AppStrings.choose(
              'When on, only people who are speaking are shown.',
              '开启后，只显示正在说话的人。',
              context: context,
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: colors.gray),
          ),
          value: settings.voiceOverlaySpeakersOnly,
          onChanged: controller.setVoiceOverlaySpeakersOnly,
        ),
      ],
    );
  }
}
