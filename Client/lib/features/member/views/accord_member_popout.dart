import 'dart:async';

import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/l10n/ui_copy.dart';
import 'package:accordkit/accordkit.dart';
import 'package:bonfire/shared/components/async_state_views.dart';
import 'package:bonfire/shared/utils/rest_result_ext.dart';
import 'package:bonfire/shared/utils/ban_dialog.dart';
import 'package:bonfire/shared/utils/confirm_dialog.dart';
import 'package:bonfire/shared/utils/client_access.dart';
import 'package:bonfire/shared/utils/text_prompt_dialog.dart';
import 'package:bonfire/features/events/controllers/presence.dart';
import 'package:bonfire/features/presence/rich_presence.dart';
import 'package:bonfire/features/presence/rich_presence_view.dart';
import 'package:bonfire/features/member/controllers/accord_members.dart';
import 'package:bonfire/features/member/utils/member_display.dart';
import 'package:bonfire/features/member/utils/permissions.dart';
import 'package:bonfire/features/member/views/accord_member_avatar.dart';
import 'package:bonfire/features/member/views/remote_origin_badge.dart';
import 'package:bonfire/features/spaces/controllers/spaces.dart';
import 'package:bonfire/features/spaces/views/accord_role_management.dart';
import 'package:bonfire/features/user/controllers/accord_users.dart';
import 'package:bonfire/features/user/controllers/blocked_users.dart';
import 'package:bonfire/features/user/views/accord_direct_messages.dart';
import 'package:bonfire/features/spaces/views/accord_reports.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:bonfire/features/member/views/user_banner.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the member profile popout for [userId] within [spaceId] as a modal.
Future<void> showAccordMemberPopout(
  BuildContext context, {
  required String spaceId,
  required String userId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _MemberPopout(spaceId: spaceId, userId: userId),
  );
}

/// Available timeout durations (label → seconds), mirroring the reference
/// client's `moderate_member_dialog`.
List<(String, int)> _timeoutDurations(BuildContext context) => [
  (AppStrings.choose('60 seconds', '60 秒', context: context), 60),
  (AppStrings.choose('5 minutes', '5 分钟', context: context), 300),
  (AppStrings.choose('10 minutes', '10 分钟', context: context), 600),
  (AppStrings.choose('1 hour', '1 小时', context: context), 3600),
  (AppStrings.choose('1 day', '1 天', context: context), 86400),
  (AppStrings.choose('1 week', '1 周', context: context), 604800),
];

class _MemberPopout extends ConsumerStatefulWidget {
  const _MemberPopout({required this.spaceId, required this.userId});

  final String spaceId;
  final String userId;

  @override
  ConsumerState<_MemberPopout> createState() => _MemberPopoutState();
}

class _MemberPopoutState extends ConsumerState<_MemberPopout> {
  bool _busy = false;
  String? _error;
  AccordUser? _profile;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshProfile());
  }

  /// The roster copy of a user is often from before they set a banner. Fetch
  /// the live profile so the banner and bio in this dialog are current.
  Future<void> _refreshProfile() async {
    final client = _client;
    if (client == null) return;
    final result = await client.users.fetch(widget.userId);
    if (!mounted) return;
    final user = result.data;
    if (user is! AccordUser) return;
    ref.read(accordUsersControllerProvider(_serverKey).notifier).upsert(user);
    ref
        .read(
          accordMembersControllerProvider(
            _serverKey,
            widget.spaceId,
          ).notifier,
        )
        .applyUserUpdate(user);
    setState(() => _profile = user);
  }

  AccordClient? get _client => ref.accordClient;
  String get _serverKey => ref.readActiveServerKey() ?? '';

  Future<void> _run(
    Future<RestResult> Function(AccordClient client) action, {
    String failure = 'Action failed',
    bool closeOnSuccess = false,
    VoidCallback? onSuccess,

    /// Given the successful result, for actions that report something back
    /// (e.g. how many messages a ban purged). Runs before [closeOnSuccess]
    /// pops, so it must not touch this popout's context.
    void Function(RestResult result)? onResult,
    bool missingIsSuccess = false,
  }) async {
    final client = _client;
    if (client == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await action(client);
    if (!mounted) return;
    // For removal actions (kick/ban), a "resource does not exist" / not-found
    // error means the member is already gone server-side — the desired end
    // state. Treat it as success so a stale roster row still gets cleared
    // instead of leaving the member stuck with a confusing error.
    final ok = result.ok || (missingIsSuccess && _isMissingResource(result));
    if (ok) {
      onSuccess?.call();
      onResult?.call(result);
      if (closeOnSuccess) {
        Navigator.of(context).pop();
        return;
      }
      setState(() => _busy = false);
    } else {
      setState(() {
        _busy = false;
        _error = result.errorOr(failure);
      });
    }
  }

  /// Whether [result] is a "the target no longer exists" error (HTTP 404 or the
  /// server's foreign-key / not-found message), meaning the member is already
  /// absent.
  bool _isMissingResource(RestResult result) {
    if (result.statusCode == 404) return true;
    final msg = result.error?.toString().toLowerCase() ?? '';
    return msg.contains('does not exist') || msg.contains('not found');
  }

  void _kick() {
    _run(
      (c) => c.members.kick(widget.spaceId, widget.userId),
      failure: UiCopy.failedToKickMember(),
      closeOnSuccess: true,
      missingIsSuccess: true,
      onSuccess: () => ref
          .read(
            accordMembersControllerProvider(
              _serverKey,
              widget.spaceId,
            ).notifier,
          )
          .removeMember(widget.userId),
    );
  }

  /// Reports this user to the space's moderators, with the option to block
  /// them at the same time (App Review 1.2 — see #290).
  void _report() {
    showReportDialog(
      context,
      spaceId: widget.spaceId,
      targetType: 'user',
      targetId: widget.userId,
      reportedUserId: widget.userId,
      reportedName: _displayName,
    );
  }

  /// Blocks this user (relationship type 2). Account-level, not space-scoped —
  /// uses `users.putRelationship`. Unblocking lives in the Friends → Blocked
  /// list.
  Future<void> _block() async {
    final confirmed = await _confirm(
      title: UiCopy.blockUser(),
      message: UiCopy.blockedUsersCanTDmYouAnd(),
      action: UiCopy.block(),
    );
    if (confirmed != true) return;
    _run(
      (c) => c.users.putRelationship(widget.userId, {
        'type': accordBlockedRelationship,
      }),
      failure: UiCopy.failedToBlockUser(),
      closeOnSuccess: true,
      // Applies the "their messages are hidden" half of the promise right away
      // rather than at the next relationship fetch (#290).
      onSuccess: () => ref.blockedUsers.block(widget.userId),
    );
  }

  /// The member's display name, resolved the same way [build] resolves it, for
  /// the moderation dialogs that name their target.
  String get _displayName {
    final member = ref.read(
      accordMembersControllerProvider(_serverKey, widget.spaceId),
    )?[widget.userId];
    if (member != null) return accordMemberName(member);
    final cached = ref.read(
      accordUsersControllerProvider(_serverKey),
    )[widget.userId];
    return accordUserName(cached, fallback: widget.userId);
  }

  Future<void> _ban() async {
    // Resolved up front because the ban removes the member from the roster
    // cache `_displayName` reads, leaving only the raw id afterwards.
    final name = _displayName;
    final request = await showBanDialog(context, memberName: name);
    if (request == null || !mounted) return;
    // Captured now: the popout pops itself on success, so by the time the
    // result lands its own context can no longer find a messenger.
    final messenger = ScaffoldMessenger.maybeOf(context);
    _run(
      (c) =>
          c.bans.create(widget.spaceId, widget.userId, data: request.toJson()),
      failure: UiCopy.failedToBanMember(),
      closeOnSuccess: true,
      missingIsSuccess: true,
      onSuccess: () => ref
          .read(
            accordMembersControllerProvider(
              _serverKey,
              widget.spaceId,
            ).notifier,
          )
          .removeMember(widget.userId),
      onResult: (result) {
        if (request.deleteMessageSeconds == 0) return;
        // Reported rather than assumed: a server that predates the purge
        // ignores the field, and this is the only way that shows up.
        final count = _deletedMessageCount(result);
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              count == 1
                  ? UiCopy.bannedAndDeleted1Message(arg0: name)
                  : UiCopy.bannedAndDeletedMessages(arg0: name, arg1: count),
            ),
          ),
        );
      },
    );
  }

  /// `deleted_message_count` from a ban response, or 0 when the server didn't
  /// report one (i.e. it doesn't support purging on ban).
  int _deletedMessageCount(RestResult result) {
    final data = result.data;
    if (data is! Map) return 0;
    final count = data['deleted_message_count'];
    return asInt(count);
  }

  void _timeout(int seconds) {
    final until = DateTime.now().toUtc().add(Duration(seconds: seconds));
    final iso = '${until.toIso8601String().split('.').first}Z';
    _run(
      (c) => c.members.update(widget.spaceId, widget.userId, {
        'communication_disabled_until': iso,
      }),
      failure: UiCopy.failedToTimeOutMember(),
    );
  }

  void _removeTimeout() {
    _run(
      (c) => c.members.update(widget.spaceId, widget.userId, {
        'communication_disabled_until': null,
      }),
      failure: UiCopy.failedToRemoveTimeout(),
    );
  }

  /// Sets or clears [member]'s nickname. An empty value resets to the display
  /// name. Optimistically mirrors the result into the member cache.
  Future<void> _editNickname(AccordMember member) async {
    final initial = member.nickname ?? '';
    final next = (await showTextPromptDialog(
      context,
      title: UiCopy.changeNickname(),
      label: UiCopy.nickname(),
      hintText: UiCopy.leaveEmptyToResetToTheirDisplay(),
      initial: initial,
      resetLabel: initial.isNotEmpty ? UiCopy.reset() : null,
    ))?.trim();
    if (next == null || !mounted) return;
    _run(
      (c) => c.members.update(widget.spaceId, widget.userId, {
        'nickname': next.isEmpty ? null : next,
      }),
      failure: UiCopy.failedToUpdateNickname(),
      onSuccess: () {
        member.nickname = next.isEmpty ? null : next;
        ref
            .read(
              accordMembersControllerProvider(
                _serverKey,
                widget.spaceId,
              ).notifier,
            )
            .upsertMember(member);
      },
    );
  }

  void _toggleRole(AccordMember member, AccordRole role, bool add) {
    _run(
      (c) => add
          ? c.members.addRole(widget.spaceId, widget.userId, role.id)
          : c.members.removeRole(widget.spaceId, widget.userId, role.id),
      failure: UiCopy.failedToUpdateRoles(),
      onSuccess: () {
        final roles = [...member.roles];
        if (add) {
          if (!roles.contains(role.id)) roles.add(role.id);
        } else {
          roles.remove(role.id);
        }
        member.roles = roles;
        ref
            .read(
              accordMembersControllerProvider(
                _serverKey,
                widget.spaceId,
              ).notifier,
            )
            .upsertMember(member);
      },
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String action,
  }) {
    return showConfirmDialog(
      context,
      title: title,
      message: message,
      confirmLabel: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);

    final members = ref.watch(
      accordMembersControllerProvider(_serverKey, widget.spaceId),
    );
    final member = members?[widget.userId];
    // Backfill the target from the on-demand user cache when outside the page.
    final cachedUser = ref.watch(
      accordUsersControllerProvider(_serverKey).select((m) => m[widget.userId]),
    );
    if (member?.user == null && cachedUser == null && members != null) {
      ref
          .read(accordUsersControllerProvider(_serverKey).notifier)
          .ensure(widget.userId);
    }

    final space = ref.watch(
      spacesControllerProvider.select(
        (s) => s?.firstWhereOrNull((sp) => sp.id == widget.spaceId),
      ),
    );
    final roles = space?.roles ?? const <AccordRole>[];
    final status = ref.watch(
      activePresencesProvider.select(
        (p) => accordPresenceStatus(p, widget.userId),
      ),
    );
    final customStatus = ref.watch(
      activePresencesProvider.select(
        (p) => accordCustomStatus(p, widget.userId),
      ),
    );
    final rich = richPresenceOf(
      ref.watch(
        activePresencesProvider.select(
          (p) => p[widget.userId]?.activities,
        ),
      ),
    );
    final cdnUrl = ref.watchCdnUrl();
    final currentUserId = ref.watchUserId();

    final profileUser = _profile ?? cachedUser ?? member?.user;
    final bannerUrl = accordUserBannerUrl(_profile, cdnUrl) ??
        accordUserBannerUrl(cachedUser, cdnUrl) ??
        accordUserBannerUrl(member?.user, cdnUrl);
    final bio = profileUser?.bio?.trim();
    final name = member != null
        ? accordMemberName(member, fallback: accordUserName(cachedUser, fallback: widget.userId))
        : accordUserName(cachedUser, fallback: widget.userId);
    final username = member?.user?.username ?? cachedUser?.username;
    final avatarUrl = member != null
        ? accordMemberAvatarUrl(member, cdnUrl)
        : accordAvatarUrl(cachedUser, cdnUrl);
    final colorRole = member == null ? null : memberColorRole(member, roles);
    final nameColor =
        communityNameColor(member?.user) ??
        (colorRole == null ? null : accordRoleColor(colorRole.color));

    final perms = ref.watchAccordPermissions(space, widget.spaceId);
    final isSelf = currentUserId != null && currentUserId == widget.userId;
    // A remote (federated) user is homed on another server; local-only
    // moderation (kick/ban/timeout/roles/nickname) can't be performed on them
    // here, so those actions are suppressed regardless of local permissions.
    final remoteDomain =
        accordMemberOrigin(member) ?? accordUserOrigin(cachedUser);
    final isRemote = remoteDomain != null;
    final canKick =
        !isSelf &&
        !isRemote &&
        accordHasPermission(perms, AccordPermission.kickMembers);
    final canBan =
        !isSelf &&
        !isRemote &&
        accordHasPermission(perms, AccordPermission.banMembers);
    final canTimeout =
        !isSelf &&
        !isRemote &&
        accordHasPermission(perms, AccordPermission.moderateMembers);
    final canManageRoles =
        !isRemote && accordHasPermission(perms, AccordPermission.manageRoles);
    final canEditNickname =
        !isRemote &&
        (isSelf
            ? accordHasPermission(perms, AccordPermission.changeNickname)
            : accordHasPermission(perms, AccordPermission.manageNicknames));
    final timedOut =
        member?.timedOutUntil != null &&
        member!.timedOutUntil.toString().isNotEmpty;

    // Roles assignable in the popout: skip @everyone (position 0) and managed.
    final assignableRoles = roles
        .where((r) => r.position != 0 && !r.managed)
        .sortedBy<num>((r) => -r.position);
    final memberRoleIds = member?.roles ?? const <String>[];

    return Dialog(
      backgroundColor: colors.foreground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bannerUrl != null)
                _BannerIdentity(
                  bannerUrl: bannerUrl,
                  name: name,
                  username: username,
                  avatarUrl: avatarUrl,
                  avatarBackgroundColor: accordAvatarColor(
                    member?.user,
                    widget.userId,
                  ),
                  status: status,
                  nameColor: nameColor,
                  customStatus: customStatus,
                  remoteDomain: remoteDomain,
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _ProfileHeader(
                    name: name,
                    username: username,
                    avatarUrl: avatarUrl,
                    avatarBackgroundColor: accordAvatarColor(
                      member?.user,
                      widget.userId,
                    ),
                    status: status,
                    nameColor: nameColor,
                    customStatus: customStatus,
                    remoteDomain: remoteDomain,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              if (bio != null && bio.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(bio, style: theme.textTheme.bodyMedium),
              ],
              if (rich != null) ...[
                const SizedBox(height: 12),
                RichPresenceCard(presence: rich),
              ],
              if (timedOut) ...[
                const SizedBox(height: 12),
                _TimeoutBanner(
                  label: UiCopy.timedOutUntil(
                    context: context,
                    arg0: member.timedOutUntil,
                  ),
                ),
              ],
              if (member != null)
                _MembershipInfo(
                  member: member,
                  roles: roles,
                  memberRoleIds: memberRoleIds,
                ),
              if (canManageRoles && member != null) ...[
                const SizedBox(height: 12),
                Divider(color: colors.background, height: 1),
                _RoleEditor(
                  domainName: space?.name ?? widget.spaceId,
                  roles: assignableRoles,
                  memberRoleIds: memberRoleIds,
                  enabled: !_busy,
                  onToggle: (role, add) => _toggleRole(member, role, add),
                  onManage: () => showAccordRoleManagement(
                    context,
                    spaceId: widget.spaceId,
                  ),
                ),
              ],
              if (canKick || canBan || canTimeout) ...[
                const SizedBox(height: 16),
                Divider(color: colors.background, height: 1),
                const SizedBox(height: 12),
                _ModerationActions(
                  canKick: canKick,
                  canBan: canBan,
                  canTimeout: canTimeout,
                  timedOut: timedOut,
                  busy: _busy,
                  onKick: _kick,
                  onBan: _ban,
                  onTimeout: _timeout,
                  onRemoveTimeout: _removeTimeout,
                ),
              ],
              if (!isSelf) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => openAccordDirectMessage(
                            context,
                            ref,
                            widget.userId,
                          ),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primary,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text(UiCopy.directMessage(context: context)),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _busy ? null : _report,
                    style: TextButton.styleFrom(foregroundColor: colors.red),
                    icon: const Icon(Icons.flag_outlined, size: 18),
                    label: Text(UiCopy.reportUser(context: context)),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _busy ? null : _block,
                    style: TextButton.styleFrom(foregroundColor: colors.red),
                    icon: const Icon(Icons.block, size: 18),
                    label: Text(UiCopy.blockUser(context: context)),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                InlineError(_error!, centered: false),
              ],
              if (canEditNickname && member != null) ...[
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.badge_outlined,
                  label: (member.nickname ?? '').isEmpty
                      ? UiCopy.setNickname(context: context)
                      : UiCopy.editNickname(context: context),
                  color: colors.dirtyWhite,
                  onTap: _busy ? null : () => _editNickname(member),
                ),
              ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner across the top of the card. The avatar sits on the banner's lower
/// edge. Name, id, and presence are centered beside the avatar.
class _BannerIdentity extends StatelessWidget {
  const _BannerIdentity({
    required this.bannerUrl,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.avatarBackgroundColor,
    required this.status,
    required this.nameColor,
    required this.customStatus,
    required this.remoteDomain,
  });

  final String bannerUrl;
  final String name;
  final String? username;
  final String? avatarUrl;
  final Color avatarBackgroundColor;
  final String status;
  final Color? nameColor;
  final String? customStatus;
  final String? remoteDomain;

  static const double _radius = 28;
  static const double _ring = 3;

  @override
  Widget build(BuildContext context) {
    final avatarBox = (_radius + _ring) * 2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 360.0;
        final bannerHeight = width * 9 / 16;
        return Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: bannerHeight,
              child: UserBannerImage(
                url: bannerUrl,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: bannerHeight - avatarBox / 2,
                left: 20,
                right: 20,
              ),
              child: _ProfileHeader(
                name: name,
                username: username,
                avatarUrl: avatarUrl,
                avatarBackgroundColor: avatarBackgroundColor,
                status: status,
                nameColor: nameColor,
                customStatus: customStatus,
                remoteDomain: remoteDomain,
                bannerRing: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Avatar on the left. Name, id, and presence sit to the right, centered on
/// the avatar. Presence follows the id on the same line, after a middle dot.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.avatarBackgroundColor,
    required this.status,
    required this.nameColor,
    required this.customStatus,
    required this.remoteDomain,
    this.bannerRing = false,
  });

  final String name;
  final String? username;
  final String? avatarUrl;
  final Color avatarBackgroundColor;
  final String status;
  final Color? nameColor;
  final String? customStatus;
  final String? remoteDomain;

  /// Draws the foreground ring used when the avatar overlaps a banner.
  final bool bannerRing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    final avatar = AccordMemberAvatar(
      avatarUrl: avatarUrl,
      initial: accordInitial(name),
      status: status,
      radius: 28,
      backgroundColor: avatarBackgroundColor,
      ringColor: bannerRing ? colors.foreground : null,
    );
    final muted = theme.textTheme.bodySmall!.copyWith(color: colors.gray);
    final idLine = username == null
        ? _statusLabel(status)
        : '@$username · ${_statusLabel(status)}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (bannerRing)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.foreground,
            ),
            child: avatar,
          )
        else
          avatar,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _OutlinedName(
                text: name,
                style: theme.textTheme.titleMedium!.copyWith(color: nameColor),
              ),
              Text(
                idLine,
                style: muted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (customStatus != null) ...[
                const SizedBox(height: 2),
                Text(
                  customStatus!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: colors.dirtyWhite,
                  ),
                ),
              ],
              if (remoteDomain != null) ...[
                const SizedBox(height: 4),
                RemoteOriginBadge(domain: remoteDomain!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'online':
        return UiCopy.online();
      case 'idle':
        return UiCopy.idle();
      case 'dnd':
        return UiCopy.doNotDisturb();
      default:
        return UiCopy.offline();
    }
  }
}

/// Display name with a thin black stroke so a role color still reads.
class _OutlinedName extends StatelessWidget {
  const _OutlinedName({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF000000);
    return Stack(
      children: [
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(foreground: stroke),
        ),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ],
    );
  }
}

/// The amber "Timed out until …" pill shown while a member is timed out.
class _TimeoutBanner extends StatelessWidget {
  const _TimeoutBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAA81A).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFFAA81A)),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

/// The read-only membership facts: "Member since" date and the member's
/// current role chips.
class _MembershipInfo extends StatelessWidget {
  const _MembershipInfo({
    required this.member,
    required this.roles,
    required this.memberRoleIds,
  });

  final AccordMember member;
  final List<AccordRole> roles;
  final List<String> memberRoleIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (member.joinedAt.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            UiCopy.memberSince(context: context, arg0: _date(member.joinedAt)),
            style: theme.textTheme.bodySmall!.copyWith(color: colors.gray),
          ),
        ],
        if (memberRoleIds.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final id in memberRoleIds)
                if (roles.firstWhereOrNull((r) => r.id == id) case final role?)
                  _RoleChip(role: role),
            ],
          ),
        ],
      ],
    );
  }

  String _date(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final AccordRole role;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final color = accordRoleColor(role.color) ?? colors.dirtyWhite;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            role.name,
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: colors.dirtyWhite),
          ),
        ],
      ),
    );
  }
}

class _RoleEditor extends StatelessWidget {
  const _RoleEditor({
    required this.domainName,
    required this.roles,
    required this.memberRoleIds,
    required this.enabled,
    required this.onToggle,
    required this.onManage,
  });

  final String domainName;
  final List<AccordRole> roles;
  final List<String> memberRoleIds;
  final bool enabled;
  final void Function(AccordRole role, bool add) onToggle;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              UiCopy.assignRoles(context: context),
              style: theme.textTheme.labelSmall!.copyWith(
                color: colors.gray,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              tooltip: AppStrings.choose(
                'Open role settings',
                '打开权限分配',
                context: context,
              ),
              onPressed: enabled ? onManage : null,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: Icon(Icons.add, size: 18, color: colors.dirtyWhite),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.choose('Only applies within $domainName', '仅对「$domainName」域生效', context: context),
          style: theme.textTheme.bodySmall?.copyWith(color: colors.gray),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final role in roles)
              FilterChip(
                label: Text(role.name),
                selected: memberRoleIds.contains(role.id),
                onSelected: enabled ? (value) => onToggle(role, value) : null,
                showCheckmark: true,
              ),
          ],
        ),
      ],
    );
  }
}

class _ModerationActions extends StatelessWidget {
  const _ModerationActions({
    required this.canKick,
    required this.canBan,
    required this.canTimeout,
    required this.timedOut,
    required this.busy,
    required this.onKick,
    required this.onBan,
    required this.onTimeout,
    required this.onRemoveTimeout,
  });

  final bool canKick;
  final bool canBan;
  final bool canTimeout;
  final bool timedOut;
  final bool busy;
  final VoidCallback onKick;
  final VoidCallback onBan;
  final ValueChanged<int> onTimeout;
  final VoidCallback onRemoveTimeout;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canTimeout)
          PopupMenuButton<int>(
            enabled: !busy,
            tooltip: UiCopy.timeOut(context: context),
            onSelected: onTimeout,
            itemBuilder: (context) => [
              for (final (label, seconds) in _timeoutDurations(context))
                PopupMenuItem(value: seconds, child: Text(label)),
            ],
            child: _ActionRow(
              icon: Icons.timer_outlined,
              label: UiCopy.timeOut2(context: context),
              color: const Color(0xFFFAA81A),
            ),
          ),
        if (canTimeout && timedOut)
          _ActionTile(
            icon: Icons.timer_off_outlined,
            label: UiCopy.removeTimeout(context: context),
            color: colors.dirtyWhite,
            onTap: busy ? null : onRemoveTimeout,
          ),
        if (canKick)
          _ActionTile(
            icon: Icons.exit_to_app,
            label: UiCopy.kickMember(context: context),
            color: const Color(0xFFFAA81A),
            onTap: busy ? null : onKick,
          ),
        if (canBan)
          _ActionTile(
            icon: Icons.gavel,
            label: UiCopy.banMember(context: context),
            color: colors.red,
            onTap: busy ? null : onBan,
          ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: _ActionRow(icon: icon, label: label, color: color),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
