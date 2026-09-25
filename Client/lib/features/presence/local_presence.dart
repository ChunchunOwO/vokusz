import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/events/controllers/presence.dart';

/// The activities this client last published, so a status change does not
/// wipe a game and a new game does not wipe a custom status.
class LocalPresence {
  LocalPresence._();

  static String status = 'online';
  static String? custom;
  static Map<String, dynamic>? rich;
  static bool _seeded = false;

  static void reset() {
    status = 'online';
    custom = null;
    rich = null;
    _seeded = false;
  }

  /// Copies the current dot and custom status once. Later edits own the copy.
  static void ensureSeeded(PresenceMap presences, String userId) {
    if (_seeded) return;
    _seeded = true;
    final current = accordPresenceStatus(presences, userId);
    status = current == 'offline' ? 'online' : current;
    custom = accordCustomStatus(presences, userId);
  }

  static List<Map<String, dynamic>> get activities {
    final list = <Map<String, dynamic>>[];
    final text = custom?.trim();
    if (text != null && text.isNotEmpty) {
      list.add({'name': text, 'type': 'custom'});
    }
    final activity = rich;
    if (activity != null) list.add(activity);
    return list;
  }

  static void publish(
    AccordClient client,
    PresenceController notifier,
    String userId,
  ) {
    if (status == 'offline') return;
    final list = activities;
    final primary = rich ??
        (list.isEmpty ? const <String, dynamic>{} : list.first);
    client.gateway.updatePresence(
      status,
      activity: primary,
      activities: list,
    );
    notifier.upsert(
      AccordPresence(
        userId: userId,
        status: status,
        activities: [for (final item in list) AccordActivity.fromJson(item)],
      ),
    );
  }
}
