import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';

/// Shows and hides [child] by animating how much of it is visible along
/// [axis], fading it at the same time.
///
/// The child keeps its natural size throughout and is clipped, so it never
/// re-lays out mid-animation — only the space it takes up changes. It is
/// built only while at least partly open, so a closed section stops building
/// (and watching providers) once the animation has finished. Honours the
/// platform's and the app's reduced-motion setting.
class AnimatedReveal extends StatefulWidget {
  const AnimatedReveal({
    super.key,
    required this.open,
    required this.child,
    this.axis = Axis.vertical,
    this.duration = AppMotion.medium,
  });

  final bool open;
  final Widget child;
  final Axis axis;
  final Duration duration;

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.open ? 1 : 0,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.curve,
    reverseCurve: AppMotion.curve.flipped,
  );

  @override
  void didUpdateWidget(AnimatedReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open == widget.open) return;
    _controller.duration = AppMotion.of(context, widget.duration);
    widget.open ? _controller.forward() : _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.axis == Axis.horizontal;
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        if (t == 0) return const SizedBox.shrink();
        // One structure at every open value, so the child's element (and its
        // state, such as a scroll position) survives the animation.
        return ClipRect(
          child: Align(
            alignment: horizontal ? Alignment.centerLeft : Alignment.topCenter,
            widthFactor: horizontal ? t : null,
            heightFactor: horizontal ? null : t,
            child: Opacity(opacity: t, child: child),
          ),
        );
      },
    );
  }
}
