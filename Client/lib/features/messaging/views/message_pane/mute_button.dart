part of 'message_pane.dart';

/// Notification controls for a channel. Server-side mutes come from the shared
/// per-connection cache; local notification levels remain app settings.
class _MuteButton extends ConsumerWidget {
  const _MuteButton({required this.channelId});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BonfireThemeExtension.of(context);
    final activeKey = ref.watch(
      connectionsControllerProvider.select((state) => state.activeKey),
    );
    final mutedChannels = activeKey == null
        ? const AsyncData<Set<String>>(<String>{})
        : ref.watch(mutedChannelsControllerProvider(activeKey));
    final muted = mutedChannels.value?.contains(channelId) ?? false;
    final level = ref.watch(
      settingsControllerProvider.select(
        (settings) => activeKey == null
            ? null
            : settings.channelNotificationLevel(activeKey, channelId),
      ),
    );
    final levelLabel = level == null
        ? 'Mentions (default)'
        : level == AccordSettings.channelNotifAll
        ? UiCopy.allMessages(context: context)
        : level == AccordSettings.channelNotifMentions
        ? UiCopy.mentionsOnly(context: context)
        : UiCopy.nothing(context: context);

    return PopupMenuButton<_NotifAction>(
      tooltip: UiCopy.notificationSettings(context: context, arg0: levelLabel),
      icon: Icon(
        muted
            ? Icons.notifications_off
            : (level == AccordSettings.channelNotifNothing
                  ? Icons.notifications_paused
                  : (level == AccordSettings.channelNotifAll
                        ? Icons.notifications_active
                        : Icons.notifications_none)),
        size: 18,
        color: colors.dirtyWhite,
      ),
      onSelected: (action) {
        if (activeKey == null) return;
        switch (action) {
          case _NotifAction.levelDefault:
            ref
                .read(settingsControllerProvider.notifier)
                .setChannelNotificationLevel(activeKey, channelId, null);
          case _NotifAction.levelAll:
            ref
                .read(settingsControllerProvider.notifier)
                .setChannelNotificationLevel(
                  activeKey,
                  channelId,
                  AccordSettings.channelNotifAll,
                );
          case _NotifAction.levelMentions:
            ref
                .read(settingsControllerProvider.notifier)
                .setChannelNotificationLevel(
                  activeKey,
                  channelId,
                  AccordSettings.channelNotifMentions,
                );
          case _NotifAction.levelNothing:
            ref
                .read(settingsControllerProvider.notifier)
                .setChannelNotificationLevel(
                  activeKey,
                  channelId,
                  AccordSettings.channelNotifNothing,
                );
          case _NotifAction.toggleMute:
            toggleChannelMute(
              context,
              ref,
              serverKey: activeKey,
              channelId: channelId,
              muted: muted,
            );
        }
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: _NotifAction.levelDefault,
          checked: level == null,
          child: Text(UiCopy.useDefault(context: context)),
        ),
        CheckedPopupMenuItem(
          value: _NotifAction.levelAll,
          checked: level == AccordSettings.channelNotifAll,
          child: Text(UiCopy.allMessages(context: context)),
        ),
        CheckedPopupMenuItem(
          value: _NotifAction.levelMentions,
          checked: level == AccordSettings.channelNotifMentions,
          child: Text(
            AppStrings.choose('Only @mentions', '仅 @提及', context: context),
          ),
        ),
        CheckedPopupMenuItem(
          value: _NotifAction.levelNothing,
          checked: level == AccordSettings.channelNotifNothing,
          child: Text(UiCopy.nothing(context: context)),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _NotifAction.toggleMute,
          enabled: activeKey != null && !mutedChannels.isLoading,
          child: Text(
            muted
                ? UiCopy.unmuteChannel(context: context)
                : UiCopy.muteChannel(context: context),
          ),
        ),
      ],
    );
  }
}

enum _NotifAction {
  levelDefault,
  levelAll,
  levelMentions,
  levelNothing,
  toggleMute,
}
