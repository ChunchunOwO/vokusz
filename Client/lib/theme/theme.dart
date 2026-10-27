import 'package:flutter/material.dart';

/// The corner scale. Rows and small controls are [sm]; buttons, inputs and
/// menus [md]; cards, popovers and the content sheet [lg]; dialogs [xl].
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
}

/// Shared motion timings, so hover and selection states move together.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration medium = Duration(milliseconds: 200);
  static const Curve curve = Curves.easeOutCubic;

  /// [duration], or zero when the platform or the app's reduced-motion
  /// setting asks for no animation.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

@immutable
class BonfireThemeExtension extends ThemeExtension<BonfireThemeExtension> {
  static BonfireThemeExtension of(BuildContext context) =>
      Theme.of(context).extension<BonfireThemeExtension>()!;

  const BonfireThemeExtension({
    required this.foreground,
    required this.background,
    required this.dirtyWhite,
    required this.gray,
    required this.darkGray,
    required this.primary,
    required this.red,
    required this.green,
    required this.yellow,
  });

  final Color foreground;
  final Color background;
  final Color dirtyWhite;
  final Color gray;
  final Color darkGray;
  final Color primary;
  final Color red;
  final Color green;
  final Color yellow;

  /// Whether the palette is a light one (dark text on light surfaces).
  bool get isLight => background.computeLuminance() > 0.5;

  /// One step above [dirtyWhite]: the colour for text that has to stand out
  /// from ordinary body text (an unread channel, the active tab). Derived from
  /// the palette rather than hard-coded white, which vanished on Light.
  Color get emphasis => isLight
      ? Color.lerp(dirtyWhite, const Color(0xFF000000), 0.55)!
      : Color.lerp(dirtyWhite, const Color(0xFFFFFFFF), 0.75)!;

  // ── Surfaces ──────────────────────────────────────────────────────────────
  // The layout is two layers: the [canvas] the navigation sits on (server
  // rail, channel list, member list), and the raised [sheet] that holds the
  // conversation. Both derive from the preset so every theme keeps its own
  // character; the base tokens above stay untouched for older surfaces.

  /// The app's base layer, a step deeper than [background].
  Color get canvas => isLight
      ? Color.lerp(background, const Color(0xFF000000), 0.03)!
      : Color.lerp(background, const Color(0xFF000000), 0.18)!;

  /// The raised content surface: the chat sheet, cards, menus and dialogs.
  Color get sheet => foreground;

  /// Recessed fields sitting on a [sheet]: inputs, the composer, code blocks.
  Color get inset => darkGray;

  /// A divider or outline that reads on any surface without adding a colour.
  Color get hairline => dirtyWhite.withValues(alpha: isLight ? 0.12 : 0.08);

  /// Row fills for hover and selection, as overlays so they work on both
  /// layers.
  Color get hoverFill => dirtyWhite.withValues(alpha: isLight ? 0.06 : 0.05);
  Color get selectedFill => dirtyWhite.withValues(alpha: isLight ? 0.10 : 0.10);

  /// A quiet accent wash for selected chips, own reactions and mentions.
  Color get accentSoft => primary.withValues(alpha: isLight ? 0.14 : 0.18);

  /// Text and icons on a solid [primary] fill: whichever of black or white
  /// contrasts more (the crossover luminance is ~0.18, not 0.5).
  Color get onPrimary => primary.computeLuminance() > 0.179
      ? const Color(0xFF000000)
      : const Color(0xFFFFFFFF);

  /// Shadow colour for floating surfaces.
  Color get shadow =>
      const Color(0xFF000000).withValues(alpha: isLight ? 0.14 : 0.45);

  @override
  BonfireThemeExtension copyWith({
    Color? foreground,
    Color? background,
    Color? dirtyWhite,
    Color? gray,
    Color? darkGray,
    Color? primary,
    Color? red,
    Color? green,
    Color? yellow,
  }) {
    return BonfireThemeExtension(
      foreground: foreground ?? this.foreground,
      background: background ?? this.background,
      dirtyWhite: dirtyWhite ?? this.dirtyWhite,
      gray: gray ?? this.gray,
      darkGray: darkGray ?? this.darkGray,
      primary: primary ?? this.primary,
      red: red ?? this.red,
      green: green ?? this.green,
      yellow: yellow ?? this.yellow,
    );
  }

  @override
  BonfireThemeExtension lerp(
      covariant BonfireThemeExtension? other, double t) {
    if (other == null) return this;
    return BonfireThemeExtension(
      foreground: Color.lerp(foreground, other.foreground, t)!,
      background: Color.lerp(background, other.background, t)!,
      dirtyWhite: Color.lerp(dirtyWhite, other.dirtyWhite, t)!,
      gray: Color.lerp(gray, other.gray, t)!,
      darkGray: Color.lerp(darkGray, other.darkGray, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      red: Color.lerp(red, other.red, t)!,
      green: Color.lerp(green, other.green, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
    );
  }
}
