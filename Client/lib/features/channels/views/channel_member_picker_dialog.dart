import 'dart:async';
import 'package:bonfire/l10n/ui_copy.dart';
import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/member/utils/member_display.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// Search-and-pick dialog used to add a new member permission overwrite from
/// [showChannelPermissionsDialog]. Pops the picked member's user ID, or `null`
/// if dismissed.
class ChannelMemberPickerDialog extends StatefulWidget {
  const ChannelMemberPickerDialog({
    super.key,
    required this.members,
    this.search,
  });

  final List<AccordMember> members;
  final Future<List<AccordMember>> Function(String)? search;

  @override
  State<ChannelMemberPickerDialog> createState() =>
      _ChannelMemberPickerDialogState();
}

class _ChannelMemberPickerDialogState extends State<ChannelMemberPickerDialog> {
  String _query = '';
  List<AccordMember>? _results;
  Timer? _searchTimer;
  bool _searching = false;
  bool _failed = false;

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onQuery(String value) {
    _searchTimer?.cancel();
    setState(() {
      _query = value;
      _results = null;
      _failed = false;
      _searching = widget.search != null && value.trim().isNotEmpty;
    });
    if (!_searching) return;
    _searchTimer = Timer(const Duration(milliseconds: 250), () async {
      try {
        final results = await widget.search!(value.trim());
        if (mounted && _query == value) {
          setState(() {
            _results = results;
            _searching = false;
          });
        }
      } catch (_) {
        if (mounted && _query == value) {
          setState(() {
            _failed = true;
            _searching = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final theme = Theme.of(context);
    final q = _query.trim().toLowerCase();
    final matches = (_results ?? widget.members)
        .where(
          (m) => q.isEmpty || accordMemberName(m).toLowerCase().contains(q),
        )
        .sortedBy((m) => accordMemberName(m).toLowerCase());

    return Dialog(
      backgroundColor: colors.foreground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320, maxHeight: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: UiCopy.searchMembers(context: context),
                  border: OutlineInputBorder(),
                ),
                onChanged: _onQuery,
              ),
            ),
            if (_searching) const LinearProgressIndicator(),
            if (_failed)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(UiCopy.couldnTLoadMembers(context: context)),
              ),
            Flexible(
              child: matches.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        UiCopy.noMembers(context: context),
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        for (final m in matches)
                          ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.person_outline,
                              color: colors.gray,
                            ),
                            title: Text(accordMemberName(m)),
                            onTap: () => Navigator.of(context).pop(m.userId),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
