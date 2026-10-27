import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';

/// A list row's leading icon set in a soft tinted tile, so a column of
/// settings rows reads as a scannable set of destinations. Tinted with the
/// accent by default, or [color] (e.g. the theme red for a destructive row).
class LeadingIcon extends StatelessWidget {
  const LeadingIcon(this.icon, {super.key, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? BonfireThemeExtension.of(context).primary;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: tint),
    );
  }
}
