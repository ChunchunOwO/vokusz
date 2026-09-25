import 'package:bonfire/features/presence/foreground_app.dart';
import 'package:bonfire/features/presence/rich_presence.dart';
import 'package:bonfire/features/settings/controllers/settings.dart';
import 'package:bonfire/features/settings/models/accord_settings.dart';
import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Account controls for rich presence: off, automatic, a pinned game, or
/// custom text.
class RichPresenceSettings extends ConsumerStatefulWidget {
  const RichPresenceSettings({super.key});

  @override
  ConsumerState<RichPresenceSettings> createState() =>
      _RichPresenceSettingsState();
}

class _RichPresenceSettingsState extends ConsumerState<RichPresenceSettings> {
  late final TextEditingController _custom;
  bool _advanced = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsControllerProvider);
    _custom = TextEditingController(text: settings.richPresenceCustomName);
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final colors = BonfireThemeExtension.of(context);
    final enabled = settings.richPresenceEnabled;
    final mode = settings.richPresenceMode;
    final notifier = ref.read(settingsControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          value: enabled,
          onChanged: notifier.setRichPresenceEnabled,
          secondary: Icon(Icons.sports_esports_outlined, color: colors.dirtyWhite),
          title: Text(
            AppStrings.choose('Show activity', '显示动态', context: context),
          ),
          subtitle: Text(
            AppStrings.choose(
              'Turn this off and others stop seeing what you are doing.',
              '关闭后，别人就看不到你正在做什么。',
              context: context,
            ),
          ),
        ),
        if (enabled)
          ListTile(
            title: Text(
              AppStrings.choose(
                'Activity options',
                '动态高级设置',
                context: context,
              ),
            ),
            subtitle: Text(_modeSummary(mode, context)),
            trailing: Icon(
              _advanced ? Icons.expand_less : Icons.expand_more,
              color: colors.gray,
            ),
            onTap: () => setState(() => _advanced = !_advanced),
          ),
        if (enabled && _advanced) ...[
          _ModeTile(
            selected: mode == AccordSettings.richPresenceAuto,
            title: AppStrings.choose(
              'Detect automatically',
              '自动识别',
              context: context,
            ),
            subtitle: AppStrings.choose(
              'Follows the window in front.',
              '跟着当前窗口变化。',
              context: context,
            ),
            onTap: () => notifier.setRichPresenceMode(
              AccordSettings.richPresenceAuto,
            ),
          ),
          _ModeTile(
            selected: mode == AccordSettings.richPresenceFixed,
            title: AppStrings.choose('Choose a window', '选择窗口', context: context),
            subtitle: settings.richPresenceFixedName.trim().isEmpty
                ? AppStrings.choose(
                    'Keep one open window instead of following the front.',
                    '一直显示选中的窗口，不再跟着前台换。',
                    context: context,
                  )
                : settings.richPresenceFixedName.trim(),
            onTap: () => notifier.setRichPresenceMode(
              AccordSettings.richPresenceFixed,
            ),
          ),
          if (mode == AccordSettings.richPresenceFixed)
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showRecognizedWindowPicker(
                      context,
                      selectedPath: settings.richPresenceFixedPath,
                    );
                    if (picked == null) return;
                    notifier.setRichPresenceFixedWindow(picked.path, picked.name);
                  },
                  child: Text(
                    settings.richPresenceFixedName.trim().isEmpty
                        ? AppStrings.choose(
                            'Choose a window',
                            '选择窗口',
                            context: context,
                          )
                        : AppStrings.choose('Change', '更换', context: context),
                  ),
                ),
              ),
            ),
          _ModeTile(
            selected: mode == AccordSettings.richPresenceCustom,
            title: AppStrings.choose('Custom', '自定义', context: context),
            subtitle: AppStrings.choose(
              'Your own line replaces automatic detection.',
              '用你写的一句代替自动识别。',
              context: context,
            ),
            onTap: () => notifier.setRichPresenceMode(
              AccordSettings.richPresenceCustom,
            ),
          ),
          if (mode == AccordSettings.richPresenceCustom) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _custom,
                decoration: InputDecoration(
                  labelText: AppStrings.choose(
                    'What to show',
                    '显示内容',
                    context: context,
                  ),
                ),
                onChanged: notifier.setRichPresenceCustomName,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final kind in RichPresenceKind.values)
                    ChoiceChip(
                      label: Text(_kindLabel(kind, context)),
                      selected: settings.richPresenceCustomKind ==
                          richPresenceType(kind),
                      onSelected: (_) => notifier.setRichPresenceCustomKind(
                        richPresenceType(kind),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  String _modeSummary(String mode, BuildContext context) {
    final settings = ref.read(settingsControllerProvider);
    switch (mode) {
      case AccordSettings.richPresenceFixed:
        final name = settings.richPresenceFixedName.trim();
        return name.isEmpty
            ? AppStrings.choose('No window chosen', '还没选窗口', context: context)
            : name;
      case AccordSettings.richPresenceCustom:
        final name = settings.richPresenceCustomName.trim();
        return name.isEmpty
            ? AppStrings.choose('Custom', '自定义', context: context)
            : name;
      default:
        return AppStrings.choose(
          'Follows the front window',
          '跟着当前窗口',
          context: context,
        );
    }
  }

  String _kindLabel(RichPresenceKind kind, BuildContext context) {
    switch (kind) {
      case RichPresenceKind.playing:
        return AppStrings.choose('Playing', '正在玩', context: context);
      case RichPresenceKind.listening:
        return AppStrings.choose('Listening', '正在听', context: context);
      case RichPresenceKind.using:
        return AppStrings.choose('Using', '正在使用', context: context);
    }
  }
}

/// Popup of recognized windows, laid out like the screen-share picker.
Future<ForegroundApp?> showRecognizedWindowPicker(
  BuildContext context, {
  String selectedPath = '',
}) {
  return showDialog<ForegroundApp>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _WindowPickerDialog(selectedPath: selectedPath),
  );
}

class _WindowPickerDialog extends StatefulWidget {
  const _WindowPickerDialog({required this.selectedPath});

  final String selectedPath;

  @override
  State<_WindowPickerDialog> createState() => _WindowPickerDialogState();
}

class _WindowPickerDialogState extends State<_WindowPickerDialog> {
  List<ForegroundApp>? _windows;
  ForegroundApp? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final windows = await ForegroundApps.windows();
    if (!mounted) return;
    ForegroundApp? selected;
    for (final app in windows) {
      if (app.path == widget.selectedPath) {
        selected = app;
        break;
      }
    }
    setState(() {
      _windows = windows;
      _selected = selected ?? _selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    final windows = _windows;
    return Dialog(
      backgroundColor: colors.foreground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.web_asset_outlined,
                    size: 20,
                    color: colors.dirtyWhite,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.choose(
                        'Choose a window',
                        '选择窗口',
                        context: context,
                      ),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: Icon(Icons.refresh, size: 20, color: colors.gray),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, size: 20, color: colors.gray),
                  ),
                ],
              ),
            ),
            Flexible(
              child: windows == null
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : windows.isEmpty
                  ? Center(
                      child: Text(
                        AppStrings.choose(
                          'No window recognized right now.',
                          '当前没有识别到窗口。',
                          context: context,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.gray,
                        ),
                      ),
                    )
                  : GridView.count(
                      padding: const EdgeInsets.all(16),
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        for (final app in windows)
                          _WindowTile(
                            name: app.name,
                            selected: _selected?.path == app.path,
                            colors: colors,
                            onTap: () => setState(() => _selected = app),
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      AppStrings.choose('Cancel', '取消', context: context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _selected == null
                        ? null
                        : () => Navigator.of(context).pop(_selected),
                    child: Text(
                      AppStrings.choose('Choose', '确定', context: context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowTile extends StatelessWidget {
  const _WindowTile({
    required this.name,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final BonfireThemeExtension colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            width: 2,
            color: selected ? colors.primary : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.web_asset_outlined,
              size: 28,
              color: selected ? colors.dirtyWhite : colors.gray,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? colors.dirtyWhite : colors.gray,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return ListTile(
      onTap: onTap,
      dense: true,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? colors.primary : colors.gray,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
