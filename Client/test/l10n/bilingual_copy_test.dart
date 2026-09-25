import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/l10n/ui_copy.dart';
import 'package:bonfire/features/spaces/utils/message_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppStrings.languageCode = 'en');

  test(
    'background text, permissions and timestamps follow the active language',
    () {
      AppStrings.languageCode = 'zh';
      expect(AppStrings.label('Manage Channels'), '管理频道');
      expect(UiCopy.members(arg0: 12), '12 位成员');
      expect(
        messageTimeString(
          DateTime(2026, 9, 22, 9, 30),
          now: DateTime(2026, 9, 23),
        ),
        '昨天 09:30',
      );
      expect(
        AppStrings.label('A user-defined community'),
        'A user-defined community',
      );
      AppStrings.languageCode = 'en';
      expect(UiCopy.members(arg0: 12), '12 members');
      expect(AppStrings.label('Manage Channels'), 'Manage Channels');
    },
  );

  testWidgets(
    'existing widgets update in both directions without losing state',
    (tester) async {
      final locale = ValueNotifier(const Locale('zh', 'CN'));
      addTearDown(locale.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: locale,
          builder: (_, value, child) => MaterialApp(
            locale: value,
            supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: child,
          ),
          child: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  Text(UiCopy.cancel(context: context)),
                  Text(UiCopy.members(context: context, arg0: 3)),
                  const TextField(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '未发送的草稿');
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('3 位成员'), findsOneWidget);
      locale.value = const Locale('en');
      await tester.pumpAndSettle();
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('3 members'), findsOneWidget);
      expect(find.text('未发送的草稿'), findsOneWidget);
      locale.value = const Locale('zh', 'CN');
      await tester.pumpAndSettle();
      expect(find.text('取消'), findsOneWidget);
    },
  );
}
