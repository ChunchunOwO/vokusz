import 'dart:math' as math;

import 'package:bonfire/features/authentication/views/auth_form.dart';
import 'package:bonfire/theme/app_theme.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Primary chrome inherits flat corners and tonal surfaces from [buildAppTheme].
///
/// A radius above 4, or a large control painted with a saturated fill, is the
/// regression this guards: auth, settings chips, and the default buttons.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('shared theme surfaces', () {
    for (final preset in AppThemePreset.values) {
      test('${preset.label} corners stay at 4 and buttons are not fills', () {
        final theme = buildAppTheme(preset);
        final palette = paletteFor(preset);
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
          _expectRadiusAtMost4(shape);
        }
        final input = theme.inputDecorationTheme.enabledBorder;
        expect(input, isA<OutlineInputBorder>());
        _expectBorderRadiusAtMost4(
          (input! as OutlineInputBorder).borderRadius.resolve(TextDirection.ltr),
        );

        for (final style in [
          theme.elevatedButtonTheme.style,
          theme.filledButtonTheme.style,
          theme.outlinedButtonTheme.style,
        ]) {
          final bg = style?.backgroundColor?.resolve(const <WidgetState>{});
          expect(bg, isNotNull);
          expect(
            _chroma(bg!),
            lessThan(0.32),
            reason: '${preset.label} button fill is saturated ($bg)',
          );
          expect(bg, isNot(palette.primary));
        }

        final chipFill = theme.chipTheme.selectedColor;
        expect(chipFill, isNotNull);
        expect(_chroma(chipFill!), lessThan(0.32));
      });
    }
  });

  testWidgets('auth toggle and default controls stay flat', (tester) async {
    final theme = buildAppTheme(AppThemePreset.dark);
    final primary = paletteFor(AppThemePreset.dark).primary;
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
              const SizedBox(
                width: 280,
                height: 48,
                child: ElevatedButton(onPressed: _noop, child: Text('继续')),
              ),
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
    await tester.pump();

    _expectNoLargeSaturatedFill(tester, primary);

    final selected = tester.widget<Container>(
      find.descendant(
        of: find.byType(AuthModeToggle),
        matching: find.byWidgetPredicate((widget) {
          if (widget is! Container) return false;
          final decoration = widget.decoration;
          if (decoration is! BoxDecoration) return false;
          final side = decoration.border;
          return side is Border &&
              side.top.color == primary &&
              side.top.width > 0;
        }),
      ),
    );
    final decoration = selected.decoration! as BoxDecoration;
    expect(decoration.color, isNot(primary));
    expect(_chroma(decoration.color!), lessThan(0.2));
    final radius = decoration.borderRadius! as BorderRadius;
    expect(radius.topLeft.x, lessThanOrEqualTo(4));
  });
}

void _noop() {}

ShapeBorder? _resolvedShape(ButtonStyle? style) =>
    style?.shape?.resolve(const <WidgetState>{});

void _expectRadiusAtMost4(ShapeBorder? shape) {
  expect(shape, isNotNull);
  expect(shape, isNot(isA<StadiumBorder>()));
  expect(shape, isNot(isA<CircleBorder>()));
  if (shape is RoundedRectangleBorder) {
    _expectBorderRadiusAtMost4(shape.borderRadius.resolve(TextDirection.ltr));
    return;
  }
  fail('primary surface uses ${shape.runtimeType}, which is not a 4px rect');
}

void _expectBorderRadiusAtMost4(BorderRadius radius) {
  for (final corner in [
    radius.topLeft,
    radius.topRight,
    radius.bottomLeft,
    radius.bottomRight,
  ]) {
    expect(math.max(corner.x, corner.y), lessThanOrEqualTo(4));
  }
}

double _chroma(Color color) {
  final high = math.max(color.r, math.max(color.g, color.b));
  final low = math.min(color.r, math.min(color.g, color.b));
  return high - low;
}

void _expectNoLargeSaturatedFill(WidgetTester tester, Color primary) {
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
          'is a saturated fill ($color), primary=$primary',
    );
  }
}
