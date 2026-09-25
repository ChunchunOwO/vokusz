import 'package:bonfire/features/profiles/views/profile_gate.dart';
import 'package:bonfire/features/settings/models/accord_settings.dart';
import 'package:bonfire/features/voice/views/compact_voice_mode.dart';
import 'package:bonfire/features/voice/views/compact_voice_window.dart';
import 'package:bonfire/features/voice/views/incoming_call_overlay.dart';
import 'package:bonfire/features/presence/rich_presence_host.dart';
import 'package:bonfire/features/voice/views/voice_desktop_extras.dart';
import 'package:bonfire/shared/components/desktop_window_bar.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Upper bound on the combined (system × in-app) text scale. The OS can ask
/// for far more than this at the top accessibility sizes; past roughly 2× the
/// app's fixed-height rows (channel tiles, the member list, voice tiles) start
/// clipping instead of growing, so honour the user's preference up to here and
/// no further.
const double maxEffectiveTextScale = 2.0;

/// Everything the app's `MaterialApp.router` layers between its chrome (theme,
/// localizations, media query) and the router's Navigator — [child] — via
/// `MaterialApp.builder`:
///
/// 1. the accessibility overrides (UI scale composed with the platform text
///    scale, reduced motion), so they apply to every route;
/// 2. the device-profile PIN gate, which replaces the Navigator with the lock
///    screen until the active profile is unlocked;
/// 3. the incoming-call banner host, above every route so a ring stays
///    answerable from inside a dialog or the full-screen call view (#139).
///
/// This must be the *only* Navigator ancestry the app has. `main.dart` used to
/// boot a second, bare `MaterialApp(home: ProfileGate(...))` around the router
/// app to host the gate; that bootstrap app had its own Navigator (and no
/// [BonfireThemeExtension]), so every `rootNavigator: true` lookup from inside
/// the app — `showDialog`, the DM call's `showFullScreenVoice`, the incoming
/// call's accept — climbed past the themed router into it. Dialogs survived
/// because `showDialog` captures inherited themes; the DM call view did not,
/// blanking on `BonfireThemeExtension.of`, and every dialog pushed there sat
/// *above* the ring banner host (#324). Hosting the gate here keeps go_router's
/// navigator as the root.
Widget buildAppShell(
  BuildContext context,
  Widget? child, {
  required double uiScale,
  required bool reducedMotion,
}) {
  // Compose the in-app UI scale with the platform's own text scale (iOS
  // Dynamic Type, Android font size) instead of replacing it. Passing
  // `TextScaler.linear(uiScale)` straight through discarded whatever the
  // user had set at the OS level, so iOS "Larger Text" did nothing here —
  // the app always rendered at its own scale. Capped at
  // [maxEffectiveTextScale] so the largest accessibility sizes can't burst
  // fixed-height rows.
  final systemScale = MediaQuery.textScalerOf(context).scale(1);
  final combined = (systemScale * uiScale).clamp(
    AccordSettings.minUiScale,
    maxEffectiveTextScale,
  );
  final frame = MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(combined),
      disableAnimations: reducedMotion,
    ),
    // The gate wraps the banner host too: a locked profile shows neither the
    // app nor who is calling it.
    child: ProfileGate(child: withIncomingCallOverlay(child)),
  );
  if (!DesktopWindowBar.enabled) return frame;
  return ListenableBuilder(
    listenable: CompactVoiceMode.instance,
    builder: (context, _) {
      if (CompactVoiceMode.instance.active) {
        final colors = BonfireThemeExtension.of(context);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
            disableAnimations:
                reducedMotion || MediaQuery.disableAnimationsOf(context),
          ),
          // The native window lets unpainted pixels show the desktop. This
          // clip is what makes those four corners round.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              CompactVoiceMode.cornerRadius,
            ),
            clipBehavior: Clip.antiAlias,
            child: ColoredBox(
              color: colors.background,
              child: const Column(
                children: [
                  VoiceDesktopExtras(),
                  RichPresenceHost(),
                  Expanded(child: CompactVoiceWindow()),
                ],
              ),
            ),
          ),
        );
      }
      return DragToResizeArea(
        resizeEdgeColor: Colors.transparent,
        resizeEdgeSize: 6,
        child: Column(
          children: [
            const VoiceDesktopExtras(),
            const RichPresenceHost(),
            MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations:
                    reducedMotion || MediaQuery.disableAnimationsOf(context),
              ),
              child: const DesktopWindowBar(),
            ),
            Expanded(child: frame),
          ],
        ),
      );
    },
  );
}
