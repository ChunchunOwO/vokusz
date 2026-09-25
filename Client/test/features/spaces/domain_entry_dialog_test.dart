import 'dart:convert';
import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/authentication/models/accord_auth_state.dart';
import 'package:bonfire/features/authentication/models/accord_session.dart';
import 'package:bonfire/features/authentication/repositories/accord_auth.dart';
import 'package:bonfire/features/server/controllers/connections.dart';
import 'package:bonfire/features/server/models/accord_server.dart';
import 'package:bonfire/features/spaces/controllers/spaces.dart';
import 'package:bonfire/features/spaces/views/create_channel_dialog.dart';
import 'package:bonfire/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Auth extends AccordAuth {
  _Auth(this.client);
  @override
  final AccordClient client;
  @override
  AccordAuthState build() => const AccordAuthLoggedOut();
  @override
  AccordClient? clientForKey(String key) => client;
}

void main() {
  testWidgets(
    'domain entry validates IDs, preserves join failures and caches successful joins and creations',
    (tester) async {
      final requests = <http.Request>[];
      var denied = true;
      final client = AccordClient(
        token: 'test',
        baseUrl: 'https://example.test',
        httpClient: MockClient((request) async {
          requests.add(request);
          Object data;
          var status = 200;
          if (request.url.path.endsWith('/join')) {
            status = denied ? 403 : 200;
            data = denied
                ? {
                    'error': {'message': 'Private domain requires invitation'},
                  }
                : {
                    'data': {'space_id': '123'},
                  };
          } else if (request.url.path.endsWith('/channels')) {
            // Domain creation must remain successful even if optional setup fails.
            status = 500;
            data = {
              'error': {'message': 'Channel setup unavailable'},
            };
          } else {
            data = {
              'data': {
                'id': request.method == 'POST' ? '456' : '123',
                'name': 'Domain',
                'owner_id': 'u1',
              },
            };
          }
          return http.Response(
            jsonEncode(data),
            status,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final container = ProviderContainer(
        overrides: [accordAuthProvider.overrideWith(() => _Auth(client))],
      );
      addTearDown(container.dispose);
      final session = AccordSession(
        server: AccordServer.fromBaseUrl('https://example.test'),
        token: 'test',
        userId: 'u1',
        username: 'Owner',
      );
      final connections = container.read(
        connectionsControllerProvider.notifier,
      );
      connections.register(session);
      connections.setActive(session.key);
      String? selected;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(AppThemePreset.dark),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    selected = await showDialog<String>(
                      context: context,
                      builder: (_) => DomainEntryDialog(serverKey: session.key),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Join domain'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '../bad');
      await tester.tap(find.text('Join'));
      await tester.pumpAndSettle();
      expect(requests, isEmpty);
      expect(find.text('Enter a valid numeric domain ID.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text('Join'));
      await tester.pumpAndSettle();
      expect(find.text('Private domain requires invitation'), findsOneWidget);
      expect(
        container.read(connectionsControllerProvider).active!.spaces,
        isEmpty,
      );
      denied = false;
      await tester.tap(find.text('Join'));
      await tester.pumpAndSettle();
      expect(selected, '123');
      expect(container.read(spacesControllerProvider)!.single.id, '123');
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create domain'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.enterText(find.byType(TextField), 'Private domain');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(selected, '456');
      final create = requests.singleWhere(
        (r) => r.method == 'POST' && r.url.path.endsWith('/spaces'),
      );
      expect(jsonDecode(create.body), {
        'name': 'Private domain',
        'public': false,
      });
      expect(
        container
            .read(connectionsControllerProvider)
            .active!
            .spaces
            .map((s) => s.id),
        containsAll(['123', '456']),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
