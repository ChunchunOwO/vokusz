import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/l10n/ui_copy.dart';
import 'package:bonfire/shared/components/self_hosting_dialog.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';

/// Width at or above which the welcome screen lays its value props out
/// three-up. Below it they are dropped entirely so a phone keeps the
/// "Browse Servers" button above the fold.
const double kWelcomeWideBreakpoint = 620;

/// What the app actually does, in the order a newcomer cares about. Kept as
/// data (and public) so a test can assert the pitch stays on screen without
/// matching prose in the widget tree.
@immutable
class WelcomeHighlight {
  const WelcomeHighlight({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

/// Every claim here is a shipped feature — see the feature list in `README.md`.
const List<WelcomeHighlight> kWelcomeHighlights = <WelcomeHighlight>[
  WelcomeHighlight(
    icon: Icons.forum_outlined,
    title: 'Messaging',
    body:
        'Channels, threads, replies, reactions, custom emoji, file sharing and '
        'search — plus direct messages.',
  ),
  WelcomeHighlight(
    icon: Icons.headset_mic_outlined,
    title: 'Voice & screen share',
    body:
        'Crystal-clear, stable voice — and screen sharing that stays free. No '
        'paywall on the call.',
  ),
  WelcomeHighlight(
    icon: Icons.dns_outlined,
    title: 'Your server',
    body:
        'Connect to as many Accord servers as you like, or run your own. No '
        'ads, no tracking, no paywalls.',
  ),
];

/// First-run / signed-out landing screen: vokusz branding, a short pitch, what
/// the app does, and the two ways in — browse the public directory, or run a
/// server of your own. The Flutter port of the reference client's
/// `welcome_screen`.
///
/// The pitch breathes into a tablet/desktop canvas (three-up highlights above
/// [kWelcomeWideBreakpoint]) and stays compact on a phone, where the primary
/// button has to stay above the fold.
///
/// [onBrowse] opens the server browser (the default next step); [onManualConnect]
/// jumps straight to the connect-by-URL credentials form.
class WelcomeView extends StatelessWidget {
  const WelcomeView({
    super.key,
    required this.onBrowse,
    required this.onManualConnect,
  });

  final VoidCallback onBrowse;
  final VoidCallback onManualConnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kWelcomeWideBreakpoint;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A wordmark rather than a heading: tight, heavy, and underscored by
            // a short accent rule — the same signal line the app chrome uses.
            Text(
              'Vokusz',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: wide ? 40 : 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              UiCopy.freeScreenSharingSmoothStableVoiceOn(context: context),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: colors.gray),
            ),
            // Wide only, deliberately: on a phone the primary button has to
            // stay above the fold, so the pitch breathes into a tablet or
            // desktop canvas rather than bloating a 320pt one.
            if (wide) ...[
              const SizedBox(height: 28),
              const _Highlights(),
              const SizedBox(height: 28),
            ] else
              const SizedBox(height: 24),
            if (wide)
              Row(
                children: [
                  Expanded(child: _browseButton(theme, colors)),
                  const SizedBox(width: 12),
                  Expanded(child: _selfHostButton(context, theme, colors)),
                ],
              )
            else
              _browseButton(theme, colors),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onManualConnect,
              child: Text(
                UiCopy.connectDirectlyToAServer(context: context),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            // Narrow: the self-hosting CTA keeps its full button weight but
            // sits last, so adding it can't push "Browse Servers" or the
            // connect-by-URL link below the fold on a small phone.
            if (!wide) ...[
              const SizedBox(height: 4),
              _selfHostButton(context, theme, colors),
            ],
          ],
        );
      },
    );
  }

  Widget _browseButton(ThemeData theme, BonfireThemeExtension colors) =>
      SizedBox(
        height: 50,
        child: ElevatedButton.icon(
          onPressed: onBrowse,
          icon: const Icon(Icons.explore_outlined, size: 20),
          label: Text(UiCopy.browseServers()),
          // The default next step: the theme's solid accent action.
          style: ElevatedButton.styleFrom(
            textStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ),
      );

  Widget _selfHostButton(
    BuildContext context,
    ThemeData theme,
    BonfireThemeExtension colors,
  ) => SizedBox(
    height: 50,
    child: OutlinedButton.icon(
      onPressed: () =>
          showSelfHostingDialog(context, onConnect: onManualConnect),
      icon: const Icon(Icons.home_work_outlined, size: 20),
      label: Text(UiCopy.runYourOwnServer(context: context)),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.dirtyWhite,
        textStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    ),
  );
}

class _Highlights extends StatelessWidget {
  const _Highlights();

  @override
  Widget build(BuildContext context) {
    // [IntrinsicHeight] so the three cards share the tallest one's height —
    // ragged card bottoms are exactly the "unfinished" look this is fixing.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final highlight in kWelcomeHighlights) ...[
            if (highlight != kWelcomeHighlights.first)
              const SizedBox(width: 12),
            Expanded(child: _HighlightCard(highlight: highlight)),
          ],
        ],
      ),
    );
  }
}

/// Tablet/desktop: a card per value prop, three across.
class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.highlight});

  final WelcomeHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: colors.sheet,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The icon sits in a soft accent tile.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(highlight.icon, size: 20, color: colors.primary),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.label(highlight.title, context: context),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.label(highlight.body, context: context),
            style: theme.textTheme.bodySmall?.copyWith(color: colors.gray),
          ),
        ],
      ),
    );
  }
}
