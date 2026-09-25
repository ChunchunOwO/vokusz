import 'dart:async';

import 'package:bonfire/features/voice/views/compact_voice_mode.dart';
import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/shared/utils/desktop_window.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Desktop window chrome that is the same surface as the app, with no
/// application icon and no system title bar.
class DesktopWindowBar extends StatelessWidget {
  const DesktopWindowBar({super.key});

  static bool get enabled => desktopChromeEnabled();

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    final colors = BonfireThemeExtension.of(context);
    return Material(
      color: colors.background,
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () async {
                  if (await windowManager.isMaximized()) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
                child: DragToMoveArea(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: const VokuszShimmerTitle(),
                    ),
                  ),
                ),
              ),
            ),
            _WindowButton(
              icon: Icons.picture_in_picture_alt_outlined,
              tooltip: AppStrings.choose(
                'Compact mode',
                '极简模式',
                context: context,
              ),
              onPressed: () {
                unawaited(CompactVoiceMode.instance.enter());
              },
            ),
            _WindowButton(
              icon: Icons.remove,
              onPressed: windowManager.minimize,
            ),
            _WindowButton(
              icon: Icons.crop_square,
              onPressed: () async {
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
            ),
            _WindowButton(
              icon: Icons.close,
              hoverColor: colors.red,
              onPressed: windowManager.close,
            ),
          ],
        ),
      ),
    );
  }
}

/// The light “Vokusz” wordmark with a slow highlight moving across it.
class VokuszShimmerTitle extends StatefulWidget {
  const VokuszShimmerTitle({super.key, this.fontSize = 13});

  final double fontSize;

  @override
  State<VokuszShimmerTitle> createState() => _VokuszShimmerTitleState();
}

class _VokuszShimmerTitleState extends State<VokuszShimmerTitle> {
  /// One pass of the highlight. Independent of how often we redraw.
  static const _cycle = Duration(seconds: 4);

  /// Decorative only. A vsync ticker was repainting the title on every
  /// screen refresh and kept the GPU busy whenever the window was focused.
  static const _frame = Duration(milliseconds: 100);

  Timer? _timer;
  double _t = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (!animate) {
      _timer?.cancel();
      _timer = null;
      if (_t != 0) setState(() => _t = 0);
      return;
    }
    _timer ??= Timer.periodic(_frame, (_) {
      if (!mounted) return;
      setState(() {
        _t = (_t + _frame.inMilliseconds / _cycle.inMilliseconds) % 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final phase = _t;
    return RepaintBoundary(
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) => LinearGradient(
          colors: [
            colors.dirtyWhite.withValues(alpha: 0.55),
            colors.dirtyWhite,
            colors.primary,
            colors.dirtyWhite.withValues(alpha: 0.55),
          ],
          stops: const [0, 0.4, 0.6, 1],
        ).createShader(
          Rect.fromLTWH(
            rect.left + (3 * phase - 1) * rect.width,
            rect.top,
            rect.width,
            rect.height,
          ),
        ),
        child: Text(
          'Vokusz',
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: Colors.white,
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _WindowButton extends StatelessWidget {
  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.hoverColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? hoverColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final button = SizedBox(
      width: 46,
      height: 32,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          hoverColor: hoverColor ?? colors.foreground,
          child: Icon(icon, size: 16, color: colors.gray),
        ),
      ),
    );
    final tip = tooltip;
    if (tip == null) return button;
    // The bar sits above the navigator, so a Tooltip has no Overlay.
    return Semantics(button: true, label: tip, child: button);
  }
}
