import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/l10n/ui_copy.dart';
import 'package:bonfire/shared/utils/client_access.dart';
import 'package:bonfire/features/events/controllers/presence.dart';
import 'package:bonfire/features/presence/local_presence.dart';
import 'package:bonfire/features/server/controllers/connections.dart';
import 'package:bonfire/features/member/utils/member_display.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The statuses a user can set for themselves.
const _statusOptions = <({String value, String label, IconData icon})>[
  (value: 'online', label: 'Online', icon: Icons.circle),
  (value: 'idle', label: 'Idle', icon: Icons.nightlight_round),
  (value: 'dnd', label: 'Do Not Disturb', icon: Icons.remove_circle),
  (value: 'invisible', label: 'Invisible', icon: Icons.circle_outlined),
];

/// A presence dot the user can tap to change their own status. Sends the new
/// status over the gateway and optimistically updates the local presence cache
/// so the dot reflects the choice immediately.
class SelfStatusButton extends ConsumerWidget {
  const SelfStatusButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BonfireThemeExtension.of(context);
    final userId = ref.watchUserId();
    final status = ref.watch(
      activePresencesProvider.select(
        (p) => userId == null ? 'offline' : accordPresenceStatus(p, userId),
      ),
    );
    final customStatus = ref.watch(
      activePresencesProvider.select(
        (p) => userId == null ? null : accordCustomStatus(p, userId),
      ),
    );
    final dotColor = accordPresenceColor(status) ?? colors.gray;

    return PopupMenuButton<String>(
      tooltip: customStatus ?? AppStrings.label('Set status', context: context),
      onSelected: (value) {
        switch (value) {
          case _customValue:
            _showCustomStatusDialog(context, ref, userId, status, customStatus);
          case _clearCustomValue:
            _setCustomStatus(ref, userId, status, '');
          default:
            _setStatus(ref, userId, value);
        }
      },
      itemBuilder: (context) => [
        for (final option in _statusOptions)
          PopupMenuItem(
            value: option.value,
            child: Row(
              children: [
                Icon(
                  option.icon,
                  size: 14,
                  color: accordPresenceColor(option.value) ?? colors.gray,
                ),
                const SizedBox(width: 10),
                Text(AppStrings.label(option.label, context: context)),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _customValue,
          child: Row(
            children: [
              Icon(Icons.edit_note, size: 16, color: colors.gray),
              const SizedBox(width: 10),
              Text(
                customStatus == null
                    ? UiCopy.setCustomStatus(context: context)
                    : UiCopy.editStatus(context: context),
              ),
            ],
          ),
        ),
        if (customStatus != null)
          PopupMenuItem(
            value: _clearCustomValue,
            child: Row(
              children: [
                Icon(Icons.clear, size: 16, color: colors.gray),
                const SizedBox(width: 10),
                Text(UiCopy.clearCustomStatus(context: context)),
              ],
            ),
          ),
      ],
      icon: Icon(Icons.circle, size: 16, color: dotColor),
    );
  }

  static const String _customValue = '__custom__';
  static const String _clearCustomValue = '__clear_custom__';

  Future<void> _showCustomStatusDialog(
    BuildContext context,
    WidgetRef ref,
    String? userId,
    String status,
    String? current,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _CustomStatusDialog(initial: current ?? ''),
    );
    if (result == null) return; // cancelled
    _setCustomStatus(ref, userId, status, result);
  }

  /// Sends the custom status as the presence `activity` name (empty clears it)
  /// and optimistically updates the local presence cache.
  void _setCustomStatus(
    WidgetRef ref,
    String? userId,
    String status,
    String text,
  ) {
    final client = ref.accordClient;
    if (client == null || userId == null) return;
    final key = ref.read(connectionsControllerProvider).activeKey;
    if (key == null) return;
    LocalPresence.ensureSeeded(ref.read(presenceControllerProvider(key)), userId);
    LocalPresence.status = status;
    LocalPresence.custom = text.trim().isEmpty ? null : text.trim();
    LocalPresence.publish(
      client,
      ref.read(presenceControllerProvider(key).notifier),
      userId,
    );
  }

  void _setStatus(WidgetRef ref, String? userId, String status) {
    final client = ref.accordClient;
    if (client == null || userId == null) return;
    final key = ref.read(connectionsControllerProvider).activeKey;
    if (key == null) return;
    LocalPresence.ensureSeeded(ref.read(presenceControllerProvider(key)), userId);
    LocalPresence.status = status;
    LocalPresence.publish(
      client,
      ref.read(presenceControllerProvider(key).notifier),
      userId,
    );
  }
}

/// Dialog to enter a custom status: an optional emoji prefix plus text. Returns
/// the composed status string ("😀 text" or "text"), or empty to clear.
class _CustomStatusDialog extends StatefulWidget {
  const _CustomStatusDialog({required this.initial});

  final String initial;

  @override
  State<_CustomStatusDialog> createState() => _CustomStatusDialogState();
}

class _CustomStatusDialogState extends State<_CustomStatusDialog> {
  late final TextEditingController _emoji;
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    // Split a leading emoji (non-alphanumeric first token) from the text.
    final initial = widget.initial.trim();
    final match = RegExp(r'^(\S+)\s+(.*)$').firstMatch(initial);
    if (match != null && _looksLikeEmoji(match.group(1)!)) {
      _emoji = TextEditingController(text: match.group(1));
      _text = TextEditingController(text: match.group(2));
    } else {
      _emoji = TextEditingController();
      _text = TextEditingController(text: initial);
    }
  }

  static bool _looksLikeEmoji(String s) =>
      s.isNotEmpty && !RegExp(r'[A-Za-z0-9]').hasMatch(s);

  @override
  void dispose() {
    _emoji.dispose();
    _text.dispose();
    super.dispose();
  }

  String get _composed {
    final e = _emoji.text.trim();
    final t = _text.text.trim();
    if (e.isEmpty) return t;
    if (t.isEmpty) return e;
    return '$e $t';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(UiCopy.setCustomStatus(context: context)),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: TextField(
              controller: _emoji,
              textAlign: TextAlign.center,
              maxLength: 8,
              decoration: InputDecoration(
                labelText: UiCopy.emoji(context: context),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _text,
              autofocus: true,
              maxLength: 128,
              decoration: InputDecoration(
                labelText: UiCopy.status(context: context),
                hintText: UiCopy.whatSOnYourMind(context: context),
              ),
              onSubmitted: (_) => Navigator.of(context).pop(_composed),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(UiCopy.cancel(context: context)),
        ),
        if (widget.initial.trim().isNotEmpty)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(UiCopy.clear(context: context)),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_composed),
          child: Text(UiCopy.save(context: context)),
        ),
      ],
    );
  }
}
