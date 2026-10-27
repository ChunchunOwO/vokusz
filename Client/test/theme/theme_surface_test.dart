import 'dart:math' as math;

import 'package:bonfire/features/authentication/views/auth_form.dart';
import 'package:bonfire/theme/app_theme.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the shared surface language [buildAppTheme] hands every screen:
/// corners on the [AppRadius] scale, a solid accent for the primary action
/// with a label that stays readable on it, and neutral large surfaces.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('shared theme surfaces', () {
    for (final preset in AppThemePreset.values) {
      test('${preset.label} corners follow the radius scale', () {
        final theme = buildAppTheme(preset);
        for (final shape in [
          theme.cardTheme.shape,
          theme.dialogTheme.shape,
          theme.popupMenuTheme.shape,
          theme.snackBarTheme.shape,
          theme.chipTheme.shape,
          theme.floatingActionButtonTheme.shape,
          _resolvedShape(theme.elevatedButtonTheme.style),
          _resolvedShape(theme.filledButtonTheme.style),
          _resolvedShape(theme.outlinedButtonTheme.style),
          _resolvedShape(theme.textButtonTheme.style),
        ]) {
          _expectOnScale(shape);
        }
        final input = theme.inputDecorationTheme.enabledBorder;
        expect(input, isA<OutlineInputBorder>());
        _expectRadiusOnScale(
          (input! as OutlineInputBorder).borderRadius.resolve(TextDirection.ltr),
        );
      });

      test('${preset.label} primary buttons fill with a readable accent', () {
        final theme = buildAppTheme(preset);
        final palette = paletteFor(preset);
        for (final style in [
          theme.elevatedButtonTheme.style,
          theme.filledButtonTheme.style,
        ]) {
          final bg = style?.backgroundColor?.resolve(const <WidgetState>{});
          final fg = style?.foregroundColor?.resolve(const <WidgetState>{});
          expect(bg, palette.primary);
          expect(fg, isNotNull);
          final ratio = _contrastRatio(fg!, bg!);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '${preset.label} button label is ${ratio.toStringAsFixed(2)}:1 '
                'on its accent',
          );
        }
        // The secondary action stays transparent so only one button per
        // group reads as primary.
        final outlined = theme.outlinedButtonTheme.style?.backgroundColor
            ?.resolve(const <WidgetState>{});
        expect(outlined, Colors.transparent);
      });

      test('${preset.label} navigation canvas keeps body text readable', () {
        final palette = paletteFor(preset);
        for (final (name, token) in [
          ('dirtyWhite', palette.dirtyWhite),
          ('gray', palette.gray),
        ]) {
          final ratio = _contrastRatio(token, palette.canvas);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '${preset.label}: $name on canvas is '
                '${ratio.toStringAsFixed(2)}:1',
          );
        }
      });
    }
  });

  testWidgets('auth toggle and chips stay neutral surfaces', (tester) async {
    final theme = buildAppTheme(AppThemePreset.dark);
    final palette = paletteFor(AppThemePreset.dark);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('zh'),
        supportedLocales: const [Locale('zh'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Column(
            children: [
              AuthModeToggle(mode: AuthMode.signIn, onModeChanged: (_) {}),
              ChoiceChip(
                label: const Text('中文'),
                selected: true,
                onSelected: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    _expectNoLargeSaturatedFill(tester);

    // The chosen mode is the raised segment: the sheet colour, never the
    // accent, with rounded corners on the scale.
    final selected = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(AuthModeToggle),
        matching: find.byWidgetPredicate((widget) {
          if (widget is! AnimatedContainer) return false;
          final decoration = widget.decoration;
          return decoration is BoxDecoration &&
              decoration.color == palette.sheet;
        }),
      ),
    );
    final decoration = selected.decoration! as BoxDecoration;
    expect(decoration.color, isNot(palette.primary));
    final radius = decoration.borderRadius! as BorderRadius;
    expect(radius.topLeft.x, inInclusiveRange(AppRadius.sm, AppRadius.xl));
  });
}

ShapeBorder? _resolvedShape(ButtonStyle? style) =>
    style?.shape?.resolve(const <WidgetState>{});

void _expectOnScale(ShapeBorder? shape) {
  expect(shape, isNotNull);
  expect(shape, isNot(isA<StadiumBorder>()));
  expect(shape, isNot(isA<CircleBorder>()));
  if (shape is RoundedRectangleBorder) {
    _expectRadiusOnScale(shape.borderRadius.resolve(TextDirection.ltr));
    return;
  }
  fail('surface uses ${shape.runtimeType}, not a rounded rectangle');
}

void _expectRadiusOnScale(BorderRadius radius) {
  for (final corner in [
    radius.topLeft,
    radius.topRight,
    radius.bottomLeft,
    radius.bottomRight,
  ]) {
    expect(
      math.max(corner.x, corner.y),
      inInclusiveRange(AppRadius.sm, AppRadius.xl),
    );
  }
}

double _chroma(Color color) {
  final high = math.max(color.r, math.max(color.g, color.b));
  final low = math.min(color.r, math.min(color.g, color.b));
  return high - low;
}

/// WCAG 2.1 relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

double _contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void _expectNoLargeSaturatedFill(WidgetTester tester) {
  final candidates = [
    ...find.byType(DecoratedBox).evaluate(),
    ...find.byType(Material).evaluate(),
  ];
  for (final element in candidates) {
    final render = element.renderObject;
    if (render is! RenderBox || !render.hasSize) continue;
    final size = render.size;
    if (size.width < 72 || size.height < 28) continue;
    final color = switch (element.widget) {
      DecoratedBox(decoration: BoxDecoration(:final Color color)) => color,
      Material(:final color) => color,
      _ => null,
    };
    if (color == null || color.a < 0.85) continue;
    expect(
      _chroma(color),
      lessThan(0.28),
      reason:
          'large surface ${element.widget.runtimeType} '
          '${size.width.toStringAsFixed(0)}x${size.height.toStringAsFixed(0)} '
          'is a saturated fill ($color)',
    );
  }
}
