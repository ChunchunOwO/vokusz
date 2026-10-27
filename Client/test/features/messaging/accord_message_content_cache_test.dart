import 'package:bonfire/features/authentication/models/accord_auth_state.dart';
import 'package:bonfire/features/authentication/repositories/accord_auth.dart';
import 'package:bonfire/features/messaging/views/box/accord_message_content.dart';
import 'package:bonfire/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_viewer/markdown_viewer.dart';

/// `MarkdownViewer` re-parses whenever its syntax-extension list is a new
/// instance. A message row rebuilds on every hover and pane rebuild, so the
/// list must survive those rebuilds or every visible message is re-parsed.
void main() {
  testWidgets('rebuilds keep the same syntax extensions', (tester) async {
    late StateSetter rebuild;
    var tick = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accordAuthProvider.overrideWithValue(const AccordAuthLoggedOut()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(AppThemePreset.dark),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return Column(
                  children: [
                    Text('$tick'),
                    // Deliberately not const: a new widget each build is
                    // what a message row hands down on hover.
                    // ignore: prefer_const_constructors
                    AccordMessageContent(content: 'hello **world**'),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    final before = tester
        .widget<MarkdownViewer>(find.byType(MarkdownViewer))
        .syntaxExtensions;
    rebuild(() => tick++);
    await tester.pump();
    final after = tester
        .widget<MarkdownViewer>(find.byType(MarkdownViewer))
        .syntaxExtensions;

    expect(find.text('1'), findsOneWidget);
    expect(identical(before, after), isTrue);
  });
}
