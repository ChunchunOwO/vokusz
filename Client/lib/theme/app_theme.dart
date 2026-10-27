import 'package:bonfire/theme/theme.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Selectable colour themes for the Accord client. Each preset maps to a
/// [BonfireThemeExtension] palette + a [Brightness]; the user may additionally
/// override the accent (primary) colour via settings.
enum AppThemePreset {
  dark('Dark'),
  midnight('Midnight'),
  light('Light'),
  nord('Nord'),
  monokai('Monokai'),
  solarized('Solarized');

  const AppThemePreset(this.label);

  final String label;

  static AppThemePreset fromName(String? name) => AppThemePreset.values
      .firstWhere((p) => p.name == name, orElse: () => AppThemePreset.dark);
}

/// The fixed palette for a preset, before any user accent override is applied.
///
/// Colours are ported from the reference vokusz client's ThemeManager presets,
/// mapping its tokens onto this client's 9-colour palette:
/// background←nav_bg, foreground←panel_bg, darkGray←input_bg,
/// dirtyWhite←text_body, gray←text_muted, primary←accent, red←error,
/// green←success, yellow←warning.
const Map<AppThemePreset, BonfireThemeExtension> _palettes = {
  AppThemePreset.dark: BonfireThemeExtension(
    background: Color(0xFF27292C),
    foreground: Color(0xFF2C2E34),
    dirtyWhite: Color(0xFFD5D9DF),
    gray: Color(0xFF939BA3),
    darkGray: Color(0xFF1E1F23),
    primary: Color(0xFF5764F1),
    red: Color(0xFFEC4245),
    green: Color(0xFF43B06D),
    yellow: Color(0xFFFFD833),
  ),
  // AMOLED variant of [dark]: pure-black base, same accent/text tokens.
  AppThemePreset.midnight: BonfireThemeExtension(
    background: Color(0xFF000000),
    foreground: Color(0xFF14161A),
    dirtyWhite: Color(0xFFD5D9DF),
    gray: Color(0xFF939BA3),
    darkGray: Color(0xFF000000),
    primary: Color(0xFF5764F1),
    red: Color(0xFFEC4245),
    green: Color(0xFF43B06D),
    yellow: Color(0xFFFFD833),
  ),
  AppThemePreset.light: BonfireThemeExtension(
    background: Color(0xFFE8EAED),
    foreground: Color(0xFFF4F4F7),
    // dirtyWhite is the high-emphasis text colour throughout the app, so on a
    // light surface it has to be dark.
    dirtyWhite: Color(0xFF2D3338),
    // Darkened from #6B707A, which sat at 4.12:1 on `background` — under the
    // 4.5:1 WCAG AA floor for the body/label text this token carries.
    gray: Color(0xFF5F646E),
    darkGray: Color(0xFFE0E2E5),
    primary: Color(0xFF5764F1),
    red: Color(0xFFD82D33),
    green: Color(0xFF2D9959),
    yellow: Color(0xFFE5BF00),
  ),
  AppThemePreset.nord: BonfireThemeExtension(
    background: Color(0xFF282C38),
    foreground: Color(0xFF2D3440),
    dirtyWhite: Color(0xFFD7DEE9),
    gray: Color(0xFF9DAABB),
    darkGray: Color(0xFF212730),
    primary: Color(0xFF81A0C1),
    red: Color(0xFFBE606A),
    green: Color(0xFFA2BD8B),
    yellow: Color(0xFFEBCA8A),
  ),
  AppThemePreset.monokai: BonfireThemeExtension(
    background: Color(0xFF21211B),
    foreground: Color(0xFF282820),
    dirtyWhite: Color(0xFFF8F8F1),
    gray: Color(0xFF99998C),
    darkGray: Color(0xFF1D1D16),
    primary: Color(0xFFA2D439),
    red: Color(0xFFFA5D5D),
    green: Color(0xFFA2D439),
    yellow: Color(0xFFE6DB74),
  ),
  AppThemePreset.solarized: BonfireThemeExtension(
    background: Color(0xFF00242D),
    foreground: Color(0xFF002B36),
    // Solarized base1/base0. Was base0/base01 (#839395/#647A83), which put muted
    // text at 3.33:1 and high-emphasis at 4.70:1 — muted failed WCAG AA outright
    // and high-emphasis had no margin. Shifting both one step lighter keeps the
    // palette authentic and clears 5:1.
    dirtyWhite: Color(0xFF93A1A1),
    gray: Color(0xFF839496),
    darkGray: Color(0xFF063642),
    primary: Color(0xFF258AD2),
    red: Color(0xFFDC312E),
    green: Color(0xFF859900),
    yellow: Color(0xFFB58800),
  ),
};

/// The default accent (primary) colour for a preset — used when the user has
/// not chosen a custom accent.
Color defaultAccentFor(AppThemePreset preset) => _palettes[preset]!.primary;

Brightness _brightnessFor(AppThemePreset preset) =>
    preset == AppThemePreset.light ? Brightness.light : Brightness.dark;

/// A readable foreground (text/icon) colour for content sitting on [background].
Color _onColor(Color background) =>
    background.computeLuminance() > 0.5 ? Colors.black : Colors.white;

/// Builds the [BonfireThemeExtension] for [preset], substituting [accent] for
/// the preset's default primary when provided.
BonfireThemeExtension paletteFor(AppThemePreset preset, {Color? accent}) {
  final base = _palettes[preset]!;
  return accent == null ? base : base.copyWith(primary: accent);
}

TextTheme _textTheme(BonfireThemeExtension palette) {
  final high = palette.dirtyWhite;
  final medium = palette.gray;
  // Every slot is defined with an explicit colour. ThemeData.copyWith replaces
  // the textTheme wholesale (it does NOT merge with the base typography), so any
  // slot left undefined here — or defined without a colour — resolves to the
  // framework's near-black default and becomes unreadable on the dark surfaces
  // (e.g. the "Vokusz" welcome title, which uses headlineSmall). Metrics are
  // kept tight (no `height`) to match the original layout and avoid overflow.
  TextStyle s(
    double size,
    Color color, [
    FontWeight weight = FontWeight.w500,
  ]) => TextStyle(fontSize: size, fontWeight: weight, color: color);
  return TextTheme(
    displayLarge: s(36, high),
    displayMedium: s(20, high),
    displaySmall: s(15, high),
    titleLarge: s(36, high),
    titleMedium: s(20, high),
    titleSmall: s(15, high),
    headlineLarge: s(18, high),
    headlineMedium: s(16, high),
    headlineSmall: s(24, high),
    labelLarge: s(15, medium),
    labelMedium: s(12, medium),
    labelSmall: s(12, medium),
    bodyLarge: s(15, high),
    bodyMedium: s(14, medium),
    bodySmall: s(12, medium),
  );
}

/// Corner radius for small primary chrome (buttons, inputs, menus).
const BorderRadius kControlRadius = BorderRadius.all(
  Radius.circular(AppRadius.md),
);

RoundedRectangleBorder _rounded(double radius, {BorderSide? side}) =>
    RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      side: side ?? BorderSide.none,
    );

OutlineInputBorder _input(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: kControlRadius,
      borderSide: BorderSide(color: color, width: width),
    );

/// Text on an accent fill: whichever of black or white contrasts more.
///
/// A plain luminance > 0.5 split put white on mid-tone accents such as the
/// Nord blue (2.8:1); the crossover where both contrast equally is ~0.18.
Color _onAccent(Color accent) =>
    accent.computeLuminance() > 0.179 ? Colors.black : Colors.white;

const _buttonPadding = WidgetStatePropertyAll(
  EdgeInsets.symmetric(horizontal: 18, vertical: 12),
);
const _buttonText = WidgetStatePropertyAll(
  TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
);

WidgetStateProperty<Color?> _overlay(Color ink) =>
    WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return ink.withValues(alpha: 0.14);
      }
      if (states.contains(WidgetState.hovered)) {
        return ink.withValues(alpha: 0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return ink.withValues(alpha: 0.12);
      }
      return null;
    });

/// The primary action: a solid accent fill.
ButtonStyle _filledButton(BonfireThemeExtension palette, Color onAccent) {
  Color fg(Set<WidgetState> states) =>
      states.contains(WidgetState.disabled) ? palette.gray : onAccent;
  return ButtonStyle(
    elevation: const WidgetStatePropertyAll(0),
    shadowColor: const WidgetStatePropertyAll(Colors.transparent),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? palette.selectedFill
          : palette.primary,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(fg),
    iconColor: WidgetStateProperty.resolveWith(fg),
    overlayColor: _overlay(onAccent),
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: kControlRadius),
    ),
    padding: _buttonPadding,
    textStyle: _buttonText,
  );
}

/// The secondary action: transparent with a quiet outline.
ButtonStyle _outlinedButton(BonfireThemeExtension palette) {
  Color fg(Set<WidgetState> states) => states.contains(WidgetState.disabled)
      ? palette.gray
      : palette.dirtyWhite;
  return ButtonStyle(
    elevation: const WidgetStatePropertyAll(0),
    shadowColor: const WidgetStatePropertyAll(Colors.transparent),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
    foregroundColor: WidgetStateProperty.resolveWith(fg),
    iconColor: WidgetStateProperty.resolveWith(fg),
    overlayColor: _overlay(palette.dirtyWhite),
    side: WidgetStateProperty.resolveWith(
      (states) => BorderSide(
        color: states.contains(WidgetState.disabled)
            ? palette.hairline
            : palette.gray.withValues(alpha: 0.45),
      ),
    ),
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: kControlRadius),
    ),
    padding: _buttonPadding,
    textStyle: _buttonText,
  );
}

/// Pages fade in while rising a few pixels: quick and quiet, for a desktop
/// app where full-screen slides feel heavy. Instant under reduced motion.
class _SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SoftPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.curve,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

const _pageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _SoftPageTransitionsBuilder(),
    TargetPlatform.fuchsia: _SoftPageTransitionsBuilder(),
    TargetPlatform.linux: _SoftPageTransitionsBuilder(),
    TargetPlatform.windows: _SoftPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
  },
);

/// Builds the [ThemeData] for [preset], applying an optional custom [accent].
ThemeData buildAppTheme(AppThemePreset preset, {Color? accent}) {
  final palette = paletteFor(preset, accent: accent);
  final brightness = _brightnessFor(preset);
  final base = brightness == Brightness.light
      ? ThemeData.light()
      : ThemeData.dark();
  final onAccent = _onAccent(palette.primary);
  final filled = _filledButton(palette, onAccent);
  final hairline = BorderSide(color: palette.hairline);
  return base.copyWith(
    scaffoldBackgroundColor: palette.background,
    canvasColor: palette.background,
    cardColor: palette.sheet,
    pageTransitionsTheme: _pageTransitions,
    splashFactory: InkRipple.splashFactory,
    highlightColor: palette.primary.withValues(alpha: 0.06),
    hoverColor: palette.hoverFill,
    focusColor: palette.primary.withValues(alpha: 0.12),
    // Selection, caret and handles carry the accent rather than Material blue.
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.primary,
      selectionColor: palette.primary.withValues(alpha: 0.32),
      selectionHandleColor: palette.primary,
    ),
    tooltipTheme: TooltipThemeData(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.sheet,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
        border: Border.fromBorderSide(hairline),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: TextStyle(
        color: palette.dirtyWhite,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    // Thin, quiet scrollbars that firm up under the pointer.
    scrollbarTheme: ScrollbarThemeData(
      radius: const Radius.circular(AppRadius.xs),
      crossAxisMargin: 2,
      thickness: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.dragged)
            ? 8
            : 5,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => palette.gray.withValues(
          alpha: states.contains(WidgetState.dragged)
              ? 0.6
              : states.contains(WidgetState.hovered)
              ? 0.45
              : 0.28,
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.xs)),
      ),
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? palette.primary
              : palette.gray,
          width: 1.5,
        ),
      ),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.primary
            : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(onAccent),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.primary
            : palette.gray,
      ),
    ),
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: palette.primary,
          brightness: brightness,
        ).copyWith(
          primary: palette.primary,
          // fromSeed derives onPrimary for its generated primary tone, not the
          // accent we force above — so pick the on-colour by contrast.
          onPrimary: onAccent,
          error: palette.red,
          onError: _onColor(palette.red),
          surface: palette.background,
          surfaceContainerHighest: palette.sheet,
        ),
    textTheme: _textTheme(palette),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: palette.background,
      foregroundColor: palette.dirtyWhite,
      surfaceTintColor: Colors.transparent,
      // Titles otherwise inherit titleLarge (36), sized for hero headings.
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: palette.dirtyWhite,
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.sheet,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: _rounded(AppRadius.lg, side: hairline),
    ),
    // Floating surfaces lift off the page with a soft shadow rather than a
    // hard outline.
    dialogTheme: DialogThemeData(
      backgroundColor: palette.sheet,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      shadowColor: palette.shadow,
      shape: _rounded(AppRadius.xl, side: hairline),
      // Dialog titles otherwise inherit headlineSmall (24): heavier than any
      // heading in the panes they open over.
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: palette.dirtyWhite,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.sheet,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.sheet,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shadowColor: palette.shadow,
      shape: _rounded(AppRadius.md + 2, side: hairline),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.sheet,
      elevation: 8,
      behavior: SnackBarBehavior.floating,
      shape: _rounded(AppRadius.md + 2, side: hairline),
      contentTextStyle: TextStyle(color: palette.dirtyWhite),
    ),
    dividerTheme: DividerThemeData(
      color: palette.hairline,
      thickness: 1,
      space: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: filled),
    filledButtonTheme: FilledButtonThemeData(style: filled),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _outlinedButton(palette),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? palette.gray
              : palette.dirtyWhite,
        ),
        overlayColor: _overlay(palette.dirtyWhite),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: kControlRadius),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(palette.dirtyWhite),
        overlayColor: _overlay(palette.dirtyWhite),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: kControlRadius),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      backgroundColor: palette.primary,
      foregroundColor: onAccent,
      shape: _rounded(AppRadius.lg),
    ),
    chipTheme: ChipThemeData(
      elevation: 0,
      pressElevation: 0,
      showCheckmark: false,
      backgroundColor: Colors.transparent,
      selectedColor: palette.accentSoft,
      disabledColor: palette.hoverFill,
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? palette.primary.withValues(alpha: 0.7)
              : palette.gray.withValues(alpha: 0.35),
        ),
      ),
      shape: _rounded(AppRadius.md),
      labelStyle: TextStyle(color: palette.dirtyWhite, fontSize: 13),
      secondaryLabelStyle: TextStyle(color: palette.dirtyWhite, fontSize: 13),
      brightness: brightness,
    ),
    // Fields are recessed wells: a hairline at rest, the accent on focus.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.inset,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: TextStyle(color: palette.gray),
      hintStyle: TextStyle(color: palette.gray),
      border: _input(palette.hairline),
      enabledBorder: _input(palette.hairline),
      disabledBorder: _input(Colors.transparent),
      focusedBorder: _input(palette.primary, width: 1.5),
      errorBorder: _input(palette.red),
      focusedErrorBorder: _input(palette.red, width: 1.5),
    ),
    listTileTheme: ListTileThemeData(
      selectedTileColor: palette.selectedFill,
      selectedColor: palette.emphasis,
      shape: _rounded(AppRadius.md),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.background,
      indicatorColor: palette.accentSoft,
      selectedIconTheme: IconThemeData(color: palette.primary),
      unselectedIconTheme: IconThemeData(color: palette.dirtyWhite),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: palette.hairline,
      labelColor: palette.emphasis,
      unselectedLabelColor: palette.gray,
      indicator: UnderlineTabIndicator(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
        borderSide: BorderSide(color: palette.primary, width: 2.5),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.primary,
      linearTrackColor: palette.inset,
      circularTrackColor: palette.inset,
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      activeTrackColor: palette.primary,
      inactiveTrackColor: palette.inset,
      thumbColor: palette.primary,
      overlayColor: palette.primary.withValues(alpha: 0.12),
    ),
    // A solid accent track for "on", a recessed outlined one for "off".
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? palette.gray.withValues(alpha: 0.5)
            : states.contains(WidgetState.selected)
            ? onAccent
            : palette.gray,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.primary
            : palette.inset,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : palette.gray.withValues(alpha: 0.5),
      ),
    ),
    extensions: [palette],
  );
}

/// The pre-redesign control styling, applied only around the compact voice
/// window so that mode keeps its look while the rest of the app moves on.
ThemeData compactWindowTheme(ThemeData theme) {
  final palette = theme.extension<BonfireThemeExtension>()!;
  final defaults = theme.brightness == Brightness.light
      ? ThemeData.light()
      : ThemeData.dark();
  return theme.copyWith(
    hoverColor: defaults.hoverColor,
    focusColor: defaults.focusColor,
    tooltipTheme: const TooltipThemeData(),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: palette.dirtyWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xs)),
        ),
      ),
    ),
  );
}
