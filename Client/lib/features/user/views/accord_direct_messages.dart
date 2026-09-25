import 'dart:async';

import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/l10n/ui_copy.dart';
import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/member/utils/member_display.dart';
import 'package:bonfire/features/member/views/user_banner.dart';
import 'package:bonfire/features/channels/controllers/read_state.dart';
import 'package:bonfire/features/channels/utils/mark_channel_read.dart';
import 'package:bonfire/features/messaging/controllers/accord_messages.dart';
import 'package:bonfire/features/messaging/views/message_pane/message_pane.dart';
import 'package:bonfire/features/settings/controllers/settings.dart';
import 'package:bonfire/shared/components/async_state_views.dart';
import 'package:bonfire/shared/components/context_menu.dart';
import 'package:bonfire/shared/components/user_avatar.dart';
import 'package:bonfire/shared/utils/confirm_dialog.dart';
import 'package:bonfire/shared/utils/client_access.dart';
import 'package:bonfire/shared/utils/responsive_dialog.dart';
import 'package:bonfire/shared/utils/rest_result_ext.dart';
import 'package:bonfire/shared/utils/text_prompt_dialog.dart';
import 'package:bonfire/features/channels/controllers/dm_channels.dart';
import 'package:bonfire/features/member/views/remote_origin_badge.dart';
import 'package:bonfire/features/user/controllers/accord_users.dart';
import 'package:bonfire/features/user/controllers/blocked_users.dart';
import 'package:bonfire/features/user/controllers/relationship_epoch.dart';
import 'package:bonfire/features/voice/controllers/call.dart';
import 'package:bonfire/features/voice/controllers/missed_calls.dart';
import 'package:bonfire/features/voice/controllers/voice.dart';
import 'package:bonfire/features/voice/views/voice_pip_overlay.dart';
import 'package:bonfire/features/voice/views/voice_view.dart';
import 'package:bonfire/features/spaces/views/accord_reports.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'accord_direct_messages_conversations.dart';
part 'accord_direct_messages_friends.dart';
part 'accord_direct_messages_groups.dart';
part 'accord_direct_messages_user_search.dart';

/// Relationship type enum mirrored from the server: 1 = friend, 2 = blocked,
/// 3 = pending incoming, 4 = pending outgoing.
class _Rel {
  static const friend = 1;
  static const blocked = 2;
  static const pendingIn = 3;
  static const pendingOut = 4;
}

/// Best display name for a user, falling back to the raw id rather than
/// "Unknown" so an unhydrated recipient stays identifiable (and reportable).
String _userName(AccordUser? user) =>
    user == null ? UiCopy.unknown() : accordUserName(user, fallback: user.id);

/// The recipients of [channel] excluding the current user.
List<AccordUser> _others(AccordChannel channel, String? selfId) =>
    (channel.recipients ?? const <AccordUser>[])
        .where((u) => u.id != selfId)
        .toList();

/// The home domain of a 1:1 DM's remote participant, or null for a local DM or
/// a group. Drives the federated-origin badge so a cross-server DM is visually
/// distinguishable from a same-server one.
String? _dmRemoteOrigin(AccordChannel channel, String? selfId) {
  final others = _others(channel, selfId);
  if (others.length != 1) return null;
  return accordUserOrigin(others.first);
}

/// Whether [channel] is a group DM (3+ participants). Accord types DM channels
/// as `dm` (1:1) or `group_dm`; we also fall back to the recipient count since
/// some payloads omit the type.
bool _isGroup(AccordChannel channel, String? selfId) =>
    channel.type == 'group_dm' || _others(channel, selfId).length > 1;

/// Title for a DM/group channel: a group's custom name, else the joined
/// recipient names.
String _channelTitle(AccordChannel channel, String? selfId) =>
    dmChannelTitle(channel, selfId, fallback: UiCopy.directMessage2());

/// Opens the direct-messages & friends panel: a tabbed dialog with the user's DM
/// conversations and their friends list (with requests). The Accord analogue of
/// the reference client's `dm_list` + `friends_list`. Pass [initialChannel] to
/// open straight into a conversation.
Future<void> showAccordDirectMessages(
  BuildContext context, {
  AccordChannel? initialChannel,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DirectMessagesDialog(initialChannel: initialChannel),
  );
}

/// Opens (creating if needed) the 1:1 direct message with [userId] and shows the
/// DM dialog focused on that conversation. Accord's `createDm` is idempotent for
/// a single recipient — it returns the existing DM when one already exists.
///
/// A **qualified** [userId] (`<snowflake>@<domain>`) opens a *cross-server* DM:
/// the server picks a deterministic home server and mirrors a replica DM channel
/// for us, returned with a qualified channel ID. A bare id is a same-server DM.
Future<void> openAccordDirectMessage(
  BuildContext context,
  WidgetRef ref,
  String userId,
) async {
  final client = ref.accordClient;
  final serverKey = ref.readActiveServerKey();
  if (client == null || serverKey == null) return;
  final result = await client.users.createDm(dmCreateBody(userId));
  if (!context.mounted || ref.readActiveServerKey() != serverKey) return;
  final data = result.data;
  if (result.ok && data is AccordChannel) {
    ref.read(dmChannelsControllerProvider(serverKey).notifier).upsert(data);
    await showAccordDirectMessages(context, initialChannel: data);
  } else {
    // Surface the server's reason (federation disabled, recipient not
    // qualified, peer untrusted, recipient blocked, …) rather than a generic
    // failure, so a rejected cross-server open is actionable.
    showInfoSnack(
      context,
      result.errorMessageOr(UiCopy.failedToOpenDirectMessage(context: context)),
    );
  }
}

/// Account-level profile used where there is no space/member context. It keeps
/// DM author and recipient interactions useful without pretending that a DM
/// user has space roles, nicknames, or moderation controls.
///
/// This is where a tap on a DM author lands — the member popout is space-scoped
/// and unreachable there — so it carries the same Report and Block actions the
/// popout offers. Without them a reviewer tapping a DM user found a dead end
/// (App Review 1.2, #290).
Future<void> showAccordUserProfile(
  BuildContext context,
  AccordUser user, {
  String? cdnUrl,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _UserProfileDialog(
      user: user,
      cdnUrl: cdnUrl,
      onClose: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

/// Account profile card. Loads the live user so a banner set after this
/// conversation was opened still shows. The copy passed in is often stale.
class _UserProfileDialog extends ConsumerStatefulWidget {
  const _UserProfileDialog({
    required this.user,
    required this.cdnUrl,
    required this.onClose,
  });

  final AccordUser user;
  final String? cdnUrl;
  final VoidCallback onClose;

  @override
  ConsumerState<_UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends ConsumerState<_UserProfileDialog> {
  late AccordUser _user = widget.user;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final client = ref.accordClient;
    if (client == null) return;
    final result = await client.users.fetch(widget.user.id);
    if (!mounted) return;
    final user = result.data;
    if (user is! AccordUser) return;
    final serverKey = ref.readActiveServerKey() ?? '';
    final users = ref.read(accordUsersControllerProvider(serverKey).notifier);
    evictUserMedia(users.cached(user.id), user, widget.cdnUrl);
    users.upsert(user);
    setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final user = _user;
    final name = _userName(user);
    final origin = accordUserOrigin(user);
    final bannerUrl = accordUserBannerUrl(user, widget.cdnUrl);
    final bio = user.bio?.trim();
    final isSelf = user.id == ref.watchUserId();
    return AlertDialog(
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  name,
                  imageUrl: accordAvatarUrl(user, widget.cdnUrl),
                  radius: 30,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (user.username.isNotEmpty) Text('@${user.username}'),
                      const SizedBox(height: 8),
                      SelectableText(user.id),
                      if (origin != null) ...[
                        const SizedBox(height: 8),
                        RemoteOriginBadge(domain: origin),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (bannerUrl != null) ...[
              const SizedBox(height: 12),
              UserBannerImage(url: bannerUrl),
            ],
            if (bio != null && bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(bio, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
      actions: [
        if (!isSelf) ...[
          TextButton(
            onPressed: () => showReportDialog(
              context,
              targetType: 'user',
              targetId: user.id,
              reportedUserId: user.id,
              reportedName: name,
            ),
            style: TextButton.styleFrom(foregroundColor: colors.red),
            child: Text(UiCopy.reportUser(context: context)),
          ),
          TextButton(
            onPressed: () => _blockDmUser(context, ref, user),
            style: TextButton.styleFrom(foregroundColor: colors.red),
            child: Text(UiCopy.block(context: context)),
          ),
        ],
        TextButton(
          onPressed: widget.onClose,
          child: Text(UiCopy.close(context: context)),
        ),
      ],
    );
  }
}

/// Responsive right-click/long-press menu for users shown in DMs. Relationship
/// state is fetched when the menu opens so the action is accurate even when the
/// Friends tab has not been visited this session.
Future<void> showAccordDmUserContextMenu(
  BuildContext context,
  WidgetRef ref,
  AccordUser user, {
  Offset? globalPosition,
  String? currentDmUserId,
  List<AccordMenuEntry> extraEntries = const [],
}) async {
  final client = ref.accordClient;
  final selfId = ref.readUserId();
  AccordRelationship? relationship;
  if (client != null && user.id != selfId) {
    final result = await client.users.listRelationships();
    final data = result.data;
    if (data is List) {
      for (final item in data.whereType<AccordRelationship>()) {
        if (item.user?.id == user.id) {
          relationship = item;
          break;
        }
      }
    }
  }
  if (!context.mounted) return;

  final rel = relationship;
  final entries = <AccordMenuEntry>[
    AccordMenuEntry(
      label: UiCopy.viewProfile2(context: context),
      icon: Icons.account_circle_outlined,
      onSelected: () =>
          showAccordUserProfile(context, user, cdnUrl: ref.readCdnUrl()),
    ),
    if (user.id != selfId && user.id != currentDmUserId)
      AccordMenuEntry(
        label: UiCopy.directMessage2(context: context),
        icon: Icons.chat_bubble_outline,
        onSelected: () => openAccordDirectMessage(context, ref, user.id),
      ),
    if (user.id != selfId) ...[
      AccordMenuEntry(
        label: switch (rel?.type) {
          _Rel.friend => UiCopy.removeFriend(context: context),
          _Rel.blocked => UiCopy.unblock(context: context),
          _Rel.pendingIn => UiCopy.acceptFriendRequest(context: context),
          _Rel.pendingOut => UiCopy.cancelFriendRequest(context: context),
          _ => UiCopy.addFriend(context: context),
        },
        icon: switch (rel?.type) {
          _Rel.friend => Icons.person_remove_outlined,
          _Rel.blocked => Icons.lock_open_outlined,
          _Rel.pendingIn => Icons.person_add_alt_1,
          _Rel.pendingOut => Icons.person_remove_outlined,
          _ => Icons.person_add_outlined,
        },
        destructive: rel?.type == _Rel.friend,
        onSelected: () => _changeDmRelationship(context, ref, user, rel?.type),
      ),
      AccordMenuEntry(
        label: UiCopy.reportUser(context: context),
        icon: Icons.flag_outlined,
        destructive: true,
        onSelected: () => showReportDialog(
          context,
          targetType: 'user',
          targetId: user.id,
          reportedUserId: user.id,
          reportedName: _userName(user),
        ),
      ),
      if (rel?.type != _Rel.blocked)
        AccordMenuEntry(
          label: UiCopy.block(context: context),
          icon: Icons.block,
          destructive: true,
          onSelected: () => _blockDmUser(context, ref, user),
        ),
    ],
    const AccordMenuEntry.divider(),
    AccordMenuEntry(
      label: UiCopy.copyUserId2(context: context),
      icon: Icons.copy_outlined,
      onSelected: () => Clipboard.setData(ClipboardData(text: user.id)),
    ),
    if (user.username.isNotEmpty)
      AccordMenuEntry(
        label: UiCopy.copyUsername2(context: context),
        icon: Icons.alternate_email,
        onSelected: () => Clipboard.setData(ClipboardData(text: user.username)),
      ),
    ...extraEntries,
  ];
  await showAccordContextMenu(
    context,
    entries: entries,
    globalPosition: globalPosition,
    title: _userName(user),
    titleIcon: Icons.person_outline,
  );
}

Future<void> _changeDmRelationship(
  BuildContext context,
  WidgetRef ref,
  AccordUser user,
  int? currentType,
) async {
  final client = ref.accordClient;
  if (client == null) return;
  final removing =
      currentType == _Rel.friend ||
      currentType == _Rel.blocked ||
      currentType == _Rel.pendingOut;
  final result = removing
      ? await client.users.deleteRelationship(user.id)
      : await client.users.putRelationship(user.id, {'type': _Rel.friend});
  // An unblock has to lift the message filter as promptly as the block applied
  // it, or their messages stay hidden until the next relationship fetch.
  if (result.ok && currentType == _Rel.blocked) {
    ref.blockedUsers.unblock(user.id);
  }
  if (!context.mounted) return;
  showInfoSnack(
    context,
    result.ok
        ? switch (currentType) {
            _Rel.friend => UiCopy.friendRemoved(context: context),
            _Rel.blocked => UiCopy.userUnblocked(context: context),
            _Rel.pendingIn => UiCopy.friendRequestAccepted(context: context),
            _Rel.pendingOut => UiCopy.friendRequestCancelled(context: context),
            _ => UiCopy.friendRequestSent(context: context),
          }
        : UiCopy.failedToUpdateRelationship(context: context),
  );
}

Future<void> _blockDmUser(
  BuildContext context,
  WidgetRef ref,
  AccordUser user,
) async {
  final confirmed = await showConfirmDialog(
    context,
    title: UiCopy.blockUser(context: context),
    message: UiCopy.blockedUsersCannotDmYouAndTheir(context: context),
    confirmLabel: UiCopy.block(context: context),
    danger: true,
  );
  if (confirmed != true || !context.mounted) return;
  final result = await ref.accordClient?.users.putRelationship(user.id, {
    'type': _Rel.blocked,
  });
  if (result?.ok == true) ref.blockedUsers.block(user.id);
  if (!context.mounted) return;
  showInfoSnack(
    context,
    result?.ok == true
        ? UiCopy.userBlocked(context: context)
        : UiCopy.failedToBlockUser(context: context),
  );
}

class _DirectMessagesDialog extends ConsumerStatefulWidget {
  const _DirectMessagesDialog({this.initialChannel});

  final AccordChannel? initialChannel;

  @override
  ConsumerState<_DirectMessagesDialog> createState() =>
      _DirectMessagesDialogState();
}

class _DirectMessagesDialogState extends ConsumerState<_DirectMessagesDialog>
    with SingleTickerProviderStateMixin {
  // Built eagerly rather than lazily: opening straight into a conversation
  // never builds the TabBar, so a `late` field would first run its initializer
  // inside dispose(), creating a ticker on an already-deactivated State.
  late final TabController _tabs;
  late AccordChannel? _openChannel = widget.initialChannel;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String? get _selfId => ref.readUserId();

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final theme = Theme.of(context);
    final openChannel = _openChannel;
    final dialog = Dialog(
      backgroundColor: colors.foreground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: dialogConstraints(context, maxWidth: 900, maxHeight: 720),
        child: openChannel != null
            ? _DmConversation(
                channel: openChannel,
                selfId: _selfId,
                onBack: () => setState(() => _openChannel = null),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            UiCopy.directMessages(context: context),
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: UiCopy.close(context: context),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, size: 20, color: colors.gray),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabs,
                    tabs: [
                      Tab(text: UiCopy.messages(context: context)),
                      Tab(text: UiCopy.friends(context: context)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _DmListTab(
                          selfId: _selfId,
                          onOpen: (c) => setState(() => _openChannel = c),
                        ),
                        const _FriendsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
    final inDmCall = ref.watch(
      voiceControllerProvider.select(
        (voice) => voice.isConnected && voice.spaceId == null,
      ),
    );
    return Stack(
      children: [
        dialog,
        // The home screen's PiP sits below this modal route. Host a DM-only
        // copy here so minimizing the full-screen call returns to a visible,
        // interactive preview instead of hiding it behind the conversation.
        // Space calls keep using the home overlay, whose channel opener can
        // restore the correct space and tab.
        if (inDmCall)
          VoicePipOverlay(
            shownChannelId: null,
            onOpen: (_, _) {
              // This overlay is only mounted for spaceless calls, which reopen
              // themselves without consulting the space-channel callback.
            },
          ),
      ],
    );
  }
}
