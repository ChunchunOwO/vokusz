import 'package:bonfire/l10n/ui_copy.dart';
import 'package:bonfire/l10n/app_strings.dart';
import 'dart:async';

import 'package:bonfire/features/voice/controllers/voice.dart';
import 'package:bonfire/features/settings/controllers/settings.dart';
import 'package:bonfire/features/settings/models/accord_settings.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:universal_platform/universal_platform.dart';

/// A desktop share choice: which surface, and whether to send system audio
/// along with the picture.
class ScreenShareRequest {
  const ScreenShareRequest(this.source, {required this.shareSystemAudio});

  final rtc.DesktopCapturerSource source;
  final bool shareSystemAudio;
}

/// Shows a desktop screen/window source picker (Screen and Window tabs with
/// live thumbnails). Returns the chosen source, or null if cancelled.
///
/// This is our own picker rather than LiveKit's bundled `ScreenSelectDialog`:
/// that SDK widget subscribes to flutter_webrtc's thumbnail stream and calls
/// `setState` on a `StatefulBuilder` from the callback without a `mounted`
/// guard or cancelling on dispose, so a late thumbnail event after the dialog
/// is dismissed throws "setState() called after dispose()". Our dialog cancels
/// its subscriptions in `dispose()` and guards every `setState` with `mounted`.
Future<ScreenShareRequest?> showScreenShareSourcePicker(
  BuildContext context,
) {
  return showDialog<ScreenShareRequest>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _ScreenShareSourceDialog(),
  );
}

/// Starts or stops screen sharing for the current voice session.
///
/// On desktop, starting first prompts the user to pick a screen or window;
/// cancelling the picker aborts without sharing. On web/mobile the platform
/// shows its own native capture prompt, so we toggle directly.
Future<void> toggleScreenShareWithPicker(
  BuildContext context,
  WidgetRef ref,
) async {
  final notifier = ref.read(voiceControllerProvider.notifier);
  final sharing = ref.read(voiceControllerProvider).selfStream;

  try {
    if (sharing) {
      await notifier.toggleScreenShare();
      return;
    }

    if (UniversalPlatform.isDesktop) {
      final request = await showScreenShareSourcePicker(context);
      if (request == null) return; // cancelled
      await notifier.toggleScreenShare(
        sourceId: request.source.id,
        shareSystemAudio: request.shareSystemAudio,
      );
    } else {
      await notifier.toggleScreenShare();
    }
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.choose(
            'Could not start screen sharing: $error',
            '无法启动屏幕共享：$error',
            context: context,
          ),
        ),
      ),
    );
  }
}

class _ScreenShareSourceDialog extends ConsumerStatefulWidget {
  const _ScreenShareSourceDialog();

  @override
  ConsumerState<_ScreenShareSourceDialog> createState() =>
      _ScreenShareSourceDialogState();
}

class _ScreenShareSourceDialogState
    extends ConsumerState<_ScreenShareSourceDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(_onTabChanged);

  final List<StreamSubscription<rtc.DesktopCapturerSource>> _subscriptions = [];
  final Map<String, rtc.DesktopCapturerSource> _sources = {};

  rtc.SourceType _sourceType = rtc.SourceType.Screen;
  rtc.DesktopCapturerSource? _selectedSource;
  bool _shareSystemAudio = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _subscriptions.add(
      rtc.desktopCapturer.onAdded.stream.listen((source) {
        if (!mounted) return;
        setState(() => _sources[source.id] = source);
      }),
    );
    _subscriptions.add(
      rtc.desktopCapturer.onRemoved.stream.listen((source) {
        if (!mounted) return;
        setState(() => _sources.remove(source.id));
      }),
    );
    _subscriptions.add(
      rtc.desktopCapturer.onThumbnailChanged.stream.listen((_) {
        if (!mounted) return;
        setState(() {});
      }),
    );

    _loadSources();
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _refreshTimer?.cancel();
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    final type = _tabs.index == 0
        ? rtc.SourceType.Screen
        : rtc.SourceType.Window;
    if (type == _sourceType) return;
    _sourceType = type;
    _loadSources();
  }

  Future<void> _loadSources() async {
    try {
      final sources = await rtc.desktopCapturer.getSources(
        types: [_sourceType],
      );
      if (!mounted) return;
      setState(() {
        _sources
          ..clear()
          ..addEntries(sources.map((s) => MapEntry(s.id, s)));
      });
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        unawaited(rtc.desktopCapturer.updateSources(types: [_sourceType]));
      });
    } catch (_) {
      // Enumeration can fail transiently (e.g. permissions not yet granted);
      // the periodic refresh and add/remove streams will recover.
    }
  }

  void _confirm() {
    final source = _selectedSource;
    if (source == null) return;
    Navigator.of(context).pop(
      ScreenShareRequest(source, shareSystemAudio: _shareSystemAudio),
    );
  }

  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    final sources = _sources.values
        .where((s) => s.type == _sourceType)
        .toList(growable: false);

    return Dialog(
      backgroundColor: colors.foreground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.screen_share_outlined,
                    size: 20,
                    color: colors.dirtyWhite,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      UiCopy.chooseWhatToShare(context: context),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: UiCopy.close(context: context),
                    onPressed: _cancel,
                    icon: Icon(Icons.close, size: 20, color: colors.gray),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: settings.screenShareResolution,
                      decoration: InputDecoration(
                        labelText: UiCopy.screenShareResolution(
                          context: context,
                        ),
                      ),
                      items: [
                        for (final i in [3, 0, 1, 2])
                          DropdownMenuItem(
                            value: i,
                            child: Text(
                              AccordSettings.screenShareResolutionLabels[i],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          controller.setScreenShareResolution(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: settings.screenShareFps,
                      decoration: InputDecoration(
                        labelText: UiCopy.screenShareFrameRate(
                          context: context,
                        ),
                      ),
                      items: [
                        for (final fps in AccordSettings.screenShareFpsOptions)
                          DropdownMenuItem(
                            value: fps,
                            child: Text(
                              UiCopy.fps(context: context, arg0: fps),
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) controller.setScreenShareFps(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              tabs: [
                Tab(text: UiCopy.entireScreen(context: context)),
                Tab(text: UiCopy.window(context: context)),
              ],
            ),
            Flexible(
              child: sources.isEmpty
                  ? Center(
                      child: Text(
                        UiCopy.noSourcesAvailable(context: context),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.gray,
                        ),
                      ),
                    )
                  : GridView.count(
                      padding: const EdgeInsets.all(16),
                      crossAxisCount: _sourceType == rtc.SourceType.Screen
                          ? 2
                          : 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        for (final source in sources)
                          _SourceTile(
                            source: source,
                            selected: _selectedSource?.id == source.id,
                            colors: colors,
                            onTap: () =>
                                setState(() => _selectedSource = source),
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 16),
              child: Row(
                children: [
                  if (UniversalPlatform.isWindows)
                    InkWell(
                      onTap: () => setState(
                        () => _shareSystemAudio = !_shareSystemAudio,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _shareSystemAudio,
                            onChanged: (value) => setState(
                              () => _shareSystemAudio = value ?? false,
                            ),
                          ),
                          Text(
                            AppStrings.choose(
                              'Also share system audio',
                              '同时共享系统音频',
                              context: context,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _cancel,
                    child: Text(UiCopy.cancel(context: context)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _selectedSource == null ? null : _confirm,
                    child: Text(UiCopy.share(context: context)),
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

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.source,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final rtc.DesktopCapturerSource source;
  final bool selected;
  final BonfireThemeExtension colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnail = source.thumbnail;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            width: 2,
            color: selected ? colors.primary : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: thumbnail != null && thumbnail.isNotEmpty
                  ? Image.memory(
                      thumbnail,
                      gaplessPlayback: true,
                      fit: BoxFit.contain,
                    )
                  : const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              source.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
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
