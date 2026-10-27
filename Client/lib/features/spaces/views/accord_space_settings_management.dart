part of 'accord_space_settings.dart';

/// "Membership" section: the change-your-nickname tile.
class _MembershipSection extends StatelessWidget {
  const _MembershipSection({required this.onEditNickname});

  final VoidCallback onEditNickname;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(UiCopy.membership(context: context)),
        ListTile(
          leading: LeadingIcon(Icons.badge_outlined),
          title: Text(UiCopy.changeYourNickname(context: context)),
          subtitle: Text(UiCopy.howYouAppearInThisSpace(context: context)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onEditNickname,
        ),
      ],
    );
  }
}

/// "Management" section: permission-gated tiles that open the roles, audit
/// log, ban list, reports, emoji, and soundboard screens.
class _ManagementSection extends StatelessWidget {
  const _ManagementSection({
    required this.spaceId,
    required this.canManageRoles,
    required this.canViewAuditLog,
    required this.canModerate,
    required this.canManageEmojis,
    required this.canUseSoundboard,
    required this.canManageSoundboard,
  });

  final String spaceId;
  final bool canManageRoles;
  final bool canViewAuditLog;
  final bool canModerate;
  final bool canManageEmojis;
  final bool canUseSoundboard;
  final bool canManageSoundboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(UiCopy.management(context: context)),
        if (canManageRoles)
          ListTile(
            leading: LeadingIcon(Icons.shield_outlined),
            title: Text(UiCopy.roles2(context: context)),
            subtitle: Text(UiCopy.createEditAndOrderRoles(context: context)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAccordRoleManagement(context, spaceId: spaceId),
          ),
        if (canViewAuditLog)
          ListTile(
            leading: LeadingIcon(Icons.history),
            title: Text(UiCopy.auditLog(context: context)),
            subtitle: Text(
              UiCopy.recentModerationAndAdminActions(context: context),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAccordAuditLog(context, spaceId: spaceId),
          ),
        if (canModerate) ...[
          ListTile(
            leading: LeadingIcon(Icons.gavel),
            title: Text(UiCopy.bannedMembers(context: context)),
            subtitle: Text(UiCopy.reviewAndUnbanMembers(context: context)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAccordBanList(context, spaceId: spaceId),
          ),
          ListTile(
            leading: LeadingIcon(Icons.flag_outlined),
            title: Text(UiCopy.reports(context: context)),
            subtitle: Text(
              UiCopy.reviewAndResolveMemberReports(context: context),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showReportsPanel(context, spaceId: spaceId),
          ),
        ],
        if (canManageEmojis)
          ListTile(
            leading: LeadingIcon(Icons.emoji_emotions_outlined),
            title: Text(UiCopy.customEmoji(context: context)),
            subtitle: Text(UiCopy.uploadRenameAndDeleteEmoji(context: context)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAccordEmojiManagement(context, spaceId: spaceId),
          ),
        if (canUseSoundboard)
          ListTile(
            leading: LeadingIcon(Icons.graphic_eq),
            title: Text(UiCopy.soundboard(context: context)),
            subtitle: Text(
              UiCopy.playAndManageSoundboardClips(context: context),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAccordSoundboard(
              context,
              spaceId: spaceId,
              canManage: canManageSoundboard,
            ),
          ),
      ],
    );
  }
}

/// "Danger zone" section (owner only): transfer ownership and delete space.
class _DangerZoneSection extends StatelessWidget {
  const _DangerZoneSection({
    required this.spaceId,
    required this.busy,
    required this.onDeleteSpace,
  });

  final String spaceId;
  final bool busy;
  final VoidCallback onDeleteSpace;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(UiCopy.dangerZone(context: context)),
        ListTile(
          leading: LeadingIcon(Icons.swap_horiz),
          title: Text(UiCopy.transferOwnership(context: context)),
          subtitle: Text(UiCopy.handThisSpaceToAnotherMember(context: context)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showTransferOwnership(context, spaceId: spaceId),
        ),
        ListTile(
          leading: LeadingIcon(Icons.delete_forever, color: colors.red),
          title: Text(
            UiCopy.deleteSpace(context: context),
            style: TextStyle(color: colors.red),
          ),
          subtitle: Text(UiCopy.permanentlyRemoveThisSpace(context: context)),
          onTap: busy ? null : onDeleteSpace,
        ),
      ],
    );
  }
}
