import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';

/// Centered progress spinner shown while a screen, list or dialog loads.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Inline error text rendered in the theme's red at `bodySmall` (the size used
/// by every error arm in the app).
///
/// Pass [centered] (the default) for the full-region case — equivalent to
/// wrapping the text in a [Center] — or `centered: false` to drop it inline in
/// a column.
class InlineError extends StatelessWidget {
  const InlineError(this.message, {super.key, this.centered = true});

  final String message;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    final text = Text(
      message,
      textAlign: centered ? TextAlign.center : null,
      style: theme.textTheme.bodySmall?.copyWith(color: colors.red),
    );
    return centered ? Center(child: text) : text;
  }
}

/// What a list or pane shows when there is nothing in it yet: a soft icon
/// badge over a short message, fading in so an empty result doesn't pop.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.of(context, AppMotion.medium),
        curve: AppMotion.curve,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 6 * (1 - t)),
            child: child,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.hoverFill,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 24, color: colors.gray),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: colors.gray),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
