import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped when a relationship event arrives, so an open Friends tab reloads.
class RelationshipEpoch extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final relationshipEpochProvider =
    NotifierProvider<RelationshipEpoch, int>(RelationshipEpoch.new);
