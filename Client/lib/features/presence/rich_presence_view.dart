import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bonfire/features/presence/rich_presence.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// The green activity line under a member's name. Nothing when they have no app.
class RichPresenceLine extends StatelessWidget {
  const RichPresenceLine({super.key, required this.presence});

  final RichPresence presence;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return Text(
      richPresenceLine(presence, context: context),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: colors.green,
        fontSize: 11,
      ),
    );
  }
}

/// Icon, application name, and how long it has been open.
class RichPresenceCard extends StatefulWidget {
  const RichPresenceCard({super.key, required this.presence});

  final RichPresence presence;

  @override
  State<RichPresenceCard> createState() => _RichPresenceCardState();
}

class _RichPresenceCardState extends State<RichPresenceCard> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final theme = Theme.of(context);
    final started = widget.presence.startedAt;
    final elapsed = started == null
        ? Duration.zero
        : DateTime.now().difference(started);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 40,
              height: 40,
              child: _ActivityIcon(
                icon: widget.presence.icon,
                kind: widget.presence.kind,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.presence.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  richPresenceElapsed(
                    widget.presence.kind,
                    elapsed.isNegative ? Duration.zero : elapsed,
                    context: context,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.gray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityIcon extends StatelessWidget {
  const _ActivityIcon({required this.icon, required this.kind});

  final String? icon;
  final RichPresenceKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final bytes = _decode(icon);
    final child = bytes != null
        ? Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true)
        : icon != null && icon!.startsWith('http')
        ? CachedNetworkImage(imageUrl: icon!, fit: BoxFit.cover)
        : ColoredBox(
            color: colors.darkGray,
            child: Icon(_glyph, size: 22, color: colors.dirtyWhite),
          );
    return child;
  }

  IconData get _glyph {
    switch (kind) {
      case RichPresenceKind.playing:
        return Icons.sports_esports;
      case RichPresenceKind.listening:
        return Icons.music_note;
      case RichPresenceKind.using:
        return Icons.apps;
    }
  }

  Uint8List? _decode(String? value) {
    if (value == null || !value.startsWith('data:image')) return null;
    final comma = value.indexOf(',');
    if (comma < 0) return null;
    try {
      return base64Decode(value.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }
}
