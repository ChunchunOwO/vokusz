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
import 'package:bonfire/features/user/views/accord_profile_edit.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    final assignableIds = {for (final role in assignableRoles) role.id};
    // The member's roles highest first, as the roster groups them.
    final memberRoles = [
      for (final id in memberRoleIds)
        if (roles.firstWhereOrNull((r) => r.id == id) case final role?) role,
    ].sortedBy<num>((r) => -r.position);
    final addableRoles = [
      for (final role in assignableRoles)
        if (!memberRoleIds.contains(role.id)) role,
    ];
    final joinedAt = member?.joinedAt ?? '';
    final bodyStyle = theme.textTheme.bodyMedium!.copyWith(
      color: colors.dirtyWhite,
      height: 1.45,
    );

    // The quiet facts, grouped on one recessed panel.
    final details = <Widget>[
      if (bio != null && bio.isNotEmpty)
        _Section(
          label: UiCopy.bio(context: context),
          child: Text(bio, style: bodyStyle),
        ),
      if (joinedAt.isNotEmpty)
        _Section(
          label: AppStrings.choose('Member since', '加入本域', context: context),
          child: Row(
            children: [
              Icon(Icons.event_outlined, size: 16, color: colors.gray),
              const SizedBox(width: 8),
              Text(_formatDate(joinedAt), style: bodyStyle),
            ],
          ),
        ),
      if (member != null && (memberRoles.isNotEmpty || canManageRoles))
        _Section(
          label: UiCopy.roles(context: context),
          trailing: canManageRoles
              ? _TinyIconButton(
                  icon: Icons.tune,
                  tooltip: AppStrings.choose(
                    'Open role settings',
                    '打开权限分配',
                    context: context,
                  ),
                  onPressed: _busy
                      ? null
                      : () => showAccordRoleManagement(
                          context,
                          spaceId: widget.spaceId,
                        ),
                )
              : null,
          child: _RoleList(
            roles: memberRoles,
            addable: canManageRoles ? addableRoles : const [],
            removable: canManageRoles ? assignableIds : const {},
            enabled: !_busy,
            onAdd: (role) => _toggleRole(member, role, true),
            onRemove: (role) => _toggleRole(member, role, false),
            hint: canManageRoles
                ? AppStrings.choose(
                    'Only applies within ${space?.name ?? widget.spaceId}',
                    '仅对「${space?.name ?? widget.spaceId}」域生效',
                    context: context,
                  )
                : null,
          ),
        ),
    ];

    final body = <Widget>[
      if (customStatus != null) _StatusBubble(text: customStatus),
      if (timedOut)
        _TimeoutBanner(
          label: UiCopy.timedOutUntil(
            context: context,
            arg0: _formatDate(member.timedOutUntil.toString(), withTime: true),
          ),
          onRemove: canTimeout && !_busy ? _removeTimeout : null,
        ),
      if (rich != null) RichPresenceCard(presence: rich),
      if (details.isNotEmpty) _DetailsPanel(children: details),
      if (canKick || canBan || canTimeout)
        _Section(
          label: AppStrings.choose('Moderation', '成员管理', context: context),
          child: _ModerationActions(
            canKick: canKick,
            canBan: canBan,
            canTimeout: canTimeout,
            busy: _busy,
            onKick: _kick,
            onBan: _ban,
            onTimeout: _timeout,
          ),
        ),
      if (_error != null) InlineError(_error!, centered: false),
      _ProfileActions(
        isSelf: isSelf,
        busy: _busy,
        onMessage: () => openAccordDirectMessage(context, ref, widget.userId),
        onReport: _report,
        onBlock: _block,
        onEditProfile: () async {
          await showAccordProfileEdit(context);
          // The editor writes the user cache, but this card prefers its own
          // fetched copy — refetch so the edit shows here too.
          if (mounted) unawaited(_refreshProfile());
        },
      ),
    ];

    // The user's chosen colour: their imageless avatar and, without a banner,
    // the band across the top.
    final accent = accordAvatarColor(profileUser, widget.userId);

    return _PopIn(
      child: Dialog(
        backgroundColor: colors.sheet,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: colors.hairline),
        ),
        child: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            // The live profile lands after the card opens and can add a banner
            // or a bio: grow into it rather than jump.
            child: AnimatedSize(
              duration: AppMotion.of(context, AppMotion.medium),
              curve: AppMotion.curve,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHero(
                    bannerUrl: bannerUrl,
                    accent: accent,
                    name: name,
                    nameColor: nameColor,
                    username: username,
                    status: status,
                    avatarUrl: avatarUrl,
                    avatarBackgroundColor: accent,
                    remoteDomain: remoteDomain,
                    editNicknameLabel: member == null || !canEditNickname
                        ? null
                        : (member.nickname ?? '').isEmpty
                        ? UiCopy.setNickname(context: context)
                        : UiCopy.editNickname(context: context),
                    onEditNickname: member == null || !canEditNickname || _busy
                        ? null
                        : () => _editNickname(member),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _spaced(body, 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scales the card in as its route fades in, so it settles into place rather
/// than just appearing.
class _PopIn extends StatelessWidget {
  const _PopIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: AppMotion.of(context, AppMotion.medium),
      curve: AppMotion.curve,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}

List<Widget> _spaced(List<Widget> children, double gap) => [
  for (var i = 0; i < children.length; i++) ...[
    if (i > 0) SizedBox(height: gap),
    children[i],
  ],
];

/// `2025-11-02`, or `2025-11-02 18:30` with [withTime], in local time. Falls
/// back to the raw value when it isn't a timestamp.
String _formatDate(String iso, {bool withTime = false}) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  final local = parsed.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  final date = '${local.year}-${two(local.month)}-${two(local.day)}';
  return withTime ? '$date ${two(local.hour)}:${two(local.minute)}' : date;
}

/// Amber for timeouts and kicks: the palette's yellow is a fill colour and too
/// pale to read as text on the light theme.
Color _amber(BonfireThemeExtension colors) =>
    colors.isLight ? const Color(0xFFB86E00) : const Color(0xFFFAA81A);

/// Opens a menu just below [anchor], left-aligned with it.
Future<T?> _showMenuBelow<T>(
  BuildContext anchor,
  List<PopupMenuEntry<T>> items,
) {
  final box = anchor.findRenderObject()! as RenderBox;
  final overlay =
      Navigator.of(anchor).overlay!.context.findRenderObject()! as RenderBox;
  final offset = Offset(0, box.size.height + 4);
  final rect = Rect.fromPoints(
    box.localToGlobal(offset, ancestor: overlay),
    box.localToGlobal(box.size.bottomRight(offset), ancestor: overlay),
  );
  return showMenu<T>(
    context: anchor,
    position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
    items: items,
  );
}

/// The top of the card: the banner — or, without one, a band in the user's
/// accent colour — with the avatar set into its lower edge and the name, id
/// and presence beside the avatar, below the banner.
class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.bannerUrl,
    required this.accent,
    required this.name,
    required this.nameColor,
    required this.username,
    required this.status,
    required this.avatarUrl,
    required this.avatarBackgroundColor,
    required this.remoteDomain,
    required this.editNicknameLabel,
    required this.onEditNickname,
  });

  final String? bannerUrl;
  final Color accent;
  final String name;
  final Color? nameColor;
  final String? username;
  final String status;
  final String? avatarUrl;
  final Color avatarBackgroundColor;
  final String? remoteDomain;

  /// Tooltip for the pencil beside the name; null hides the pencil.
  final String? editNicknameLabel;
  final VoidCallback? onEditNickname;

  static const double _avatarRadius = 40;
  static const double _ring = 5;
  static const double _avatarBox = (_avatarRadius + _ring) * 2;
  static const double _bandHeight = 96;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 380.0;
        // An uploaded banner keeps the 16:9 frame it was cropped to.
        final bannerHeight = bannerUrl == null ? _bandHeight : width * 9 / 16;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: bannerHeight,
                  child: _HeroBanner(
                    url: bannerUrl,
                    accent: accent,
                    width: width,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16 + _avatarBox + 12,
                    right: 12,
                    top: 4,
                  ),
                  // Centred on the half of the avatar below the banner.
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: _avatarBox / 2 - 4,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                    color: nameColor ?? colors.emphasis,
                                    // Keeps a dark role colour legible on the
                                    // dark sheet; on light it would only smudge.
                                    shadows: colors.isLight
                                        ? null
                                        : const [
                                            Shadow(
                                              color: Color(0x80000000),
                                              blurRadius: 3,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                  ),
                                ),
                              ),
                              if (editNicknameLabel != null) ...[
                                const SizedBox(width: 4),
                                _TinyIconButton(
                                  icon: Icons.edit_outlined,
                                  tooltip: editNicknameLabel!,
                                  onPressed: onEditNickname,
                                  size: 24,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            username == null
                                ? _statusLabel(context, status)
                                : '@$username · '
                                      '${_statusLabel(context, status)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: colors.gray,
                            ),
                          ),
                          if (remoteDomain != null) ...[
                            const SizedBox(height: 4),
                            RemoteOriginBadge(domain: remoteDomain!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 16,
              top: bannerHeight - _avatarBox / 2,
              child: Container(
                padding: const EdgeInsets.all(_ring),
                decoration: BoxDecoration(
                  color: colors.sheet,
                  shape: BoxShape.circle,
                ),
                child: AccordMemberAvatar(
                  avatarUrl: avatarUrl,
                  initial: accordInitial(name),
                  status: status,
                  radius: _avatarRadius,
                  backgroundColor: avatarBackgroundColor,
                  ringColor: colors.sheet,
                  initialStyle: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'online':
        return UiCopy.online(context: context);
      case 'idle':
        return UiCopy.idle(context: context);
      case 'dnd':
        return UiCopy.doNotDisturb(context: context);
      default:
        return UiCopy.offline(context: context);
    }
  }
}

/// The banner image over the accent band, which shows while it loads and
/// stays if it fails.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.url,
    required this.accent,
    required this.width,
  });

  final String? url;
  final Color accent;
  final double width;

  @override
  Widget build(BuildContext context) {
    final band = AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.medium),
      curve: AppMotion.curve,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(accent, Colors.white, 0.08)!,
            Color.lerp(accent, Colors.black, 0.18)!,
          ],
        ),
      ),
      // A soft highlight in one corner, so the band has some depth rather
      // than reading as a flat swatch.
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.85, -1.4),
            radius: 1.3,
            colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
          ),
        ),
      ),
    );
    final url = this.url;
    if (url == null) return band;
    return Stack(
      fit: StackFit.expand,
      children: [
        band,
        CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          memCacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
              .ceil(),
          fadeInDuration: AppMotion.of(context, AppMotion.medium),
          placeholder: (_, _) => const SizedBox.shrink(),
          errorWidget: (_, _, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// A custom status as a speech bubble pointing up at the name.
class _StatusBubble extends StatelessWidget {
  const _StatusBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.inset,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xs),
            topRight: Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(AppRadius.lg),
            bottomRight: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: colors.dirtyWhite),
        ),
      ),
    );
  }
}

/// The amber notice shown while a member is timed out, with the way out of it
/// for a moderator.
class _TimeoutBanner extends StatelessWidget {
  const _TimeoutBanner({required this.label, required this.onRemove});

  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final amber = _amber(colors);
    return Container(
      padding: EdgeInsets.fromLTRB(12, 6, onRemove == null ? 12 : 4, 6),
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 18, color: amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: colors.dirtyWhite),
            ),
          ),
          if (onRemove != null)
            TextButton(
              onPressed: onRemove,
              style: TextButton.styleFrom(
                foregroundColor: amber,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(UiCopy.removeTimeout(context: context)),
            ),
        ],
      ),
    );
  }
}

/// The recessed panel holding the profile's read-only sections.
class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.inset,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _spaced(children, 16),
        ),
      ),
    );
  }
}

/// A small-caps label over its content, with an optional control at the end of
/// the label row.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child, this.trailing});

  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 20,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: colors.gray,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// A borderless icon button sized to sit inside a line of text.
class _TinyIconButton extends StatelessWidget {
  const _TinyIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 20,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      style: IconButton.styleFrom(
        foregroundColor: colors.gray,
        hoverColor: colors.hoverFill,
        padding: EdgeInsets.zero,
        minimumSize: Size.square(size),
        maximumSize: Size.square(size),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}

/// The member's roles as chips — removable where the viewer may assign them —
/// followed by an "Add" chip listing the roles they don't have yet.
class _RoleList extends StatelessWidget {
  const _RoleList({
    required this.roles,
    required this.addable,
    required this.removable,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
    required this.hint,
  });

  final List<AccordRole> roles;
  final List<AccordRole> addable;
  final Set<String> removable;
  final bool enabled;
  final ValueChanged<AccordRole> onAdd;
  final ValueChanged<AccordRole> onRemove;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final role in roles)
              _RoleChip(
                role: role,
                onRemove: removable.contains(role.id)
                    ? (enabled ? () => onRemove(role) : null)
                    : null,
                removable: removable.contains(role.id),
              ),
            if (addable.isNotEmpty)
              _AddRoleChip(roles: addable, onAdd: enabled ? onAdd : null),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(
            hint!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: colors.gray),
          ),
        ],
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.role,
    required this.onRemove,
    required this.removable,
  });

  final AccordRole role;
  final VoidCallback? onRemove;

  /// Whether to show the remove control at all; [onRemove] being null while
  /// this is true just means it is disabled for now.
  final bool removable;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final color = accordRoleColor(role.color) ?? colors.gray;
    return Container(
      height: 26,
      padding: EdgeInsets.only(left: 9, right: removable ? 3 : 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: colors.isLight ? 0.12 : 0.16),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: colors.dirtyWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (removable) ...[
            const SizedBox(width: 2),
            Tooltip(
              message: AppStrings.choose(
                'Remove role',
                '移除权限组',
                context: context,
              ),
              child: InkResponse(
                onTap: onRemove,
                radius: 11,
                child: SizedBox.square(
                  dimension: 20,
                  child: Icon(Icons.close, size: 13, color: colors.gray),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The "+ Add" chip: a menu of the assignable roles the member lacks.
class _AddRoleChip extends StatelessWidget {
  const _AddRoleChip({required this.roles, required this.onAdd});

  final List<AccordRole> roles;
  final ValueChanged<AccordRole>? onAdd;

  Future<void> _pick(BuildContext context) async {
    final colors = BonfireThemeExtension.of(context);
    final role = await _showMenuBelow<AccordRole>(context, [
      for (final role in roles)
        PopupMenuItem(
          value: role,
          height: 40,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accordRoleColor(role.color) ?? colors.gray,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(child: Text(role.name, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
    ]);
    if (role != null) onAdd?.call(role);
  }

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final shape = StadiumBorder(
      side: BorderSide(color: colors.gray.withValues(alpha: 0.45)),
    );
    return Tooltip(
      message: AppStrings.choose('Add role', '添加权限组', context: context),
      child: Material(
        color: Colors.transparent,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onAdd == null ? null : () => _pick(context),
          child: SizedBox(
            height: 26,
            child: Padding(
              padding: const EdgeInsets.only(left: 6, right: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 15, color: colors.gray),
                  const SizedBox(width: 3),
                  Text(
                    AppStrings.choose('Add', '添加', context: context),
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: colors.gray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Time out / kick / ban as a row of equal tinted buttons.
class _ModerationActions extends StatelessWidget {
  const _ModerationActions({
    required this.canKick,
    required this.canBan,
    required this.canTimeout,
    required this.busy,
    required this.onKick,
    required this.onBan,
    required this.onTimeout,
  });

  final bool canKick;
  final bool canBan;
  final bool canTimeout;
  final bool busy;
  final VoidCallback onKick;
  final VoidCallback onBan;
  final ValueChanged<int> onTimeout;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final amber = _amber(colors);
    final buttons = <Widget>[
      if (canTimeout)
        Builder(
          builder: (anchor) => _ToneButton(
            icon: Icons.timer_outlined,
            label: UiCopy.timeOut(context: context),
            color: amber,
            dropdown: true,
            onPressed: busy
                ? null
                : () async {
                    final seconds = await _showMenuBelow<int>(anchor, [
                      for (final (label, seconds) in _timeoutDurations(context))
                        PopupMenuItem(value: seconds, child: Text(label)),
                    ]);
                    if (seconds != null) onTimeout(seconds);
                  },
          ),
        ),
      if (canKick)
        _ToneButton(
          icon: Icons.exit_to_app,
          label: AppStrings.choose('Kick', '移出', context: context),
          tooltip: UiCopy.kickMember(context: context),
          color: amber,
          onPressed: busy ? null : onKick,
        ),
      if (canBan)
        _ToneButton(
          icon: Icons.gavel,
          label: AppStrings.choose('Ban', '封禁', context: context),
          tooltip: UiCopy.banMember(context: context),
          color: colors.red,
          onPressed: busy ? null : onBan,
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Side by side while each still fits its label; stacked on a phone.
        if (constraints.maxWidth / buttons.length >= 100) {
          return Row(
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: buttons[i]),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _spaced(buttons, 8),
        );
      },
    );
  }
}

/// A button filled with a wash of its own colour.
class _ToneButton extends StatelessWidget {
  const _ToneButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.tooltip,
    this.dropdown = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final String? tooltip;

  /// Adds a chevron for a button that opens a menu.
  final bool dropdown;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final fg = onPressed == null ? colors.gray : color;
    final radius = BorderRadius.circular(AppRadius.md);
    Widget button = Material(
      color: fg.withValues(alpha: 0.12),
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        hoverColor: fg.withValues(alpha: 0.10),
        splashColor: fg.withValues(alpha: 0.16),
        highlightColor: fg.withValues(alpha: 0.08),
        child: SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
                if (dropdown) Icon(Icons.expand_more, size: 16, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
    final tooltip = this.tooltip;
    if (tooltip != null) button = Tooltip(message: tooltip, child: button);
    return button;
  }
}

/// The card's footer: message (or, on your own card, edit profile) as the
/// primary action, with report and block one tap away beside it.
class _ProfileActions extends StatelessWidget {
  const _ProfileActions({
    required this.isSelf,
    required this.busy,
    required this.onMessage,
    required this.onReport,
    required this.onBlock,
    required this.onEditProfile,
  });

  final bool isSelf;
  final bool busy;
  final VoidCallback onMessage;
  final VoidCallback onReport;
  final VoidCallback onBlock;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final style = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: isSelf
                ? FilledButton.icon(
                    style: style,
                    onPressed: busy ? null : onEditProfile,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(UiCopy.editProfile(context: context)),
                  )
                : FilledButton.icon(
                    style: style,
                    onPressed: busy ? null : onMessage,
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text(UiCopy.directMessage(context: context)),
                  ),
          ),
          if (!isSelf) ...[
            const SizedBox(width: 8),
            _QuietIconButton(
              icon: Icons.flag_outlined,
              tooltip: UiCopy.reportUser(context: context),
              color: colors.red,
              onPressed: busy ? null : onReport,
            ),
            const SizedBox(width: 8),
            _QuietIconButton(
              icon: Icons.block,
              tooltip: UiCopy.blockUser(context: context),
              color: colors.red,
              onPressed: busy ? null : onBlock,
            ),
          ],
        ],
      ),
    );
  }
}

/// An outlined square icon button that takes on [color] when hovered.
class _QuietIconButton extends StatelessWidget {
  const _QuietIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      style: ButtonStyle(
        fixedSize: const WidgetStatePropertyAll(Size.square(40)),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.hovered)
                ? color.withValues(alpha: 0.5)
                : colors.hairline,
          ),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.gray.withValues(alpha: 0.5);
          }
          return states.contains(WidgetState.hovered) ? color : colors.gray;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return color.withValues(alpha: 0.16);
          }
          if (states.contains(WidgetState.hovered)) {
            return color.withValues(alpha: 0.10);
          }
          return null;
        }),
      ),
    );
  }
}
