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

/// The list of users present in a voice [channelId], nested beneath the
/// channel row in the sidebar on a guide line that drops from the channel icon,
/// so the people read as *in* the channel rather than as a separate list.
/// Avatars line up with the channel name. Ports the reference client's
/// `voice_channel_item.gd` participant strip: small avatar (ringed while
/// speaking), name in role color, and status icons for mute, deafen, camera
/// and screen share.
class VoiceParticipantList extends ConsumerWidget {
  const VoiceParticipantList({
    super.key,
    required this.channelId,
    required this.spaceId,
    // Channel rows inset the icon by 8 and it is 18 wide with an 8 gap, so the
    // channel name — and the avatars beneath it — start 34 in.
    this.indent = 34,
  });

  final String channelId;
  final String? spaceId;

  /// Width of the guide-line gutter; the avatar starts here.
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sorted.length; i++)
            _VoiceMemberDrag(
              enabled: canMove,
              data: VoiceMemberDragData(
                ref.readActiveServerKey() ?? '',
                spaceId ?? '',
                channelId,
                sorted[i].userId,
              ),
              name: _nameFor(sorted[i].userId, members, users),
              child: _ParticipantRow(
                voiceState: sorted[i],
                member: members?[sorted[i].userId],
                user: users[sorted[i].userId],
                roles: roles,
                cdnUrl: cdnUrl,
                spaceId: spaceId,
                speaking: speaking.contains(sorted[i].userId),
                afk:
                    (selfAfk && sorted[i].userId == selfUserId) ||
                    accordPresenceStatus(presences, sorted[i].userId) ==
                        'idle',
                indent: indent,
                last: i == sorted.length - 1,
              ),
            ),
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
    required this.last,
  });

  /// Row height; the guide line is drawn against it.
  static const double height = 30;

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

  /// Whether this is the last participant, where the guide line ends.
  final bool last;

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
      padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
      child: Row(
        children: [
          Opacity(
            // Dimmed avatar for an away member, matching how every other chat
            // client signals "present but not here".
            opacity: afk ? 0.4 : 1,
            child: AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.fast),
              width: 24,
              height: 24,
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
              child: AccordMemberAvatar(
                avatarUrl: avatarUrl,
                initial: initial,
                radius: 10,
                backgroundColor: avatarBg,
                initialStyle: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall!.copyWith(
                color: afk ? nameColor.withValues(alpha: 0.5) : nameColor,
                fontSize: 13,
                fontWeight: speaking ? FontWeight.w600 : FontWeight.w500,
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
    final content = id == null
        ? row
        : Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => showAccordMemberPopout(
                context,
                spaceId: id,
                userId: voiceState.userId,
              ),
              child: row,
            ),
          );
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: indent - 4,
            child: CustomPaint(
              painter: _GuidePainter(
                color: colors.dirtyWhite.withValues(alpha: 0.18),
                // Centre of the 18px channel icon, which sits 8 in.
                x: 17,
                last: last,
              ),
            ),
          ),
          Expanded(child: content),
        ],
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

/// One participant's stretch of the guide line: a vertical stroke dropping from
/// the channel icon, with a rounded elbow into this row. The last row's stroke
/// ends at its elbow, so the line stops at the last person.
class _GuidePainter extends CustomPainter {
  const _GuidePainter({
    required this.color,
    required this.x,
    required this.last,
  });

  final Color color;
  final double x;
  final bool last;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 6.0;
    final mid = size.height / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final end = size.width - 2;
    final path = Path()
      ..moveTo(x, 0)
      ..lineTo(x, mid - radius)
      ..quadraticBezierTo(x, mid, x + radius, mid)
      ..lineTo(end, mid);
    if (!last) {
      path
        ..moveTo(x, mid - radius)
        ..lineTo(x, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GuidePainter old) =>
      old.color != color || old.x != x || old.last != last;
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
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final colors = BonfireThemeExtension.of(context);
    return Draggable<VoiceMemberDragData>(
      data: data,
      // A lifted chip in the sheet colour, matching the menus.
      feedback: Material(
        color: colors.sheet,
        elevation: 8,
        shadowColor: colors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.headset_mic_outlined, size: 16, color: colors.gray),
              const SizedBox(width: 8),
              Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.emphasis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: child),
      child: child,
    );
  }
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
      // A drop target lights up with a soft accent wash as a member hovers it.
      builder: (context, candidates, rejected) => AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.fast),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: Theme.of(context).colorScheme.primary.withValues(
            alpha: candidates.isEmpty ? 0 : 0.18,
          ),
        ),
        child: child,
      ),
    );
  }
}
