import 'package:bonfire/theme/theme.dart';
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

/// Corner radius for primary chrome. Larger radii read as pills; the shell
/// stays at a hairline 4.
const BorderRadius kFlatRadius = BorderRadius.all(Radius.circular(4));

RoundedRectangleBorder _flatRect({BorderSide side = BorderSide.none}) =>
    RoundedRectangleBorder(borderRadius: kFlatRadius, side: side);

OutlineInputBorder _flatInput(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: kFlatRadius,
      borderSide: BorderSide(color: color, width: width),
    );

/// Outline control: the surface colour, a 1px edge, no filled accent block.
ButtonStyle _flatButton(BonfireThemeExtension palette) {
  return ButtonStyle(
    elevation: const WidgetStatePropertyAll(0),
    shadowColor: const WidgetStatePropertyAll(Colors.transparent),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    backgroundColor: WidgetStatePropertyAll(palette.background),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? palette.gray
          : palette.dirtyWhite,
    ),
    iconColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? palette.gray
          : palette.dirtyWhite,
    ),
    side: WidgetStateProperty.resolveWith(
      (states) => BorderSide(
        color: states.contains(WidgetState.disabled)
            ? palette.darkGray
            : palette.primary,
      ),
    ),
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: kFlatRadius),
    ),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}

/// Builds the [ThemeData] for [preset], applying an optional custom [accent].
ThemeData buildAppTheme(AppThemePreset preset, {Color? accent}) {
  final palette = paletteFor(preset, accent: accent);
  final brightness = _brightnessFor(preset);
  final base = brightness == Brightness.light
      ? ThemeData.light()
      : ThemeData.dark();
  final button = _flatButton(palette);
  return base.copyWith(
    scaffoldBackgroundColor: palette.background,
    canvasColor: palette.background,
    cardColor: palette.foreground,
    splashFactory: InkRipple.splashFactory,
    highlightColor: palette.primary.withValues(alpha: 0.06),
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: palette.primary,
          brightness: brightness,
        ).copyWith(
          primary: palette.primary,
          // fromSeed derives onPrimary for its generated primary tone, not the
          // accent we force above — so a light accent (e.g. Nord, or a custom one)
          // would otherwise get light text. Pick the on-colour by luminance.
          onPrimary: _onColor(palette.primary),
          error: palette.red,
          onError: _onColor(palette.red),
          surface: palette.background,
          surfaceContainerHighest: palette.foreground,
        ),
    textTheme: _textTheme(palette),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: palette.background,
      foregroundColor: palette.dirtyWhite,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: palette.foreground,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: _flatRect(side: BorderSide(color: palette.darkGray)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.foreground,
      elevation: 0,
      shape: _flatRect(side: BorderSide(color: palette.darkGray)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.foreground,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.foreground,
      elevation: 0,
      shape: _flatRect(side: BorderSide(color: palette.darkGray)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.foreground,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      shape: _flatRect(side: BorderSide(color: palette.darkGray)),
      contentTextStyle: TextStyle(color: palette.dirtyWhite),
    ),
    dividerTheme: DividerThemeData(
      color: palette.darkGray,
      thickness: 1,
      space: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: button),
    filledButtonTheme: FilledButtonThemeData(style: button),
    outlinedButtonTheme: OutlinedButtonThemeData(style: button),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.dirtyWhite,
        shape: const RoundedRectangleBorder(borderRadius: kFlatRadius),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: palette.dirtyWhite,
        shape: const RoundedRectangleBorder(borderRadius: kFlatRadius),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      backgroundColor: palette.background,
      foregroundColor: palette.dirtyWhite,
      shape: _flatRect(side: BorderSide(color: palette.primary)),
    ),
    chipTheme: ChipThemeData(
      elevation: 0,
      pressElevation: 0,
      showCheckmark: false,
      backgroundColor: palette.background,
      selectedColor: palette.foreground,
      disabledColor: palette.darkGray,
      side: BorderSide(color: palette.darkGray),
      shape: const RoundedRectangleBorder(borderRadius: kFlatRadius),
      labelStyle: TextStyle(color: palette.dirtyWhite, fontSize: 13),
      secondaryLabelStyle: TextStyle(color: palette.dirtyWhite, fontSize: 13),
      brightness: brightness,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.darkGray,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      labelStyle: TextStyle(color: palette.gray),
      hintStyle: TextStyle(color: palette.gray),
      border: _flatInput(palette.darkGray),
      enabledBorder: _flatInput(palette.gray.withValues(alpha: 0.45)),
      focusedBorder: _flatInput(palette.primary),
      errorBorder: _flatInput(palette.red),
      focusedErrorBorder: _flatInput(palette.red),
    ),
    listTileTheme: const ListTileThemeData(
      selectedTileColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: kFlatRadius),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.background,
      indicatorColor: Colors.transparent,
      selectedIconTheme: IconThemeData(color: palette.primary),
      unselectedIconTheme: IconThemeData(color: palette.dirtyWhite),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: palette.darkGray,
      labelColor: palette.dirtyWhite,
      unselectedLabelColor: palette.gray,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: palette.primary, width: 1),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.primary,
      linearTrackColor: palette.darkGray,
      circularTrackColor: palette.darkGray,
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 2,
      activeTrackColor: palette.primary,
      inactiveTrackColor: palette.darkGray,
      thumbColor: palette.dirtyWhite,
      overlayColor: palette.primary.withValues(alpha: 0.08),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.dirtyWhite
            : palette.gray,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.darkGray
            : palette.background,
      ),
      trackOutlineColor: WidgetStatePropertyAll(palette.gray),
    ),
    extensions: [palette],
  );
}
