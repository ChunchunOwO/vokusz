// Design-review hook for the capture app, not part of the store set: opens a
// named screen or dialog over the seeded home screen, so every surface can be
// looked at against the same offline fixture. `?open=space` and so on — see
// [openReviewScreen].

import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/automod/views/automod_panel.dart';
import 'package:bonfire/features/channels/views/channel_management.dart';
import 'package:bonfire/features/channels/views/channel_permissions.dart';
import 'package:bonfire/features/member/views/accord_member_popout.dart';
import 'package:bonfire/features/messaging/views/emoji_picker.dart';
import 'package:bonfire/features/messaging/views/pinned_messages.dart';
import 'package:bonfire/features/onboarding/views/onboarding_help.dart';
import 'package:bonfire/features/profiles/views/profiles_page.dart';
import 'package:bonfire/features/server/views/add_server_dialog.dart';
import 'package:bonfire/features/settings/views/privacy_settings_page.dart';
import 'package:bonfire/features/spaces/views/accord_audit_log.dart';
import 'package:bonfire/features/spaces/views/accord_ban_list.dart';
import 'package:bonfire/features/spaces/views/accord_channel_reorder.dart';
import 'package:bonfire/features/spaces/views/accord_discovery.dart';
import 'package:bonfire/features/spaces/views/accord_emoji_management.dart';
import 'package:bonfire/features/spaces/views/accord_invites.dart';
import 'package:bonfire/features/spaces/views/accord_reports.dart';
import 'package:bonfire/features/spaces/views/accord_search.dart';
import 'package:bonfire/features/spaces/views/accord_soundboard.dart';
import 'package:bonfire/features/spaces/views/accord_space_settings.dart';
import 'package:bonfire/features/spaces/views/accord_transfer_ownership.dart';
import 'package:bonfire/features/user/views/accord_account_settings.dart';
import 'package:bonfire/features/user/views/accord_direct_messages.dart';
import 'package:bonfire/features/user/views/accord_profile_edit.dart';
import 'package:bonfire/features/voice/views/voice_settings_screen.dart';
import 'package:flutter/material.dart';

import 'seeded_space.dart';

final _general = AccordChannel(
  id: seedGeneralChannelId,
  name: 'general',
  type: 'text',
  spaceId: seedSpaceId,
);

/// Opens the screen named [name] (from the `open` query parameter) over the
/// home screen. Unknown names do nothing.
Future<void> openReviewScreen(BuildContext context, String name) async {
  switch (name) {
    case 'space':
      await showAccordSpaceSettings(context, spaceId: seedSpaceId);
    case 'invites':
      await showAccordInvites(context, spaceId: seedSpaceId);
    case 'bans':
      await showAccordBanList(context, spaceId: seedSpaceId);
    case 'audit':
      await showAccordAuditLog(context, spaceId: seedSpaceId);
    case 'emoji':
      await showAccordEmojiManagement(context, spaceId: seedSpaceId);
    case 'soundboard':
      await showAccordSoundboard(
        context,
        spaceId: seedSpaceId,
        canManage: true,
      );
    case 'search':
      await showAccordSearch(context, spaceId: seedSpaceId);
    case 'pins':
      await showPinnedMessages(
        context,
        channelId: seedGeneralChannelId,
        spaceId: seedSpaceId,
        canManage: true,
      );
    case 'dm':
      await showAccordDirectMessages(context);
    case 'account':
      await showAccordAccountSettings(context);
    case 'profile':
      await showAccordProfileEdit(context);
    case 'channel':
      await showEditChannelDialog(
        context,
        spaceId: seedSpaceId,
        channel: _general,
      );
    case 'create':
      await showCreateChannelDialog(context, spaceId: seedSpaceId);
    case 'perms':
      await showChannelPermissionsDialog(
        context,
        spaceId: seedSpaceId,
        channel: _general,
      );
    case 'reorder':
      await showAccordChannelReorder(
        context,
        spaceId: seedSpaceId,
        channels: [_general],
      );
    case 'transfer':
      await showTransferOwnership(context, spaceId: seedSpaceId);
    case 'reports':
      await showReportsPanel(context, spaceId: seedSpaceId);
    case 'automod':
      await showAutomodPanel(context, seedSpaceId);
    case 'addserver':
      await showAddServerDialog(context);
    case 'voice':
      await showVoiceSettings(context);
    case 'profiles':
      await showProfilesSettings(context);
    case 'privacy':
      await showPrivacySettings(context);
    case 'help':
      await showOnboardingHelpDialog(context);
    case 'emojipicker':
      await showAccordEmojiPicker(context, spaceId: seedSpaceId);
    case 'discovery':
      await showAccordDiscovery(context);
    case 'member':
      // The one seeded member with a bio.
      await showAccordMemberPopout(
        context,
        spaceId: seedSpaceId,
        userId: 'u-tobi',
      );
    case 'self':
      await showAccordMemberPopout(
        context,
        spaceId: seedSpaceId,
        userId: seedSelfId,
      );
  }
}
