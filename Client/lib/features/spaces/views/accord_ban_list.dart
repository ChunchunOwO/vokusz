import 'package:bonfire/l10n/ui_copy.dart';
import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/member/utils/member_display.dart';
import 'package:bonfire/shared/components/async_state_views.dart';
import 'package:bonfire/shared/utils/rest_result_ext.dart';
import 'package:bonfire/shared/utils/confirm_dialog.dart';
import 'package:bonfire/shared/utils/client_access.dart';
import 'package:bonfire/shared/utils/responsive_dialog.dart';
import 'package:bonfire/shared/utils/self_loading_list.dart';
import 'package:bonfire/features/user/controllers/accord_users.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the ban list dialog for [spaceId]. Gated on `ban_members` by the
/// caller (space settings). Lists banned users with their reason and an unban
/// action per row. Mirrors the reference client's ban management dialog.
Future<void> showAccordBanList(
  BuildContext context, {
  required String spaceId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _BanList(spaceId: spaceId),
  );
}

class _BanList extends ConsumerStatefulWidget {
  const _BanList({required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<_BanList> createState() => _BanListState();
}

class _BanListState extends ConsumerState<_BanList>
    with SelfLoadingListState<_Ban, _BanList> {
  String _query = '';
  final Set<String> _selected = {};

  /// Bans matching the current search query (by name or reason).
  List<_Ban> get _filtered {
    final all = items ?? const <_Ban>[];
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where(
          (b) =>
              b.name.toLowerCase().contains(q) ||
              b.reason.toLowerCase().contains(q),
        )
        .toList();
  }

  AccordClient? get _client => ref.accordClient;

  @override
  bool get canLoad => _client != null;

  @override
  Future<(List<_Ban>? items, String? error)> fetchItems() async {
    final result = await _client!.bans.list(widget.spaceId);
    if (!result.ok) return (null, result.errorOr(UiCopy.failedToLoadBans()));
    final raw = result.data;
    final parsed = <_Ban>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map) parsed.add(_Ban.fromJson(entry));
      }
    }
    return (parsed, null);
  }

  Future<void> _unban(_Ban ban) async {
    final client = _client;
    if (client == null) return;
    final ok = await showConfirmDialog(
      context,
      title: UiCopy.unbanMember(),
      message: UiCopy.allowBackIntoTheSpace(arg0: ban.name),
      confirmLabel: UiCopy.unban(),
    );
    if (ok != true || !mounted) return;
    setState(() => loading = true);
    final result = await client.bans.remove(widget.spaceId, ban.userId);
    if (!mounted) return;
    if (!result.ok) {
      setState(() {
        loading = false;
        error = result.errorOr(UiCopy.failedToUnban());
      });
      return;
    }
    setState(() {
      items?.removeWhere((b) => b.userId == ban.userId);
      _selected.remove(ban.userId);
      loading = false;
    });
  }

  Future<void> _bulkUnban() async {
    final client = _client;
    if (client == null || _selected.isEmpty) return;
    final ids = _selected.toList();
    final ok = await showConfirmDialog(
      context,
      title: UiCopy.unbanMembers(),
      message: UiCopy.allowMemberSBackIntoTheSpace(arg0: ids.length),
      confirmLabel: UiCopy.unban(),
    );
    if (ok != true || !mounted) return;
    setState(() => loading = true);
    final failed = <String>[];
    for (final id in ids) {
      final result = await client.bans.remove(widget.spaceId, id);
      if (result.ok) {
        items?.removeWhere((b) => b.userId == id);
      } else {
        failed.add(id);
      }
    }
    if (!mounted) return;
    setState(() {
      loading = false;
      _selected
        ..clear()
        ..addAll(failed);
      error = failed.isEmpty
          ? null
          : UiCopy.failedToUnban2(arg0: failed.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    final bans = items;
    // Ensure any bans the API returned with only a userId resolve their name
    // on the next rebuild via the on-demand user cache.
    final users = ref.watch(
      accordUsersControllerProvider(ref.readActiveServerKey() ?? ''),
    );
    final ensureUser = ref
        .read(
          accordUsersControllerProvider(
            ref.readActiveServerKey() ?? '',
          ).notifier,
        )
        .ensure;
    if (bans != null) {
      for (final b in bans) {
        if (b.username == null) {
          final cached = users[b.userId];
          if (cached != null) {
            b.username = cached.username;
            b.displayName = cached.displayName ?? b.displayName;
          } else {
            ensureUser(b.userId);
          }
        }
      }
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: dialogConstraints(context, maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel, size: 18, color: colors.dirtyWhite),
                  const SizedBox(width: 8),
                  Text(
                    UiCopy.bannedMembers(context: context),
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: UiCopy.refresh(context: context),
                    onPressed: loading ? null : load,
                    icon: const Icon(Icons.refresh, size: 18),
                  ),
                  IconButton(
                    tooltip: UiCopy.close(context: context),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (bans != null && bans.isNotEmpty)
                TextField(
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search, size: 18),
                    hintText: UiCopy.searchBannedMembers(context: context),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${_selected.length} selected',
                      style: theme.textTheme.bodySmall,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => setState(_selected.clear),
                      child: Text(UiCopy.clear(context: context)),
                    ),
                    FilledButton.icon(
                      onPressed: loading ? null : _bulkUnban,
                      icon: const Icon(Icons.lock_open, size: 16),
                      label: Text(UiCopy.unbanSelected(context: context)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InlineError(error!, centered: false),
                ),
              Flexible(
                child: loading && bans == null
                    ? const LoadingView()
                    : bans == null || bans.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            bans == null
                                ? UiCopy.loading(context: context)
                                : UiCopy.noBansInThisSpace(context: context),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final filtered = _filtered;
                          if (filtered.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  UiCopy.noMatchingBans(context: context),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final ban = filtered[index];
                              final selected = _selected.contains(ban.userId);
                              return ListTile(
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: selected,
                                      onChanged: loading
                                          ? null
                                          : (v) => setState(() {
                                              if (v == true) {
                                                _selected.add(ban.userId);
                                              } else {
                                                _selected.remove(ban.userId);
                                              }
                                            }),
                                    ),
                                    CircleAvatar(
                                      radius: 16,
                                      child: Text(ban.initial),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  ban.name,
                                  style: theme.textTheme.titleSmall,
                                ),
                                subtitle: Text(
                                  ban.reason.isEmpty
                                      ? UiCopy.noReasonGiven(context: context)
                                      : ban.reason,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: TextButton.icon(
                                  onPressed: loading ? null : () => _unban(ban),
                                  icon: const Icon(Icons.lock_open, size: 16),
                                  label: Text(UiCopy.unban(context: context)),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loosely-typed shape of a ban entry. The bans API returns raw JSON; fields
/// vary by server, so we accept the common subset and let the dialog hydrate
/// the name via the on-demand user cache when only the userId came back.
class _Ban {
  _Ban({
    required this.userId,
    required this.reason,
    this.username,
    this.displayName,
  });

  final String userId;
  final String reason;
  String? username;
  String? displayName;

  /// displayName → username → "Unknown". Never the raw snowflake (#25).
  String get name => accordUserName(
    AccordUser(id: userId, username: username ?? '', displayName: displayName),
  );

  String get initial => accordInitial(name);

  factory _Ban.fromJson(Map data) {
    final user = data['user'];
    String? userId;
    String? username;
    String? displayName;
    if (user is Map) {
      userId = user['id']?.toString();
      username = user['username']?.toString();
      displayName = user['display_name']?.toString();
    }
    userId ??= data['user_id']?.toString() ?? '';
    return _Ban(
      userId: userId,
      reason: data['reason']?.toString() ?? '',
      username: username,
      displayName: displayName,
    );
  }
}
