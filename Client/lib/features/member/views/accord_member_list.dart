import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/l10n/ui_copy.dart';
import 'package:accordkit/accordkit.dart';
import 'package:bonfire/shared/utils/client_access.dart';
import 'package:bonfire/features/authentication/models/accord_auth_state.dart';
import 'package:bonfire/features/authentication/repositories/accord_auth.dart';
import 'package:bonfire/features/events/controllers/connection.dart';
import 'package:bonfire/features/events/controllers/presence.dart';
import 'package:bonfire/features/presence/rich_presence.dart';
import 'package:bonfire/features/presence/rich_presence_view.dart';
import 'package:bonfire/features/member/controllers/accord_members.dart';
import 'package:bonfire/features/member/utils/member_display.dart';
import 'package:bonfire/features/member/views/accord_member_avatar.dart';
import 'package:bonfire/features/member/views/accord_member_popout.dart';
import 'package:bonfire/features/member/views/remote_origin_badge.dart';
import 'package:bonfire/features/server/controllers/connections.dart';
import 'package:bonfire/features/spaces/controllers/spaces.dart';
import 'package:bonfire/features/user/views/accord_direct_messages.dart';
import 'package:bonfire/shared/components/async_state_views.dart';
import 'package:bonfire/shared/components/server_unreachable.dart';
import 'package:bonfire/shared/utils/rest_result_ext.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The right-hand member roster for the Accord home view. Groups the space's
/// cached members under their highest hoisted role (ungrouped members fall into
/// a trailing "Members" section), tinting each name by its highest colored
/// role. The Accord analogue of Bonfire's firebridge `MemberList`/
/// `MemberScrollView`, but driven by the simpler [AccordMembersController]
/// cache rather than lazy member-list sync ranges.
class AccordMemberList extends ConsumerWidget {
  const AccordMemberList({super.key, required this.spaceId, this.channel});

  final String? spaceId;
  final AccordChannel? channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BonfireThemeExtension.of(context);
    final id = spaceId;

    final body = id == null
        ? const SizedBox.shrink()
        : _Roster(spaceId: id, channel: channel);

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: colors.foreground,
        border: Border(left: BorderSide(color: colors.background, width: 1)),
      ),
      child: body,
    );
  }
}

class _Roster extends ConsumerWidget {
  const _Roster({required this.spaceId, this.channel});

  final String spaceId;
  final AccordChannel? channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(
      accordMembersControllerProvider(ref.readActiveServerKey() ?? '', spaceId),
    );
    // One selector for everything read off the cached space, so a rebuild
    // only walks spacesControllerProvider's list once instead of twice.
    final spaceInfo = ref.watch(
      spacesControllerProvider.select((spaces) {
        final space = spaces?.firstWhereOrNull((s) => s.id == spaceId);
        return (
          ownerId: space?.ownerId,
          roles: space?.roles ?? const <AccordRole>[],
          memberCount: space?.memberCount,
          presenceCount: space?.presenceCount,
        );
      }),
    );
    final roles = spaceInfo.roles;
    final cdnUrl = ref.watchCdnUrl();
    final presences = ref.watch(activePresencesProvider);

    if (members == null) {
      // The roster fetch itself failed (timeout / non-2xx / network) — surface
      // a retry instead of spinning forever. onRetry clears the failed flag
      // itself, then invalidates the controller to re-run `_load`.
      if (ref.watch(
        membersLoadFailedProvider(ref.readActiveServerKey() ?? '', spaceId),
      )) {
        return ServerUnreachable(
          title: UiCopy.couldnTLoadMembers(context: context),
          message: UiCopy.somethingWentWrongFetchingTheMemberList(
            context: context,
          ),
          onRetry: () {
            ref
                .read(
                  membersLoadFailedProvider(
                    ref.readActiveServerKey() ?? '',
                    spaceId,
                  ).notifier,
                )
                .set(false);
            ref.invalidate(
              accordMembersControllerProvider(
                ref.readActiveServerKey() ?? '',
                spaceId,
              ),
            );
          },
        );
      }
      final connectionStatus = ref.watch(
        connectionsControllerProvider.select(
          (connections) =>
              connections.active?.status ?? ConnectionStatus.disconnected,
        ),
      );
      if (connectionStatus.isUnreachable) {
        return ServerUnreachable(
          onRetry: () {
            final auth = ref.read(accordAuthProvider);
            if (auth is AccordAuthLoggedIn) {
              auth.client.ensureConnected();
            }
          },
        );
      }
      return const LoadingView();
    }

    final sections = _buildSections(
      members.values.toList(),
      roles,
      presences,
      memberCount: spaceInfo.memberCount,
      presenceCount: spaceInfo.presenceCount,
      ownerId: spaceInfo.ownerId,
      ownerLabel: AppStrings.choose('Domain owner', '域主', context: context),
    );

    // Flatten sections into one lazily-built row list so a large roster only
    // materializes the rows on screen.
    final rows = <Widget Function()>[
      for (final section in sections) ...[
        () => _SectionHeader(
          label: section.label,
          count: section.count ?? section.members.length,
        ),
        for (final member in section.members)
          () => _MemberRow(
            member: member,
            roles: roles,
            cdnUrl: cdnUrl,
            spaceId: spaceId,
            status: accordPresenceStatus(presences, member.userId),
          ),
      ],
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: rows.length,
      itemBuilder: (context, index) => rows[index](),
    );
  }
}

/// One roster group: a hoisted role's members, or the trailing default bucket.
class _RosterSection {
  _RosterSection({required this.label, required this.position}) : members = [];

  final String label;

  /// Role position for ordering; the default bucket uses [_defaultPosition] so
  /// it always sorts last.
  final int position;
  final List<AccordMember> members;
  int? count;
}

List<_RosterSection> _buildSections(
  List<AccordMember> members,
  List<AccordRole> roles,
  PresenceMap presences, {
  Object? memberCount,
  Object? presenceCount,
  String? ownerId,
  String ownerLabel = 'Domain owner',
}) {
  final sections = <String, _RosterSection>{};
  final orderedRoles = [...roles]
    ..sort((a, b) => b.position.compareTo(a.position));
  for (final member in members) {
    final owner = member.userId == ownerId;
    final role = owner ? null : memberHoistRole(member, orderedRoles);
    final key = owner ? 'domain-owner' : role?.id ?? 'ordinary';
    sections
        .putIfAbsent(
          key,
          () => _RosterSection(
            label: owner
                ? ownerLabel
                : role == null || role.name == '@everyone'
                ? AppStrings.choose('Ordinary members', '普通成员')
                : role.name,
            position: owner ? 0x7fffffff : role?.position ?? 0,
          ),
        )
        .members
        .add(member);
  }
  final result = sections.values.toList()
    ..sort((a, b) => b.position.compareTo(a.position));
  for (final section in result) {
    section.members.sort((a, b) {
      final offlineA = accordPresenceStatus(presences, a.userId) == 'offline';
      final offlineB = accordPresenceStatus(presences, b.userId) == 'offline';
      if (offlineA != offlineB) return offlineA ? 1 : -1;
      return accordMemberName(
        a,
      ).toLowerCase().compareTo(accordMemberName(b).toLowerCase());
    });
  }
  return result;
}

/// Uses the server's space summary for the complete offline total while the
/// roster itself stays bounded to its initial page. Older servers omit these
/// fields, in which case the visible rows remain the best available count.
int rosterOfflineCount({
  required Object? memberCount,
  required Object? presenceCount,
  required int loadedOfflineCount,
}) {
  final total = memberCount is num ? memberCount.toInt() : null;
  final online = presenceCount is num ? presenceCount.toInt() : null;
  if (total == null || online == null || total < 0 || online < 0) {
    return loadedOfflineCount;
  }
  final reported = total > online ? total - online : 0;
  return reported > loadedOfflineCount ? reported : loadedOfflineCount;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        '${label.toUpperCase()} — $count',
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: colors.gray,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.member,
    required this.roles,
    required this.cdnUrl,
    required this.spaceId,
    required this.status,
  });

  final AccordMember member;
  final List<AccordRole> roles;
  final String? cdnUrl;
  final String spaceId;
  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    final name = accordMemberName(member);
    final avatarUrl = accordMemberAvatarUrl(member, cdnUrl);
    final colorRole = memberColorRole(member, roles);
    final nameColor =
        communityNameColor(member.user) ??
        (colorRole == null
            ? colors.dirtyWhite
            : accordRoleColor(colorRole.color));
    final initial = accordInitial(name);
    final rich = richPresenceOf(
      ref.watch(
        activePresencesProvider.select(
          (presences) => presences[member.userId]?.activities,
        ),
      ),
    );
    // Offline members read as muted, matching the reference roster.
    final dimmed = status == 'offline';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => showAccordMemberPopout(
            context,
            spaceId: spaceId,
            userId: member.userId,
          ),
          onSecondaryTapUp: (d) => _showMemberContextMenu(
            context,
            ref,
            member,
            spaceId,
            d.globalPosition,
          ),
          onLongPress: () =>
              _showMemberContextMenu(context, ref, member, spaceId, null),
          child: Opacity(
            opacity: dimmed ? 0.5 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  AccordMemberAvatar(
                    avatarUrl: avatarUrl,
                    initial: initial,
                    status: status,
                    radius: 16,
                    backgroundColor: accordAvatarColor(
                      member.user,
                      member.userId,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (communityNameColor(member.user) != null)
                    Tooltip(
                      message: AppStrings.choose(
                        'Community management',
                        '社区管理',
                        context: context,
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        size: 14,
                        color: Color(0xFFFFB74D),
                      ),
                    ),
                  Expanded(
                    child: rich == null
                        ? Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: nameColor ?? colors.dirtyWhite,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: nameColor ?? colors.dirtyWhite,
                                ),
                              ),
                              RichPresenceLine(presence: rich),
                            ],
                          ),
                  ),
                  if (member.isRemote) ...[
                    const SizedBox(width: 6),
                    RemoteOriginBadge(
                      domain: member.homeDomain,
                      showDomain: false,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick-utility right-click / long-press menu for a roster member: view their
/// profile, start a DM, or copy their id/username. Moderation lives in the
/// profile popout reached by tapping the row. [globalPos] is the pointer
/// location for a right-click; it's null for a long-press, where the menu
/// anchors to the overlay centre instead.
Future<void> _showMemberContextMenu(
  BuildContext context,
  WidgetRef ref,
  AccordMember member,
  String spaceId,
  Offset? globalPos,
) async {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (overlay == null) return;
  final anchor = globalPos ?? overlay.size.center(Offset.zero);
  final currentUserId = ref.readUserId();
  final isSelf = currentUserId != null && currentUserId == member.userId;
  final username = member.user?.username;
  final selected = await showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(
      anchor & const Size(40, 40),
      Offset.zero & overlay.size,
    ),
    items: [
      PopupMenuItem(
        value: 'profile',
        child: Text(UiCopy.viewProfile(context: context)),
      ),
      if (!isSelf)
        PopupMenuItem(
          value: 'dm',
          child: Text(UiCopy.directMessage(context: context)),
        ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'copyId',
        child: Text(UiCopy.copyUserId(context: context)),
      ),
      if (username != null && username.isNotEmpty)
        PopupMenuItem(
          value: 'copyName',
          child: Text(UiCopy.copyUsername(context: context)),
        ),
    ],
  );
  if (selected == null || !context.mounted) return;
  switch (selected) {
    case 'profile':
      await showAccordMemberPopout(
        context,
        spaceId: spaceId,
        userId: member.userId,
      );
    case 'dm':
      await openAccordDirectMessage(context, ref, member.userId);
    case 'copyId':
      await Clipboard.setData(ClipboardData(text: member.userId));
      if (context.mounted)
        showInfoSnack(context, UiCopy.userIdCopied(context: context));
    case 'copyName':
      await Clipboard.setData(ClipboardData(text: username!));
      if (context.mounted)
        showInfoSnack(context, UiCopy.usernameCopied(context: context));
  }
}
