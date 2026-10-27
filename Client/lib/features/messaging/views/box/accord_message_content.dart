import 'package:accordkit/accordkit.dart';
import 'package:bonfire/shared/utils/client_access.dart';
import 'package:bonfire/features/channels/controllers/accord_channels.dart';
import 'package:bonfire/features/channels/controllers/open_tabs.dart';
import 'package:bonfire/features/channels/utils/mark_channel_read.dart';
import 'package:bonfire/features/channels/models/open_tab.dart';
import 'package:bonfire/features/member/controllers/accord_members.dart';
import 'package:bonfire/features/member/views/accord_member_popout.dart';
import 'package:bonfire/features/messaging/views/box/accord_markdown_box.dart';
import 'package:bonfire/features/messaging/views/box/accord_message_markup.dart';
import 'package:bonfire/features/messaging/controllers/accord_emojis.dart';
import 'package:bonfire/features/server/controllers/connections.dart';
import 'package:bonfire/features/settings/controllers/settings.dart';
import 'package:bonfire/features/spaces/controllers/spaces.dart';
import 'package:collection/collection.dart';
import 'package:dart_markdown/dart_markdown.dart' as md;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_viewer/markdown_viewer.dart';

/// Renders Accord message content as markdown, with inline chips for `@user`,
/// `@role`, `@everyone`/`@here`, and `#channel` references, custom `:emoji:`,
/// `||spoiler||` reveals, and `__underline__`.
///
/// All of these are layered onto the standard markdown stack ([AccordMarkdownBox])
/// as syntax extensions, so a single message renders markdown *and* Accord
/// tokens together. Mention/channel chips are tappable: a user mention opens the
/// member popout, a channel mention opens (or focuses) that channel's tab.
///
/// Pass [spaceId] when rendering inside a space so handles resolve against the
/// space's caches and taps can navigate; without it (DMs) only the
/// protocol-agnostic tokens (`@everyone`/`@here`, spoiler, underline, markdown)
/// apply.
///
/// The syntax extensions are memoised per row and rebuilt only when a lookup
/// table they resolve against changes. `MarkdownViewer` keeps its parsed AST
/// across rebuilds only while the extension list is *identical*, so a fresh list
/// on every build (a hover, a divider drag, a message arriving elsewhere in the
/// pane) used to re-parse every visible message each time.
class AccordMessageContent extends ConsumerStatefulWidget {
  const AccordMessageContent({super.key, required this.content, this.spaceId});

  final String content;
  final String? spaceId;

  @override
  ConsumerState<AccordMessageContent> createState() =>
      _AccordMessageContentState();
}

typedef _Markup = ({
  List<md.Syntax> syntaxes,
  List<MarkdownElementBuilder> builders,
});

class _AccordMessageContentState extends ConsumerState<AccordMessageContent> {
  _Markup? _markup;
  List<Object?> _markupInputs = const [];

  /// The cached markup while every input is unchanged — strings by value, the
  /// lookup tables by identity (they come from the shared [Expando] caches
  /// below, so identity tracks the underlying provider state exactly).
  _Markup _markupFor(List<Object?> inputs, _Markup Function() build) {
    final cached = _markup;
    if (cached != null && _sameInputs(inputs, _markupInputs)) return cached;
    _markupInputs = inputs;
    return _markup = build();
  }

  static bool _sameInputs(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (x == null || x is String) {
        if (x != y) return false;
      } else if (!identical(x, y)) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cdnUrl = ref.watchCdnUrl();
    final content = widget.content;

    final id = widget.spaceId;
    if (id == null) {
      // DM / no-space context: still resolve broadcasts, spoilers, underline,
      // and markdown — just nothing that needs space caches or navigation.
      final markup = _markupFor([
        null,
        cdnUrl,
      ], () => buildAccordMarkup(AccordMarkupContext(cdnUrl: cdnUrl)));
      return AccordMarkdownBox(
        content: content,
        trustedMediaBaseUrl: cdnUrl,
        syntaxExtensions: markup.syntaxes,
        elementBuilders: markup.builders,
      );
    }

    final serverKey = ref.readActiveServerKey() ?? '';
    // The member roster is only consulted to resolve `@handle` mentions, and
    // backfilling it fans out a fetch per member. Most messages contain no
    // mention, so skip the load entirely unless this one does — that keeps a
    // mention-free channel from triggering the roster fetch when the member
    // sidebar (which loads it on its own) is collapsed.
    final members = content.contains('@')
        ? ref.watch(accordMembersControllerProvider(serverKey, id))
        : null;
    // Role edits replace the space's `roles` list, so selecting it (rather
    // than the whole space) rebuilds on exactly the changes that matter.
    final roles = ref.watch(
      spacesControllerProvider.select(
        (s) => s?.firstWhereOrNull((sp) => sp.id == id)?.roles,
      ),
    );
    final channels = ref.watch(accordChannelsControllerProvider(serverKey, id));
    final emojiList = ref.watch(accordEmojisControllerProvider(serverKey, id));

    final userByHandle = _handlesFor(members);
    final roleByName = _rolesFor(roles);
    final channelByName = _channelsFor(channels);
    final emojiByName = _emojiFor(emojiList);

    final markup = _markupFor(
      [id, cdnUrl, userByHandle, roleByName, channelByName, emojiByName],
      () => buildAccordMarkup(
        AccordMarkupContext(
          userByHandle: userByHandle,
          roleByName: roleByName,
          channelByName: channelByName,
          emojiByName: emojiByName,
          cdnUrl: cdnUrl,
          // Resolved at tap time, so a markup cached across rebuilds never acts
          // on a stale space.
          onTapUser: (userId) {
            final spaceId = widget.spaceId;
            if (!mounted || spaceId == null) return;
            showAccordMemberPopout(context, spaceId: spaceId, userId: userId);
          },
          onTapChannel: (channelId) {
            final spaceId = widget.spaceId;
            if (!mounted || spaceId == null) return;
            _openChannel(spaceId, channelId);
          },
        ),
      ),
    );

    return AccordMarkdownBox(
      content: content,
      trustedMediaBaseUrl: cdnUrl,
      syntaxExtensions: markup.syntaxes,
      elementBuilders: markup.builders,
    );
  }

  /// Opens (or switches to) the tab for [channelId] on the active server,
  /// mirroring the sidebar's channel selection. The NSFW gate and voice-join
  /// behaviour stay with the message pane / channel list; a mention tap just
  /// surfaces the channel.
  void _openChannel(String spaceId, String channelId) {
    final activeKey = ref.read(connectionsControllerProvider).activeKey;
    if (activeKey == null) return;
    final channel = ref
        .read(accordChannelsControllerProvider(activeKey, spaceId))
        ?.firstWhereOrNull((c) => c.id == channelId);
    ref
        .read(openTabsControllerProvider.notifier)
        .open(
          OpenTab(
            channelId: channelId,
            spaceId: spaceId,
            serverKey: activeKey,
            name: channel?.name ?? channelId,
          ),
        );
    markChannelRead(ref, channelId, fallbackMessageId: channel?.lastMessageId);
    ref
        .read(settingsControllerProvider.notifier)
        .setLastSelection(activeKey, spaceId, channelId);
  }
}

// Lookup tables shared by every visible message. Each is derived from a single
// provider state object and cached against that exact instance (the caches
// replace their collections on every change), so a pane full of rows builds a
// table once per state change instead of once per row per rebuild — the handle
// table alone walks the whole roster.

const Map<String, AccordMember> _noHandles = {};
const Map<String, AccordRole> _noRoles = {};
const Map<String, AccordChannel> _noChannels = {};
const Map<String, AccordEmoji> _noEmoji = {};

final _handleCache = Expando<Map<String, AccordMember>>('accordHandles');
final _roleCache = Expando<Map<String, AccordRole>>('accordRoles');
final _channelCache = Expando<Map<String, AccordChannel>>('accordChannels');
final _emojiCache = Expando<Map<String, AccordEmoji>>('accordEmoji');

Map<String, AccordMember> _handlesFor(Map<String, AccordMember>? members) {
  if (members == null || members.isEmpty) return _noHandles;
  final cached = _handleCache[members];
  if (cached != null) return cached;
  final byHandle = <String, AccordMember>{};
  for (final member in members.values) {
    final username = member.user?.username;
    if (username != null && username.isNotEmpty) {
      byHandle.putIfAbsent(username.toLowerCase(), () => member);
    }
    final display = member.user?.displayName;
    if (display != null && display.isNotEmpty) {
      byHandle.putIfAbsent(display.toLowerCase(), () => member);
    }
  }
  return _handleCache[members] = byHandle;
}

Map<String, AccordRole> _rolesFor(List<AccordRole>? roles) {
  if (roles == null || roles.isEmpty) return _noRoles;
  return _roleCache[roles] ??= {
    for (final role in roles)
      if (role.mentionable && role.name.isNotEmpty)
        role.name.toLowerCase(): role,
  };
}

Map<String, AccordChannel> _channelsFor(List<AccordChannel>? channels) {
  if (channels == null || channels.isEmpty) return _noChannels;
  final cached = _channelCache[channels];
  if (cached != null) return cached;
  final byName = <String, AccordChannel>{};
  for (final channel in channels) {
    final name = channel.name;
    if (name != null && name.isNotEmpty && channel.type != 'category') {
      byName.putIfAbsent(name.toLowerCase(), () => channel);
    }
  }
  return _channelCache[channels] = byName;
}

Map<String, AccordEmoji> _emojiFor(List<AccordEmoji>? emoji) {
  if (emoji == null || emoji.isEmpty) return _noEmoji;
  return _emojiCache[emoji] ??= {
    for (final e in emoji)
      if (e.name.isNotEmpty) e.name.toLowerCase(): e,
  };
}
