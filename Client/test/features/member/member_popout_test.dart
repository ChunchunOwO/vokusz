import 'dart:convert';

import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/authentication/models/accord_auth_state.dart';
import 'package:bonfire/features/authentication/models/accord_session.dart';
import 'package:bonfire/features/authentication/repositories/accord_auth.dart';
import 'package:bonfire/features/member/controllers/accord_members.dart';
import 'package:bonfire/features/member/views/accord_member_popout.dart';
import 'package:bonfire/features/server/models/accord_server.dart';
import 'package:bonfire/features/spaces/controllers/spaces.dart';
import 'package:bonfire/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The member profile card: roles are edited in place (remove on the chip, add
/// from the "Add" menu), moderation and the footer actions are reachable, your
/// own card swaps messaging for editing, and a phone stacks the moderation
/// buttons rather than clipping them.

const _spaceId = 'space1';
const _selfId = 'u1';
const _memberId = 'u2';

const _desktop = Size(1024, 768);
const _phone = Size(360, 780);

class _Harness {
  _Harness() {
    final responder = MockClient((request) async {
      requests.add('${request.method} ${request.url.path}');
      return http.Response(
        jsonEncode({'data': <Object>[]}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final server = AccordServer.fromBaseUrl('https://accord.example.test');
    final client = AccordClient(
      token: 'test-token',
      tokenType: 'Bearer',
      baseUrl: server.baseUrl,
      gatewayUrl: server.gatewayUrl,
      cdnUrl: server.cdnUrl,
      httpClient: responder,
    );
    final space = AccordSpace(
      id: _spaceId,
      ownerId: _selfId,
      roles: [
        AccordRole(id: 'everyone', name: '@everyone', position: 0),
        AccordRole(id: 'helper', name: 'Helper', position: 1),
        AccordRole(id: 'mod', name: 'Moderator', position: 2),
      ],
    );
    container = ProviderContainer(
      overrides: [
        accordAuthProvider.overrideWithValue(
          AccordAuthLoggedIn(
            client: client,
            session: AccordSession(
              server: server,
              token: 'test-token',
              userId: _selfId,
              username: 'self',
            ),
          ),
        ),
        spacesControllerProvider.overrideWithValue([space]),
        accordMembersControllerProvider('', _spaceId).overrideWith(
          () => _SeededMembers({
            _selfId: AccordMember(
              userId: _selfId,
              spaceId: _spaceId,
              joinedAt: '2025-11-02T09:00:00Z',
              user: AccordUser(id: _selfId, username: 'self'),
            ),
            _memberId: AccordMember(
              userId: _memberId,
              spaceId: _spaceId,
              roles: ['helper'],
              joinedAt: '2025-11-02T09:00:00Z',
              user: AccordUser(
                id: _memberId,
                username: 'alice',
                bio: 'Keeps the workshop tidy.',
              ),
            ),
          }),
        ),
      ],
    );
  }

  final List<String> requests = [];
  late final ProviderContainer container;

  Widget app(String userId) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: buildAppTheme(AppThemePreset.dark),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAccordMemberPopout(
              context,
              spaceId: _spaceId,
              userId: userId,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

/// The roster as a real controller (the card writes role and nickname changes
/// back through its notifier), seeded instead of fetched.
class _SeededMembers extends AccordMembersController {
  _SeededMembers(this.seed);

  final Map<String, AccordMember> seed;

  @override
  Map<String, AccordMember>? build(String serverKey, String spaceId) => seed;
}

Future<_Harness> _open(WidgetTester tester, String userId, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final h = _Harness();
  addTearDown(h.container.dispose);
  await tester.pumpWidget(h.app(userId));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return h;
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('another member: details, roles in place, all actions', (
    tester,
  ) async {
    final h = await _open(tester, _memberId, _desktop);

    expect(find.text('Keeps the workshop tidy.'), findsOneWidget);
    expect(find.text('2025-11-02'), findsOneWidget);
    // The held role is a chip with a remove control; the other assignable
    // role waits in the Add menu.
    expect(find.text('Helper'), findsOneWidget);
    expect(find.byTooltip('Remove role'), findsOneWidget);
    expect(find.text('Moderator'), findsNothing);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moderator'));
    await tester.pumpAndSettle();
    expect(
      h.requests,
      contains('PUT /api/v1/spaces/$_spaceId/members/$_memberId/roles/mod'),
    );

    // Roles list highest first, so the new Moderator chip now leads.
    final helperChip = find.ancestor(
      of: find.text('Helper'),
      matching: find.byType(Row),
    );
    await tester.tap(
      find.descendant(
        of: helperChip.first,
        matching: find.byTooltip('Remove role'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      h.requests,
      contains(
        'DELETE /api/v1/spaces/$_spaceId/members/$_memberId/roles/helper',
      ),
    );

    expect(find.text('Kick'), findsOneWidget);
    expect(find.text('Ban'), findsOneWidget);
    expect(find.text('Direct Message'), findsOneWidget);
    expect(find.byTooltip('Report user'), findsOneWidget);
    expect(find.byTooltip('Block user'), findsOneWidget);
    expect(find.text('Edit profile'), findsNothing);

    // Time out opens its duration menu from the button.
    await tester.tap(find.text('Time out'));
    await tester.pumpAndSettle();
    expect(find.text('1 hour'), findsOneWidget);
    await tester.tap(find.text('1 hour'));
    await tester.pumpAndSettle();
    expect(
      h.requests,
      contains('PATCH /api/v1/spaces/$_spaceId/members/$_memberId'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('your own card edits instead of messaging or reporting', (
    tester,
  ) async {
    await _open(tester, _selfId, _desktop);

    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Direct Message'), findsNothing);
    expect(find.byTooltip('Report user'), findsNothing);
    expect(find.byTooltip('Block user'), findsNothing);
    // No moderating yourself.
    expect(find.text('Kick'), findsNothing);
    expect(find.text('Ban'), findsNothing);
  });

  testWidgets('a phone stacks the moderation buttons', (tester) async {
    await _open(tester, _memberId, _phone);

    final timeout = tester.getRect(find.text('Time out'));
    final kick = tester.getRect(find.text('Kick'));
    final ban = tester.getRect(find.text('Ban'));
    expect(kick.top, greaterThan(timeout.bottom));
    expect(ban.top, greaterThan(kick.bottom));
    expect(tester.takeException(), isNull);
  });
}
