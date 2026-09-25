import 'package:accordkit/accordkit.dart';

/// A space update from REST or the gateway often omits roles and emoji.
/// Replacing the cached space with that payload would wipe them. Keep the
/// previous lists when the incoming space has none.
void retainOmittedSpaceDetails(AccordSpace next, AccordSpace? previous) {
  if (previous == null) return;
  if (next.roles.isEmpty && previous.roles.isNotEmpty) {
    next.roles = List<AccordRole>.of(previous.roles);
  }
  if (next.emojis.isEmpty && previous.emojis.isNotEmpty) {
    next.emojis = List<AccordEmoji>.of(previous.emojis);
  }
}
