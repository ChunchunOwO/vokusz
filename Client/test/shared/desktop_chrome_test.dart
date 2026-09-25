import 'package:bonfire/shared/components/desktop_window_bar.dart';
import 'package:bonfire/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:bonfire/shared/utils/desktop_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'title has no debug underline and shimmer respects reduced motion',
    (tester) async {
      Widget host(bool reducedMotion) => MaterialApp(
        theme: buildAppTheme(AppThemePreset.dark),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reducedMotion),
          child: const Align(
            alignment: Alignment.topCenter,
            child: DesktopWindowBar(),
          ),
        ),
        home: const SizedBox(),
      );
      await tester.pumpWidget(host(false));
      final title = tester.widget<Text>(find.text('Vokusz'));
      expect(title.style!.decoration, TextDecoration.none);
      expect(
        DefaultTextStyle.of(
          tester.element(find.text('Vokusz')),
        ).style.decoration,
        isNot(TextDecoration.underline),
      );
      final initial = tester.widget<ShaderMask>(find.byType(ShaderMask));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        identical(initial, tester.widget<ShaderMask>(find.byType(ShaderMask))),
        isFalse,
      );
      await tester.pumpWidget(host(true));
      await tester.pumpAndSettle();
      final stopped = tester.widget<ShaderMask>(find.byType(ShaderMask));
      await tester.pump(const Duration(seconds: 1));
      expect(
        identical(stopped, tester.widget<ShaderMask>(find.byType(ShaderMask))),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('frameless chrome stays off when the host is web', () {
    expect(
      desktopChromeEnabled(
        web: true,
        windows: true,
        linux: false,
        macos: false,
      ),
      isFalse,
    );
    expect(
      desktopChromeEnabled(
        web: true,
        windows: false,
        linux: true,
        macos: false,
      ),
      isFalse,
    );
    expect(
      desktopChromeEnabled(
        web: false,
        windows: true,
        linux: false,
        macos: false,
      ),
      isTrue,
    );
  });
}
