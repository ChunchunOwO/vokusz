part of 'accord_home.dart';

/// Sidebar channel list with inline long-press drag-to-reorder for space managers.
class _ChannelDragList extends ConsumerStatefulWidget {
  const _ChannelDragList({
    required this.spaceId,
    required this.channels,
    required this.selectedChannelId,
    required this.onSelect,
    required this.collapsed,
    required this.onToggleCollapsed,
  });

  final String spaceId;
  final List<AccordChannel> channels;
  final String? selectedChannelId;
  final ValueChanged<String> onSelect;
  final Set<String> collapsed;
  final ValueChanged<String> onToggleCollapsed;

  @override
  ConsumerState<_ChannelDragList> createState() => _ChannelDragListState();
}

class _ChannelDragListState extends ConsumerState<_ChannelDragList> {
  late List<ChannelReorderEntry> _items;
  late String _signature;
  bool _persisting = false;
  bool _pendingPersist = false;

  @override
  void initState() {
    super.initState();
    _items = _flatten(widget.channels);
    _signature = _signatureOf(widget.channels);
  }

  @override
  void didUpdateWidget(covariant _ChannelDragList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ignore incoming list churn while our own optimistic PATCHes are landing;
    // we reconcile once at the end of [_persist].
    if (_persisting) return;
    final sig = _signatureOf(widget.channels);
    if (sig != _signature) _resync();
  }

  void _resync() {
    setState(() {
      _items = _flatten(widget.channels);
      _signature = _signatureOf(widget.channels);
    });
  }

  static String _signatureOf(List<AccordChannel> channels) =>
      channelListSignature(channels);

  /// Uncategorized channels, then categories each followed by their children
  /// (see [flattenChannelsForReorder]).
  static List<ChannelReorderEntry> _flatten(List<AccordChannel> channels) =>
      flattenChannelsForReorder(channels, uncategorizedFirst: true);

  /// The items actually shown: every category, plus the children of categories
  /// that aren't collapsed (uncategorized channels are always shown).
  List<ChannelReorderEntry> get _visible => _items
      .where((e) => e.isCategory || !widget.collapsed.contains(e.parentId))
      .toList();

  void _drop(
    ChannelReorderEntry moved,
    String? parentId, {
    ChannelReorderEntry? before,
  }) {
    if (_persisting || identical(moved, before)) return;
    setState(() {
      final block = moved.isCategory
          ? _items
                .where(
                  (e) => identical(e, moved) || e.parentId == moved.channel.id,
                )
                .toList()
          : [moved];
      _items.removeWhere(block.contains);
      if (!moved.isCategory) moved.parentId = parentId;
      var index = before == null ? -1 : _items.indexOf(before);
      if (index < 0) {
        if (parentId == null && !moved.isCategory) {
          index = _items.indexWhere((e) => e.isCategory);
        } else if (parentId != null) {
          index =
              _items.lastIndexWhere(
                (e) => e.channel.id == parentId || e.parentId == parentId,
              ) +
              1;
        }
      }
      _items.insertAll(index < 0 ? _items.length : index, block);
    });
    _schedulePersist();
  }

  Widget _target(
    Widget child,
    String? parentId, {
    ChannelReorderEntry? before,
    bool categories = false,
  }) {
    return DragTarget<ChannelReorderEntry>(
      onWillAcceptWithDetails: (details) =>
          !_persisting &&
          (categories || !details.data.isCategory) &&
          !identical(details.data, before),
      onAcceptWithDetails: (details) =>
          _drop(details.data, parentId, before: before),
      builder: (context, candidates, rejected) => Container(
        color: candidates.isEmpty
            ? null
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        child: child,
      ),
    );
  }

  void _schedulePersist() {
    if (_persisting) {
      _pendingPersist = true;
    } else {
      _persist();
    }
  }

  /// Walks the new ordering and PATCHes any channel whose (parent, position)
  /// changed. Positions count within each bucket (categories share one bucket;
  /// each category's children share another) so siblings stay coherent.
  Future<void> _persist() async {
    final client = ref.read(
      accordAuthProvider.select(
        (s) => s is AccordAuthLoggedIn ? s.client : null,
      ),
    );
    if (client == null) return;
    final notifier = ref.read(
      accordChannelsControllerProvider(
        ref.readActiveServerKey() ?? '',
        widget.spaceId,
      ).notifier,
    );

    final updates = diffChannelPositions(_items);

    if (updates.isEmpty) return;

    _persisting = true;
    try {
      for (final u in updates) {
        final saved = await notifier.updateChannel(
          client,
          u.channelId,
          u.toBody(),
        );
        if (!saved) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppStrings.choose(
                    'Could not move channel',
                    '移动频道失败',
                    context: context,
                  ),
                ),
              ),
            );
          break;
        }
      }
    } finally {
      _persisting = false;
      if (_pendingPersist && mounted) {
        _pendingPersist = false;
        _persist();
      } else if (mounted) {
        _resync();
      }
    }
  }

  Widget _buildItem(BuildContext context, ChannelReorderEntry entry) {
    if (entry.isCategory) {
      final cat = entry.channel;
      return _categoryHeader(
        context,
        cat,
        spaceId: widget.spaceId,
        canManageChannels: true,
        collapsed: widget.collapsed.contains(cat.id),
        onToggle: () => widget.onToggleCollapsed(cat.id),
      );
    }
    final ch = entry.channel;
    return _channelTile(
      context,
      ch,
      spaceId: widget.spaceId,
      selected: ch.id == widget.selectedChannelId,
      canManageChannels: true,
      onTap: () => widget.onSelect(ch.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        for (final entry in visible) ...[
          _target(
            const SizedBox(height: 8),
            entry.isCategory ? null : entry.parentId,
            before: entry,
            categories: entry.isCategory,
          ),
          Draggable<ChannelReorderEntry>(
            key: ValueKey(entry.channel.id),
            data: entry,
            maxSimultaneousDrags: _persisting ? 0 : 1,
            feedback: Material(
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(entry.channel.name ?? entry.channel.id),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.35,
              child: _buildItem(context, entry),
            ),
            child: entry.isCategory
                ? _target(_buildItem(context, entry), entry.channel.id)
                : _buildItem(context, entry),
          ),
        ],
        _target(const SizedBox(height: 24), null, categories: true),
      ],
    );
  }
}
