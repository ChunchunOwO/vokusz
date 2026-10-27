import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';

/// A raised section card: the sheet colour with a hairline edge and rounded
/// corners, used to group a page's settings sections on the canvas.
///
/// It is a [Material] rather than a coloured box, so list tiles and ink wells
/// inside it paint their hover and splash effects on the card.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    // Falls back to the base theme where the app palette isn't installed
    // (embedded panels, tests), rather than failing to build.
    final theme = Theme.of(context);
    final colors = theme.extension<BonfireThemeExtension>();
    return Material(
      color: colors?.sheet ?? theme.cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colors?.hairline ?? theme.dividerColor),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Splits [children] at every [Divider] and wraps each run in a [SurfaceCard],
/// spaced [gap] apart — turning a divider-separated settings list into a
/// stack of cards without touching the sections themselves.
List<Widget> surfaceCardsFromSections(
  List<Widget> children, {
  double gap = 12,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 8),
}) {
  final groups = <List<Widget>>[[]];
  for (final child in children) {
    if (child is Divider) {
      if (groups.last.isNotEmpty) groups.add([]);
    } else {
      groups.last.add(child);
    }
  }
  final cards = <Widget>[];
  for (final group in groups) {
    if (group.isEmpty) continue;
    if (cards.isNotEmpty) cards.add(SizedBox(height: gap));
    cards.add(
      SurfaceCard(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: group,
        ),
      ),
    );
  }
  return cards;
}
