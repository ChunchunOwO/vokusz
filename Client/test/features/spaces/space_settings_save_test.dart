import 'dart:async';
import 'dart:convert';

import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/authentication/models/accord_auth_state.dart';
import 'package:bonfire/features/authentication/models/accord_session.dart';
import 'package:bonfire/features/authentication/repositories/accord_auth.dart';
import 'package:bonfire/features/server/models/accord_server.dart';
import 'package:bonfire/features/spaces/controllers/spaces.dart';
import 'package:bonfire/features/spaces/views/accord_space_settings.dart';
import 'package:bonfire/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
    'back saves the draft, waits for success and preserves failed edits',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var saved = <String, dynamic>{
        'id': 's1',
        'owner_id': 'u1',
        'name': 'Before',
      };
      var attempts = 0;
      var fail = false;
      Completer<void>? pending;
      final client = AccordClient(
        token: 'test',
        baseUrl: 'https://example.test',
        httpClient: MockClient((request) async {
          if (request.method == 'PATCH') {
            attempts++;
            await pending?.future;
            if (fail) {
              return http.Response(
                jsonEncode({
                  'error': {'message': 'Save unavailable'},
                }),
                500,
                headers: {'content-type': 'application/json'},
              );
            }
            saved = {
              ...saved,
              ...jsonDecode(request.body) as Map<String, dynamic>,
            };
            return http.Response(
              jsonEncode({'data': saved}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            '{"data":[]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final container = ProviderContainer(
        overrides: [
          accordAuthProvider.overrideWithValue(
            AccordAuthLoggedIn(
              client: client,
              session: AccordSession(
                server: AccordServer.fromBaseUrl('https://example.test'),
                token: 'test',
                userId: 'u1',
                username: 'Owner',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(spacesControllerProvider.notifier).setSpaces([
        AccordSpace.fromJson(saved),
      ]);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(AppThemePreset.dark),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () =>
                      showAccordSpaceSettings(context, spaceId: 's1'),
                  child: const Text('Open settings'),
                ),
              ),
            ),
          ),
        ),
      );
      Future<void> open() async {
        await tester.tap(find.text('Open settings'));
        await tester.pumpAndSettle();
      }

      await open();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(attempts, 0);

      await open();
      await tester.enterText(find.byType(TextField).first, 'After');
      await tester.enterText(
        find.byType(TextField).at(1),
        'Updated description',
      );
      pending = Completer<void>();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      expect(attempts, 1);
      expect(find.byType(TextField), findsWidgets);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Open settings'), findsOneWidget);
      expect(saved['name'], 'After');
      expect(saved['description'], 'Updated description');

      await open();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'After',
      );
      await tester.enterText(find.byType(TextField).first, 'Retry me');
      fail = true;
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Save unavailable'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Retry me',
      );
      expect(saved['name'], 'After');
      fail = false;
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(saved['name'], 'Retry me');
      expect(find.text('Open settings'), findsOneWidget);
      await open();
      await tester.enterText(find.byType(TextField).first, 'Discard me');
      fail = true;
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Open settings'), findsOneWidget);
      expect(saved['name'], 'Retry me');
      expect(tester.takeException(), isNull);
    },
  );
}
