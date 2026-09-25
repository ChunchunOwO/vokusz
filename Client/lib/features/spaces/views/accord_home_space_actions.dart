part of 'accord_home.dart';

/// The mute / invite / settings / leave entries shared by the standalone-space
/// menu and the folder-member menu. Gated on the space's own connection session,
/// so actions hit the right server even when it isn't the active one.
List<AccordMenuEntry> _serverActionEntries(
  BuildContext context,
  WidgetRef ref,
  AccordSpace space,
  String serverKey,
) {
  final conn = ref.read(connectionsControllerProvider).connectionFor(serverKey);
  final session = conn?.session;
  final userId = session?.userId;
  final members = ref.read(
    accordMembersControllerProvider(serverKey, space.id),
  );
  final preview = ref.read(rolePreviewControllerProvider);
  final perms = accordEffectivePermissions(
    space: space,
    selfMember: userId == null ? null : members?[userId],
    roles: space.roles,
    currentUserId: userId ?? '',
    currentUserIsAdmin: session?.isAdmin ?? false,
    previewRoleId: preview?.spaceId == space.id ? preview?.roleId : null,
  );
  final canInvite = accordHasPermission(perms, AccordPermission.createInvites);
  final canManage = canManageSpaceSettings(perms);
  final isOwner = userId != null && space.ownerId == userId;
  final settingsCtl = ref.read(settingsControllerProvider.notifier);
  final muted = ref
      .read(settingsControllerProvider)
      .isSpaceMuted(serverKey, space.id);
  return [
    AccordMenuEntry(
      label: muted
          ? UiCopy.unmuteServer(context: context)
          : UiCopy.muteServer(context: context),
      icon: muted
          ? Icons.notifications_active_outlined
          : Icons.notifications_off_outlined,
      subtitle: muted
          ? null
          : UiCopy.silenceNotificationsFromThisServer(context: context),
      onSelected: () => settingsCtl.toggleSpaceMuted(serverKey, space.id),
    ),
    if (canInvite)
      AccordMenuEntry(
        label: UiCopy.copyServerLink(context: context),
        icon: Icons.link_outlined,
        onSelected: () => _copyServerLink(context, ref, space, serverKey),
      ),
    if (canInvite)
      AccordMenuEntry(
        label: UiCopy.invitePeople(context: context),
        icon: Icons.person_add_outlined,
        onSelected: () => showAccordInvites(context, spaceId: space.id),
      ),
    if (canManage)
      AccordMenuEntry(
        label: UiCopy.spaceSettings(context: context),
        icon: Icons.settings_outlined,
        onSelected: () => showAccordSpaceSettings(context, spaceId: space.id),
      ),
    AccordMenuEntry(
      label: UiCopy.hideFromList(context: context),
      icon: Icons.visibility_off_outlined,
      subtitle: UiCopy.removeFromYourRailWithoutLeaving(context: context),
      onSelected: () => settingsCtl.setSpaceHidden(serverKey, space.id, true),
    ),
    AccordMenuEntry(
      label: UiCopy.leaveServer(context: context),
      icon: Icons.logout,
      destructive: !isOwner,
      enabled: !isOwner,
      subtitle: isOwner
          ? UiCopy.transferOwnershipBeforeLeaving(context: context)
          : null,
      onSelected: isOwner
          ? null
          : () => _leaveSpace(context, ref, space, serverKey),
    ),
    AccordMenuEntry(
      label: UiCopy.leaveDeleteData2(context: context),
      icon: Icons.delete_forever_outlined,
      destructive: !isOwner,
      enabled: !isOwner,
      subtitle: isOwner
          ? null
          : UiCopy.permanentlyDeleteYourMessagesDataHere(context: context),
      onSelected: isOwner
          ? null
          : () => _leaveAndDeleteSpace(context, ref, space, serverKey),
    ),
    AccordMenuEntry(
      label: UiCopy.removeServer(context: context),
      icon: Icons.link_off,
      destructive: true,
      subtitle: UiCopy.disconnectRemoveFromThisAppWorksEven(context: context),
      onSelected: () => _removeServer(context, ref, serverKey),
    ),
    const AccordMenuEntry.divider(),
  ];
}

/// Removes the whole server *connection* that hosts a space from this app,
/// purely locally: it disposes the client and clears the saved credentials,
/// the rail entry, open tabs, unread state and the cached space list. Unlike
/// [_leaveSpace] it makes no network call, so it works for a server you can no
/// longer reach. A connection can host several spaces, so this removes all of
/// them on that host; nothing is deleted server-side.
Future<void> _removeServer(
  BuildContext context,
  WidgetRef ref,
  String serverKey,
) async {
  final conn = ref.read(connectionsControllerProvider).connectionFor(serverKey);
  if (conn == null) return;
  final server = conn.session.server;
  final label = (server.name?.isNotEmpty ?? false)
      ? server.name!
      : server.homeDomain;
  final confirmed = await showConfirmDialog(
    context,
    title: "Remove '$label'?",
    message: UiCopy.thisDisconnectsYourAccountAndRemovesThe(context: context),
    confirmLabel: UiCopy.remove(context: context),
    danger: true,
  );
  if (confirmed != true) return;
  await ref.read(accordAuthProvider.notifier).removeAccount(conn.session);
  if (context.mounted) showInfoSnack(context, "Removed '$label'");
}

/// Copies a shareable invite link for [space] to the clipboard, reusing an
/// existing invite when one exists or minting a default 7-day one otherwise.
/// Gated on `createInvites` by the caller. The quick equivalent of opening the
/// full invite dialog just to copy a link.
Future<void> _copyServerLink(
  BuildContext context,
  WidgetRef ref,
  AccordSpace space,
  String serverKey,
) async {
  final conn = ref.read(connectionsControllerProvider).connectionFor(serverKey);
  final client = ref.read(accordAuthProvider.notifier).clientForKey(serverKey);
  final baseUrl = conn?.session.server.baseUrl;
  if (client == null) return;

  String? code;
  final existing = await client.invites.listSpace(space.id);
  final existingData = existing.data;
  if (existing.ok && existingData is List) {
    final invites = existingData.whereType<AccordInvite>().toList();
    if (invites.isNotEmpty) code = invites.first.code;
  }
  if (code == null) {
    final created = await client.invites.createSpace(
      space.id,
      data: {'max_age': 604800, 'max_uses': 0, 'temporary': false},
    );
    final createdData = created.data;
    if (created.ok && createdData is AccordInvite) {
      code = createdData.code;
    } else if (created.ok) {
      // Some servers return no body on create; refetch to recover the code.
      final refetch = await client.invites.listSpace(space.id);
      final refetchData = refetch.data;
      if (refetch.ok && refetchData is List) {
        final invites = refetchData.whereType<AccordInvite>().toList();
        if (invites.isNotEmpty) code = invites.first.code;
      }
    }
  }
  if (code == null) {
    if (context.mounted) {
      showInfoSnack(
        context,
        UiCopy.couldNotCreateAnInviteLink(context: context),
      );
    }
    return;
  }
  final link = baseUrl == null ? code : '$baseUrl/invite/$code';
  await Clipboard.setData(ClipboardData(text: link));
  if (context.mounted)
    showInfoSnack(context, UiCopy.serverLinkCopied(context: context));
}

/// Confirms then leaves [space] *and deletes all the user's data* on its own
/// connection (`deleteData: true`). The destructive sibling of [_leaveSpace],
/// surfaced from the space menu as well as Privacy & Data. Owner-guarded by the
/// caller (the tile is disabled for owners).
Future<void> _leaveAndDeleteSpace(
  BuildContext context,
  WidgetRef ref,
  AccordSpace space,
  String serverKey,
) async {
  final confirmed = await showConfirmDialog(
    context,
    title: UiCopy.leaveDeleteData2(context: context),
    message: UiCopy.thisWillPermanentlyLeaveAndDeleteAll(context: context, arg0: space.name),
    confirmLabel: UiCopy.leaveDelete2(context: context),
    danger: true,
  );
  if (confirmed != true || !context.mounted) return;

  final client = ref.read(accordAuthProvider.notifier).clientForKey(serverKey);
  if (client == null) return;
  final result = await client.members.leaveMe(space.id, deleteData: true);
  if (!result.ok) {
    if (context.mounted) {
      showErrorSnack(
        context,
        result,
        prefix: UiCopy.failedToLeave(context: context),
      );
    }
    return;
  }
  ref
      .read(connectionsControllerProvider.notifier)
      .removeSpace(serverKey, space.id);
  ref.read(spacesControllerProvider.notifier).removeSpace(space.id);
  if (context.mounted) {
    showInfoSnack(
      context,
      UiCopy.leftAndDeletedYourData(context: context, arg0: space.name),
    );
  }
}

/// Confirms then leaves [space] on its own connection, without deleting any
/// data. Drops the space from both the connection cache and the active list on
/// success.
Future<void> _leaveSpace(
  BuildContext context,
  WidgetRef ref,
  AccordSpace space,
  String serverKey,
) async {
  final confirmed = await showConfirmDialog(
    context,
    title: "Leave '${space.name}'?",
    message: UiCopy.youWillLoseAccessToThisServer(context: context),
    confirmLabel: UiCopy.leave(context: context),
    danger: true,
  );
  if (confirmed != true || !context.mounted) return;

  final client = ref.read(accordAuthProvider.notifier).clientForKey(serverKey);
  if (client == null) return;
  final result = await client.members.leaveMe(space.id);
  if (!result.ok) {
    if (context.mounted) {
      showErrorSnack(
        context,
        result,
        prefix: UiCopy.failedToLeave(context: context),
      );
    }
    return;
  }
  ref
      .read(connectionsControllerProvider.notifier)
      .removeSpace(serverKey, space.id);
  ref.read(spacesControllerProvider.notifier).removeSpace(space.id);
  if (context.mounted) showInfoSnack(context, "Left '${space.name}'");
}
