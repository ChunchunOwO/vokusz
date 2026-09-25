import 'package:bonfire/features/settings/controllers/settings.dart';
import 'package:bonfire/features/voice/controllers/accompaniment.dart';
import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

/// Chooses an application, plays or stops its audio, and sets the level.
/// Same kind of dialog as the soundboard.
Future<void> showAccompanimentPanel(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _AccompanimentPanel(),
  );
}

class AppAudioSource {
  const AppAudioSource(this.id, this.name);

  final String id;
  final String name;
}

/// Lists top-level windows. Capturing any window of an application captures
/// that process's audio.
Future<AppAudioSource?> showAccompanimentPicker(BuildContext context) {
  return showDialog<AppAudioSource>(
    context: context,
    builder: (_) => const _AccompanimentPicker(),
  );
}

class _AccompanimentPicker extends StatefulWidget {
  const _AccompanimentPicker();

  @override
  State<_AccompanimentPicker> createState() => _AccompanimentPickerState();
}

class _AccompanimentPickerState extends State<_AccompanimentPicker> {
  List<AppAudioSource> _sources = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sources = await rtc.desktopCapturer.getSources(
        types: [rtc.SourceType.Window],
      );
      final seen = <String>{};
      final apps = <AppAudioSource>[];
      for (final source in sources) {
        final name = source.name.trim();
        if (name.isEmpty || name == 'Vokusz' || !seen.add(name)) continue;
        apps.add(AppAudioSource(source.id, name));
      }
      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _sources = apps;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return AlertDialog(
      title: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          AppStrings.choose('Choose an application', '选择应用', context: context),
        ),
      ),
      content: SizedBox(
        width: 360,
        height: 360,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Text(_error!)
            : _sources.isEmpty
            ? Text(
                AppStrings.choose(
                  'No application windows are open',
                  '没有打开的应用窗口',
                  context: context,
                ),
                style: TextStyle(color: colors.gray),
              )
            : ListView.builder(
                itemCount: _sources.length,
                itemBuilder: (context, index) {
                  final source = _sources[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      source.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.of(context).pop(source),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.choose('Cancel', '取消', context: context)),
        ),
      ],
    );
  }
}

class _AccompanimentPanel extends ConsumerWidget {
  const _AccompanimentPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BonfireThemeExtension.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final accompaniment = ref.watch(accompanimentControllerProvider);
    final controls = ref.read(accompanimentControllerProvider.notifier);
    final volume = settings.accompanimentVolume.clamp(0, 200);
    final name = accompaniment.sourceName.isEmpty
        ? AppStrings.choose('No application selected', '未选择应用', context: context)
        : accompaniment.sourceName;
    return AlertDialog(
      title: Align(
        alignment: Alignment.centerLeft,
        child: Text(AppStrings.choose('Accompaniment', '伴奏', context: context)),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.choose(
                'Play a running application\'s audio into the voice channel. Your microphone stays separate, and this level only changes the accompaniment.',
                '把正在运行的应用的声音送进语音频道。麦克风不受影响，这个音量只调节伴奏。',
                context: context,
              ),
              style: theme.textTheme.bodySmall?.copyWith(color: colors.gray),
            ),
            const SizedBox(height: 12),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (accompaniment.error != null) ...[
              const SizedBox(height: 6),
              Text(
                accompaniment.error!,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.red),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton(
                  onPressed: accompaniment.busy
                      ? null
                      : () async {
                          final source = await showAccompanimentPicker(context);
                          if (source == null || !context.mounted) return;
                          final wasActive = accompaniment.active;
                          if (wasActive) await controls.stop();
                          controls.remember(source.id, source.name);
                          if (wasActive) await controls.start();
                        },
                  child: Text(
                    AppStrings.choose('Choose app', '选择应用', context: context),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: accompaniment.busy
                      ? null
                      : () async {
                          if (accompaniment.active) {
                            await controls.stop();
                            return;
                          }
                          if (accompaniment.sourceId.isEmpty) {
                            final source = await showAccompanimentPicker(
                              context,
                            );
                            if (source == null || !context.mounted) return;
                            controls.remember(source.id, source.name);
                          }
                          await controls.start();
                        },
                  child: Text(
                    accompaniment.active
                        ? AppStrings.choose('Stop', '停止', context: context)
                        : AppStrings.choose('Play', '播放', context: context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.choose(
                    'Accompaniment volume',
                    '伴奏音量',
                    context: context,
                  ),
                ),
                Text('$volume%'),
              ],
            ),
            Slider(
              value: volume.toDouble(),
              max: 200,
              divisions: 200,
              label: '$volume%',
              onChanged: (value) => ref
                  .read(settingsControllerProvider.notifier)
                  .setAccompanimentVolume(value.round()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.choose('Close', '关闭', context: context)),
        ),
      ],
    );
  }
}
