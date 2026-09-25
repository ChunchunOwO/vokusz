part of 'accord_space_settings.dart';

/// Shared outlined dropdown used by the moderation/channel pickers below.
/// Renders exactly the dropdown the old `_dropdown` state helper produced.
class _SettingsDropdown<T> extends StatelessWidget {
  const _SettingsDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final bool enabled;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      items: items,
      onChanged: enabled ? onChanged : null,
    );
  }
}

/// "Banner" section: the 16:9 banner preview plus upload/change/remove
/// controls (or a hint when the user lacks Manage Space).
class _BannerSection extends StatelessWidget {
  const _BannerSection({
    required this.bannerUrl,
    required this.pendingBytes,
    required this.canManage,
    required this.busy,
    required this.onPick,
    required this.onRemove,
  });

  final String? bannerUrl;
  final Uint8List? pendingBytes;
  final bool canManage;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    final bannerUrl = this.bannerUrl;
    final hasBanner = pendingBytes != null || bannerUrl != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(UiCopy.banner(context: context)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpaceSettingsBannerPreview(
                url: bannerUrl,
                pendingBytes: pendingBytes,
              ),
              if (canManage) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: busy ? null : onPick,
                      icon: const Icon(Icons.upload, size: 18),
                      label: Text(
                        hasBanner
                            ? UiCopy.change(context: context)
                            : UiCopy.upload(context: context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (hasBanner)
                      TextButton(
                        onPressed: busy ? null : onRemove,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.red,
                        ),
                        child: Text(UiCopy.remove(context: context)),
                      ),
                  ],
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    UiCopy.youNeedManageSpaceToEditThe(context: context),
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: colors.gray,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Overview" section: icon avatar with upload/remove controls plus the name
/// and description fields. The [TextEditingController]s stay owned by the
/// settings screen's state.
class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.nameController,
    required this.descriptionController,
    required this.iconUrl,
    required this.pendingIconBytes,
    required this.iconRemoved,
    required this.busy,
    required this.onPickIcon,
    required this.onRemoveIcon,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final String? iconUrl;
  final Uint8List? pendingIconBytes;
  final bool iconRemoved;
  final bool busy;
  final VoidCallback onPickIcon;
  final VoidCallback onRemoveIcon;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final iconUrl = this.iconUrl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(UiCopy.overview(context: context)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  SpaceSettingsIconPreview(
                    url: iconUrl,
                    pendingBytes: pendingIconBytes,
                    removed: iconRemoved,
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: busy ? null : onPickIcon,
                    child: Text(
                      pendingIconBytes != null ||
                              (!iconRemoved && iconUrl != null)
                          ? UiCopy.change(context: context)
                          : UiCopy.upload(context: context),
                    ),
                  ),
                  if (pendingIconBytes != null ||
                      (!iconRemoved && iconUrl != null))
                    TextButton(
                      onPressed: busy ? null : onRemoveIcon,
                      style: TextButton.styleFrom(foregroundColor: colors.red),
                      child: Text(UiCopy.remove(context: context)),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !busy,
                      decoration: InputDecoration(
                        labelText: UiCopy.name(context: context),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      enabled: !busy,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: UiCopy.description(context: context),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Moderation" section: verification/notification/NSFW/content-filter
/// dropdowns plus the public and guest-access switches.
class _ModerationSection extends StatelessWidget {
  const _ModerationSection({
    required this.verification,
    required this.notifications,
    required this.nsfw,
    required this.contentFilter,
    required this.isPublic,
    required this.guestAccess,
    required this.busy,
    required this.onVerificationChanged,
    required this.onNotificationsChanged,
    required this.onNsfwChanged,
    required this.onContentFilterChanged,
    required this.onPublicChanged,
    required this.onGuestAccessChanged,
  });

  final String verification;
  final String notifications;
  final String nsfw;
  final String contentFilter;
  final bool isPublic;
  final bool guestAccess;
  final bool busy;
  final ValueChanged<String?> onVerificationChanged;
  final ValueChanged<String?> onNotificationsChanged;
  final ValueChanged<String?> onNsfwChanged;
  final ValueChanged<String?> onContentFilterChanged;
  final ValueChanged<bool> onPublicChanged;
  final ValueChanged<bool> onGuestAccessChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(UiCopy.moderation(context: context)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            children: [
              _SettingsDropdown<String>(
                label: UiCopy.verificationLevel(context: context),
                value: verification,
                items: [
                  for (final v in _verificationLevels)
                    DropdownMenuItem(
                      value: v.value,
                      child: Text(AppStrings.label(v.label, context: context)),
                    ),
                ],
                enabled: !busy,
                onChanged: onVerificationChanged,
              ),
              const SizedBox(height: 8),
              _SettingsDropdown<String>(
                label: UiCopy.defaultNotifications(context: context),
                value: notifications,
                items: [
                  for (final v in _notificationLevels)
                    DropdownMenuItem(
                      value: v.value,
                      child: Text(AppStrings.label(v.label, context: context)),
                    ),
                ],
                enabled: !busy,
                onChanged: onNotificationsChanged,
              ),
              const SizedBox(height: 8),
              _SettingsDropdown<String>(
                label: UiCopy.nsfwLevel(context: context),
                value: nsfw,
                items: [
                  for (final v in _nsfwLevels)
                    DropdownMenuItem(
                      value: v.value,
                      child: Text(AppStrings.label(v.label, context: context)),
                    ),
                ],
                enabled: !busy,
                onChanged: onNsfwChanged,
              ),
              const SizedBox(height: 8),
              _SettingsDropdown<String>(
                label: UiCopy.explicitContentFilter(context: context),
                value: contentFilter,
                items: [
                  for (final v in _contentFilters)
                    DropdownMenuItem(
                      value: v.value,
                      child: Text(AppStrings.label(v.label, context: context)),
                    ),
                ],
                enabled: !busy,
                onChanged: onContentFilterChanged,
              ),
            ],
          ),
        ),
        SwitchListTile(
          value: isPublic,
          onChanged: busy ? null : onPublicChanged,
          title: Text(UiCopy.publicSpace(context: context)),
          subtitle: Text(
            UiCopy.discoverableAndJoinableByAnyone(context: context),
          ),
        ),
        SwitchListTile(
          value: guestAccess,
          onChanged: busy ? null : onGuestAccessChanged,
          title: Text(UiCopy.allowGuestAccess(context: context)),
          subtitle: Text(
            UiCopy.letUnauthenticatedUsersBrowse(context: context),
          ),
        ),
      ],
    );
  }
}

/// "Channels" section: the rules and system-messages channel pickers.
class _ChannelsSection extends StatelessWidget {
  const _ChannelsSection({
    required this.textChannels,
    required this.rulesValue,
    required this.systemValue,
    required this.busy,
    required this.onRulesChanged,
    required this.onSystemChanged,
  });

  final List<AccordChannel> textChannels;
  final String? rulesValue;
  final String? systemValue;
  final bool busy;
  final ValueChanged<String?> onRulesChanged;
  final ValueChanged<String?> onSystemChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(UiCopy.channels(context: context)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            children: [
              _SettingsDropdown<String?>(
                label: UiCopy.rulesChannel(context: context),
                value: rulesValue,
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(UiCopy.none(context: context)),
                  ),
                  for (final c in textChannels)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text('# ${c.name ?? c.id}'),
                    ),
                ],
                enabled: !busy,
                onChanged: onRulesChanged,
              ),
              const SizedBox(height: 8),
              _SettingsDropdown<String?>(
                label: UiCopy.systemMessagesChannel(context: context),
                value: systemValue,
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(UiCopy.none(context: context)),
                  ),
                  for (final c in textChannels)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text('# ${c.name ?? c.id}'),
                    ),
                ],
                enabled: !busy,
                onChanged: onSystemChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The right-aligned "Save settings" button that flushes the whole form.
class _SaveSettingsButton extends StatelessWidget {
  const _SaveSettingsButton({required this.busy, required this.onSave});

  final bool busy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: busy ? null : onSave,
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save, size: 18),
          label: Text(UiCopy.saveSettings(context: context)),
        ),
      ),
    );
  }
}
