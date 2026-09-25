import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/member/utils/member_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'community badge is display-only and never trusted for remote users',
    () {
      final user = AccordUser.fromJson({'id': '1', 'community_admin': true});
      expect(user.isAdmin, isFalse);
      expect(communityNameColor(user), isNotNull);
      expect(communityNameColor(AccordUser.fromJson(user.toJson())), isNotNull);
      user.origin = 'remote.example';
      expect(communityNameColor(user), isNull);
      expect(communityNameColor(AccordUser(id: '2')), isNull);
    },
  );
}
