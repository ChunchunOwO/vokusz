import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/features/member/utils/permissions.dart';
import 'package:bonfire/shared/utils/rest_result_ext.dart';
import 'package:bonfire/l10n/ui_copy.dart';
import 'package:accordkit/accordkit.dart';
import 'package:bonfire/shared/utils/client_access.dart';
import 'package:bonfire/features/events/controllers/presence.dart';
import 'package:bonfire/features/member/controllers/accord_members.dart';
import 'package:bonfire/features/member/utils/member_display.dart';
import 'package:bonfire/features/spaces/controllers/spaces.dart';
import 'package:bonfire/features/user/controllers/accord_users.dart';
import 'package:bonfire/features/voice/controllers/voice.dart';
import 'package:bonfire/features/voice/controllers/voice_states.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:bonfire/features/member/views/accord_member_avatar.dart';
import 'package:bonfire/features/member/views/accord_member_popout.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The list of users present in a voice [channelId], rendered beneath the
/// channel tile in the sidebar. The avatar lines up with the channel icon.
/// Ports the reference client's `voice_channel_item.gd` participant strip:
/// small avatar (green ring while speaking), name in role color, and status
/// icons for mute, deafen, camera and screen share.
class VoiceParticipantList extends ConsumerWidget {
  const VoiceParticipantList({
    super.key,
    required this.channelId,
    required this.spaceId,
    // Channel rows inset the icon by 8 + 8. The 22px avatar circle sits 2px
    // inside its 26px slot, so 14 puts that circle's left edge on the icon.
    this.indent = 14,
  });

  final String channelId;
  final String? spaceId;
  final double indent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final states = ref.watch(
      voiceStatesControllerProvider(
        ref.readActiveServerKey() ?? '',
      ).select((cache) => voiceStatesFor(cache, channelId)),
    );
    if (states.isEmpty) return const SizedBox.shrink();

    // Speaking highlights only apply while we're connected to this channel —
    // the speaking set is derived from our own LiveKit room.
    final speaking = ref.watch(
      voiceControllerProvider.select(
        (v) => v.channelId == channelId ? v.speakingUserIds : const <String>{},
      ),
    );

    // AFK, for #112. Remote members are read from presence (`idle`) — the
    // Accord voice state carries no AFK field, so an idle presence is the only
    // away signal that crosses the wire. Our own row uses the voice
    // controller's flag directly so it flips the instant we go away, without
    // waiting on the presence round-trip.
    final presences = ref.watch(activePresencesProvider);
    final selfAfk = ref.watch(
      voiceControllerProvider.select(
        (v) => v.channelId == channelId && v.isAfk,
      ),
    );
    final selfUserId = ref.watchUserId();

    final members = spaceId == null
        ? null
        : ref.watch(
            accordMembersControllerProvider(
              ref.readActiveServerKey() ?? '',
              spaceId!,
            ),
          );
    final users = ref.watch(
      accordUsersControllerProvider(ref.readActiveServerKey() ?? ''),
    );
    final roles = spaceId == null
        ? const <AccordRole>[]
        : ref.watch(
                spacesControllerProvider.select(
                  (s) => s?.firstWhereOrNull((sp) => sp.id == spaceId)?.roles,
                ),
              ) ??
              const <AccordRole>[];
    final space = ref.watch(spacesControllerProvider)?.firstWhereOrNull((s) => s.id == spaceId);
    final canMove = spaceId != null && accordHasPermission(ref.watchAccordPermissions(space, spaceId!), AccordPermission.moveMembers);
    final cdnUrl = ref.watchCdnUrl();

    final sorted = [...states]
      ..sort(
        (a, b) => _nameFor(a.userId, members, users).toLowerCase().compareTo(
          _nameFor(b.userId, members, users).toLowerCase(),
        ),
      );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final vs in sorted)
          _VoiceMemberDrag(
            enabled: canMove,
            data: VoiceMemberDragData(ref.readActiveServerKey() ?? '', spaceId ?? '', channelId, vs.userId),
            name: _nameFor(vs.userId, members, users),
            child: _ParticipantRow(
            voiceState: vs,
            member: members?[vs.userId],
            user: users[vs.userId],
            roles: roles,
            cdnUrl: cdnUrl,
            spaceId: spaceId,
            speaking: speaking.contains(vs.userId),
            afk:
                (selfAfk && vs.userId == selfUserId) ||
                accordPresenceStatus(presences, vs.userId) == 'idle',
            indent: indent,
          )),
      ],
      ),
    );
  }
}

String _nameFor(
  String userId,
  Map<String, AccordMember>? members,
  Map<String, AccordUser> users,
) {
  final member = members?[userId];
  if (member != null) return accordMemberName(member, fallback: userId);
  return accordUserName(users[userId], fallback: userId);
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.voiceState,
    required this.member,
    required this.user,
    required this.roles,
    required this.cdnUrl,
    required this.spaceId,
    required this.speaking,
    required this.afk,
    required this.indent,
  });

  final AccordVoiceState voiceState;
  final AccordMember? member;
  final AccordUser? user;
  final List<AccordRole> roles;
  final String? cdnUrl;
  final String? spaceId;
  final bool speaking;

  /// Away from keyboard: dims the row and adds a moon badge.
  final bool afk;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final theme = Theme.of(context);
    final name = member != null
        ? accordMemberName(member, fallback: voiceState.userId)
        : accordUserName(user, fallback: voiceState.userId);
    final avatarUrl = member != null
        ? accordMemberAvatarUrl(member, cdnUrl)
        : accordAvatarUrl(user, cdnUrl);
    final avatarBg = accordAvatarColor(member?.user ?? user, voiceState.userId);
    final colorRole = member == null ? null : memberColorRole(member!, roles);
    final nameColor =
        communityNameColor(member?.user ?? user) ??
        (colorRole == null ? null : accordRoleColor(colorRole.color)) ??
        colors.dirtyWhite;
    final initial = accordInitial(name);

    final row = Padding(
      padding: EdgeInsets.fromLTRB(indent, 1, 8, 1),
      child: Row(
        children: [
          Opacity(
            // Dimmed avatar for an away member, matching how every other chat
            // client signals "present but not here".
            opacity: afk ? 0.4 : 1,
            child: Container(
              width: 26,
              height: 26,
              // The border's thickness is added to [padding]. Keeping the
              // stroke when silent stops the face from jumping.
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: speaking
                      ? const Color(0xFF4DA3FF)
                      : const Color(0x00000000),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(1),
              child: AccordMemberAvatar(
                avatarUrl: avatarUrl,
                initial: initial,
                radius: 11,
                backgroundColor: avatarBg,
                initialStyle: const TextStyle(fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall!.copyWith(
                color: afk ? nameColor.withValues(alpha: 0.5) : nameColor,
                fontSize: 13,
              ),
            ),
          ),
          if (afk)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Tooltip(
                message: UiCopy.away(context: context),
                child: Icon(
                  Icons.nightlight_round,
                  size: 11,
                  color: colors.gray,
                  key: const Key('voice-participant-afk'),
                ),
              ),
            ),
          ..._flags(context, colors),
        ],
      ),
    );
    final id = spaceId;
    if (id == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showAccordMemberPopout(
          context,
          spaceId: id,
          userId: voiceState.userId,
        ),
        child: row,
      ),
    );
  }

  List<Widget> _flags(BuildContext context, BonfireThemeExtension colors) {
    final flags = <Widget>[];
    if (voiceState.selfDeaf) {
      flags.add(
        _iconFlag(
          Icons.volume_off,
          colors.red,
          AppStrings.choose('Deafened', '已关闭听音', context: context),
        ),
      );
    }
    if (voiceState.selfMute) {
      flags.add(
        _iconFlag(
          Icons.mic_off,
          colors.red,
          AppStrings.choose('Muted', '已静音', context: context),
        ),
      );
    }
    if (voiceState.selfVideo) {
      flags.add(
        _iconFlag(
          Icons.videocam,
          colors.green,
          AppStrings.choose('Camera on', '正在视频', context: context),
        ),
      );
    }
    if (voiceState.selfStream) {
      flags.add(
        _iconFlag(
          Icons.screen_share,
          colors.primary,
          AppStrings.choose('Sharing screen', '正在共享屏幕', context: context),
        ),
      );
    }
    return flags;
  }

  Widget _iconFlag(IconData icon, Color color, String tip) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Tooltip(
      message: tip,
      child: Icon(icon, size: 13, color: color),
    ),
  );
}

class VoiceMemberDragData {
  const VoiceMemberDragData(this.serverKey, this.spaceId, this.channelId, this.userId);
  final String serverKey;
  final String spaceId;
  final String channelId;
  final String userId;
}

class _VoiceMemberDrag extends StatelessWidget {
  const _VoiceMemberDrag({required this.enabled, required this.data, required this.name, required this.child});
  final bool enabled;
  final VoiceMemberDragData data;
  final String name;
  final Widget child;
  @override
  Widget build(BuildContext context) => !enabled ? child : Draggable<VoiceMemberDragData>(
    data: data,
    feedback: Material(elevation: 6, child: Padding(padding: const EdgeInsets.all(10), child: Text(name))),
    childWhenDragging: Opacity(opacity: 0.4, child: child),
    child: child,
  );
}

class VoiceMemberDropTarget extends ConsumerWidget {
  const VoiceMemberDropTarget({super.key, required this.channel, required this.spaceId, required this.child});
  final AccordChannel channel;
  final String? spaceId;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spacesControllerProvider)?.firstWhereOrNull((s) => s.id == spaceId);
    final canMove = spaceId != null && accordHasPermission(ref.watchAccordPermissions(space, spaceId!), AccordPermission.moveMembers);
    return DragTarget<VoiceMemberDragData>(
      onWillAcceptWithDetails: (details) => canMove && details.data.serverKey == ref.readActiveServerKey() && details.data.spaceId == spaceId && details.data.channelId != channel.id,
      onAcceptWithDetails: (details) async {
        final client = ref.accordClient;
        if (client == null) return;
        final result = await client.voice.moveMember(channel.id, details.data.userId, details.data.channelId);
        if (!result.ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.errorMessageOr(AppStrings.choose('Could not move member', '移动成员失败', context: context)))));
        }
      },
      builder: (context, candidates, rejected) => Container(
        color: candidates.isEmpty ? null : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        child: child,
      ),
    );
  }
}
