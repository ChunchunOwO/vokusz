import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/l10n/ui_copy.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/authentication/models/accord_auth_state.dart';
import 'package:bonfire/features/authentication/repositories/accord_auth.dart';
import 'package:bonfire/features/automod/utils/automod_policy.dart';
import 'package:bonfire/features/automod/views/automod_rule_editor.dart';
import 'package:bonfire/features/channels/controllers/accord_channels.dart';
import 'package:bonfire/features/member/utils/permissions.dart';
import 'package:bonfire/features/spaces/controllers/spaces.dart';
import 'package:bonfire/shared/utils/client_access.dart';
import 'package:bonfire/shared/utils/confirm_dialog.dart';
import 'package:bonfire/shared/utils/download_attachment.dart';
import 'package:bonfire/shared/utils/text_prompt_dialog.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showAutomodPanel(BuildContext context, String scope) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.label('AutoMod', context: context)),
          ),
          body: AutomodPanel(scope: scope),
        ),
      ),
    );

/// Rebuild the workbench when its account or permissions change so old evidence
/// and late HTTP responses cannot bleed into a different session.
class AutomodPanel extends ConsumerWidget {
  const AutomodPanel({super.key, this.scope = '*'});
  final String scope;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(accordAuthProvider);
    if (auth is! AccordAuthLoggedIn) {
      return Center(
        child: Text(UiCopy.connectToAServerFirst(context: context)),
      );
    }
    final spaces = ref.watch(spacesControllerProvider) ?? <AccordSpace>[];
    final space = spaces.firstWhereOrNull((s) => s.id == scope);
    final perms = scope == '*'
        ? <String>{}
        : ref.watchAccordPermissions(space, scope);
    final configure =
        auth.session.isAdmin ||
        (scope != '*' &&
            accordHasPermission(perms, AccordPermission.manageSpace));
    final review =
        auth.session.isAdmin ||
        (scope != '*' &&
            accordHasPermission(perms, AccordPermission.moderateMembers));
    if (!configure && !review) {
      return Center(
        child: Text(UiCopy.youDoNotHavePermissionToManage(context: context)),
      );
    }
    final channels = scope == '*'
        ? [
            for (final s in spaces)
              ...?ref.watch(
                accordChannelsControllerProvider(
                  ref.watchActiveServerKey() ?? '',
                  s.id,
                ),
              ),
          ]
        : ref.watch(
                accordChannelsControllerProvider(
                  ref.watchActiveServerKey() ?? '',
                  scope,
                ),
              ) ??
              <AccordChannel>[];
    return AutomodWorkbench(
      key: ValueKey((auth.client, scope, configure, review)),
      client: auth.client,
      scope: scope,
      canConfigure: configure,
      canReview: review,
      roles: scope == '*'
          ? [for (final s in spaces) ...s.roles]
          : space?.roles ?? const [],
      channels: channels,
    );
  }
}

class AutomodWorkbench extends StatefulWidget {
  const AutomodWorkbench({
    super.key,
    required this.client,
    required this.scope,
    required this.canConfigure,
    required this.canReview,
    this.roles = const [],
    this.channels = const [],
  });
  final AccordClient client;
  final String scope;
  final bool canConfigure, canReview;
  final List<AccordRole> roles;
  final List<AccordChannel> channels;
  @override
  State<AutomodWorkbench> createState() => _AutomodWorkbenchState();
}

class _AutomodWorkbenchState extends State<AutomodWorkbench> {
  Map<String, dynamic>? _policy, _health;
  List<Map<String, dynamic>> _uploads = [], _hashes = [], _events = [];
  bool _inherited = false, _loading = true, _busy = false, _dirty = false;
  String? _error;
  String _status = 'quarantined';
  int _generation = 0;
  StreamSubscription<AccordAutomodUploadStatus>? _subscription;
  Timer? _refreshTimer;
  DialogRoute<void>? _evidenceRoute;
  NavigatorState? _evidenceNavigator;
  AutomodApi get _api => widget.client.automod;
  @override
  void initState() {
    super.initState();
    _subscription = widget.client.onAutomodUploadUpdate.listen((event) {
      if (widget.scope != '*' && event.spaceId != widget.scope) return;
      _refreshTimer?.cancel();
      _refreshTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted && !_busy && !_loading) _load();
      });
    });
    _load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _refreshTimer?.cancel();
    _generation++;
    final route = _evidenceRoute;
    final navigator = _evidenceNavigator;
    if (route != null && navigator != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.isActive) navigator.removeRoute(route);
      });
    }
    super.dispose();
  }

  List<Map<String, dynamic>> _rows(Object? data) => data is List
      ? data.whereType<Map>().map((r) => r.cast<String, dynamic>()).toList()
      : [];
  String _failure(RestResult result) =>
      result.statusCode == 404 ||
          result.statusCode == 405 ||
          result.statusCode == 501
      ? UiCopy.thisServerDoesNotSupportThisAutomod()
      : result.statusCode == 403
      ? UiCopy.yourServerPermissionsDoNotAllowThis()
      : result.error?.message ?? 'The request failed. Try again.';
  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    final requests = <String, Future<RestResult>>{
      if (widget.canConfigure) 'policy': _api.getPolicy(widget.scope),
      if (widget.canConfigure) 'hashes': _api.listHashes(widget.scope),
      if (widget.canReview)
        'uploads': _api.listUploads(widget.scope, status: _status),
      if (widget.canReview) 'events': _api.events(widget.scope),
      if (widget.scope == '*') 'health': _api.health(),
    };
    final values = await Future.wait(requests.values);
    if (!mounted || generation != _generation) return;
    setState(() {
      for (var i = 0; i < values.length; i++) {
        final result = values[i], key = requests.keys.elementAt(i);
        if (!result.ok) {
          _error ??= _failure(result);
          continue;
        }
        switch (key) {
          case 'policy':
            if (!_dirty) {
              final envelope = automodMap(result.data);
              _policy = copyAutomodJson(automodMap(envelope['policy']));
              _inherited = envelope['inherited'] == true;
            }
          case 'hashes':
            _hashes = _rows(result.data);
          case 'uploads':
            _uploads = _rows(result.data);
          case 'events':
            _events = _rows(result.data);
          case 'health':
            _health = automodMap(result.data);
        }
      }
      _loading = false;
    });
  }

  Future<void> _mutate(
    Future<RestResult> Function() request, {
    bool policy = false,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await request();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!result.ok) {
        _error = _failure(result);
      } else if (policy) {
        _dirty = false;
      }
    });
    if (result.ok) await _load();
  }

  void _edit(VoidCallback update) => setState(() {
    update();
    _dirty = true;
  });
  Future<void> _rule([int? index]) async {
    final rules = automodList(_policy?['rules']);
    final edited = await editAutomodRule(
      context,
      rule: index == null ? null : automodMap(rules[index]),
      channels: widget.channels,
    );
    if (!mounted || edited == null) return;
    _edit(() {
      if (index == null) {
        rules.add(edited);
      } else {
        rules[index] = edited;
      }
      _policy!['rules'] = rules;
    });
  }

  Future<String?> _reason(String title) async {
    final reason = await showTextPromptDialog(
      context,
      title: title,
      label: UiCopy.reason(),
      confirmLabel: UiCopy.continueAction(),
    );
    if (!mounted || reason == null) return null;
    if (reason.trim().isEmpty || utf8.encode(reason.trim()).length > 2000) {
      setState(() => _error = UiCopy.enterAReasonOf12000Utf());
      return null;
    }
    return reason.trim();
  }

  Future<void> _blockDigest() async {
    final hash = await showTextPromptDialog(
      context,
      title: UiCopy.blockFileDigest(),
      label: UiCopy.sha256Digest(),
      helperText: UiCopy.message64HexadecimalCharactersFromAKnownFile(),
    );
    if (!mounted || hash == null) return;
    final digest = hash.trim().toLowerCase();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) {
      setState(() => _error = UiCopy.enterAValid64CharacterSha256());
      return;
    }
    final reason = await _reason(UiCopy.whyBlockThisFile());
    if (!mounted || reason == null) return;
    await _mutate(() => _api.blockHash(widget.scope, digest, reason));
  }

  Future<void> _review(Map<String, dynamic> upload, String action) async {
    final reason = await _reason(
      '${action[0].toUpperCase()}${action.substring(1)} attachment',
    );
    if (!mounted || reason == null || reason.trim().isEmpty) return;
    await _mutate(
      () => _api.review(asString(upload['id']), action, reason.trim()),
    );
  }

  Future<void> _content(Map<String, dynamic> upload) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await _api.getContent(asString(upload['id']));
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.ok || result.data is! Uint8List) {
      setState(
        () => _error = result.statusCode == 404 || result.statusCode == 410
            ? UiCopy.thisEvidenceHasExpiredOrIsNo()
            : _failure(result),
      );
      return;
    }
    final bytes = result.data as Uint8List;
    final filename = sanitizeAttachmentFilename(
      asString(upload['filename'], 'evidence.bin'),
    );
    // The private API authenticates the download. Never hand its URL/token to
    // an unauthenticated browser, CDN widget, external viewer or persistent cache.
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<void>(
      context: context,
      builder: (context) => !mounted
          ? const SizedBox.shrink()
          : AlertDialog(
              title: Text(filename),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (asString(upload['content_type']).startsWith('image/'))
                      Flexible(
                        child: Image.memory(
                          bytes,
                          cacheWidth: 800,
                          errorBuilder: (_, _, _) => Text(
                            UiCopy.noImagePreviewAvailableDownloadToReview(),
                          ),
                        ),
                      )
                    else
                      Text(UiCopy.downloadThisPrivateOriginalToReviewIt()),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(UiCopy.close()),
                ),
                TextButton(
                  onPressed: () async {
                    if (!mounted) return;
                    try {
                      await FilePicker.platform.saveFile(
                        fileName: filename,
                        bytes: bytes,
                      );
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(UiCopy.couldNotSaveTheEvidence()),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(UiCopy.downloadOriginal()),
                ),
              ],
            ),
    );
    _evidenceRoute = route;
    _evidenceNavigator = navigator;
    await navigator.push(route);
    _evidenceRoute = null;
    _evidenceNavigator = null;
    await ResizeImage.resizeIfNeeded(800, null, MemoryImage(bytes)).evict();
  }

  Future<void> _more(String kind) async {
    if (_busy) return;
    final rows = kind == 'uploads'
        ? _uploads
        : kind == 'hashes'
        ? _hashes
        : _events;
    if (rows.isEmpty) return;
    setState(() => _busy = true);
    final before = asString(rows.last[kind == 'hashes' ? 'hash' : 'id']);
    final result = await (kind == 'uploads'
        ? _api.listUploads(widget.scope, status: _status, before: before)
        : kind == 'hashes'
        ? _api.listHashes(widget.scope, before: before)
        : _api.events(widget.scope, before: before));
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.ok) {
        rows.addAll(_rows(result.data));
      } else {
        _error = _failure(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      if (widget.canConfigure) UiCopy.rules(context: context),
      if (widget.canReview) UiCopy.review(context: context),
      if (widget.canConfigure) UiCopy.blockedFiles(context: context),
      if (widget.canReview) UiCopy.activity(context: context),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TabBar(
                  isScrollable: true,
                  tabs: [for (final title in tabs) Tab(text: title)],
                ),
              ),
              IconButton(
                tooltip: UiCopy.refreshAutomod(context: context),
                onPressed: _loading || _busy ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (_loading || _busy) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: TabBarView(
              children: [
                if (widget.canConfigure) _rules(),
                if (widget.canReview) _queue(),
                if (widget.canConfigure) _blocked(),
                if (widget.canReview) _activity(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rules() {
    final policy = _policy;
    if (policy == null) return Center(child: Text(UiCopy.noPolicyLoaded()));
    final rules = automodList(policy['rules']);
    final exemptions = automodList(
      policy['exempt_roles'],
    ).map((v) => '$v').toSet();
    final permissions = automodList(
      policy['exempt_permissions'],
    ).map((v) => '$v').toSet();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_health != null)
          Text(
            AppStrings.choose(
              'Detector: ${_health!['scanner']}',
              '检测器：${_health!['scanner']}',
              context: context,
            ),
          ),
        if (_health != null)
          Text(UiCopy.videoSampler(arg0: _health!['video_sampler'])),
        if (_health != null)
          Text(
            UiCopy.queueCapacityUploadsMib(
              arg0: _health!['max_held'],
              arg1: ((asInt(_health!['max_held_bytes'])) / (1024 * 1024))
                  .round(),
            ),
          ),
        if (_health != null)
          for (final row in automodList(_health!['uploads']))
            Text('${row['status']}: ${row['count']} uploads'),
        if (_health != null && _health!['scanner'] != 'ready')
          Text(UiCopy.askTheServerOperatorToInstallConfigure()),
        if (_inherited) Text(UiCopy.usingTheServerPolicySavingCreatesA()),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(UiCopy.enableAutomaticScanning()),
          value: policy['enabled'] == true,
          onChanged: _busy ? null : (v) => _edit(() => policy['enabled'] = v),
        ),
        Text(UiCopy.explicitFileBlocksAndUploadLimitsWork()),
        TextFormField(
          key: ObjectKey(policy),
          initialValue: '${policy['retention_days']}',
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: UiCopy.keepHeldEvidenceDays190(),
          ),
          onChanged: (v) =>
              _edit(() => policy['retention_days'] = int.tryParse(v)),
        ),
        const SizedBox(height: 12),
        Text(UiCopy.exemptRoles()),
        Wrap(
          spacing: 6,
          children: [
            for (final role in widget.roles)
              FilterChip(
                label: Text(role.name),
                selected: exemptions.contains(role.id),
                onSelected: _busy
                    ? null
                    : (v) => _edit(() {
                        if (v) {
                          exemptions.add(role.id);
                        } else {
                          exemptions.remove(role.id);
                        }
                        policy['exempt_roles'] = exemptions.toList();
                      }),
              ),
            for (final id in exemptions.where(
              (id) => !widget.roles.any((r) => r.id == id),
            ))
              InputChip(
                label: Text(
                  AppStrings.choose('Role $id', '角色 $id', context: context),
                ),
                onDeleted: () => _edit(() {
                  exemptions.remove(id);
                  policy['exempt_roles'] = exemptions.toList();
                }),
              ),
          ],
        ),
        Text(UiCopy.exemptPermissions()),
        Wrap(
          spacing: 6,
          children: [
            for (final permission in {
              ...permissions,
              'manage_messages',
              'manage_channels',
              'moderate_members',
            })
              FilterChip(
                label: Text(permission.replaceAll('_', ' ')),
                selected: permissions.contains(permission),
                onSelected: _busy
                    ? null
                    : (v) => _edit(() {
                        if (v) {
                          permissions.add(permission);
                        } else {
                          permissions.remove(permission);
                        }
                        policy['exempt_permissions'] = permissions.toList();
                      }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(UiCopy.rulesRunInOrderTheFirstMatch()),
        for (var i = 0; i < rules.length; i++)
          Card(
            child: ListTile(
              title: Text(asString(rules[i]['id'])),
              subtitle: Text(
                '${AppStrings.label(asString(automodTriggers[rules[i]['trigger']['type']] ?? rules[i]['trigger']['type']), context: context)} · ${AppStrings.label(asString(automodActions[rules[i]['action']['type']] ?? rules[i]['action']['type']), context: context)}',
              ),
              onTap: _busy ? null : () => _rule(i),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: UiCopy.moveRuleUp(),
                    onPressed: _busy || i == 0
                        ? null
                        : () => _edit(() {
                            final r = rules.removeAt(i);
                            rules.insert(i - 1, r);
                            policy['rules'] = rules;
                          }),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  IconButton(
                    tooltip: UiCopy.deleteRule(),
                    onPressed: _busy
                        ? null
                        : () => _edit(() {
                            rules.removeAt(i);
                            policy['rules'] = rules;
                          }),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        Wrap(
          spacing: 12,
          children: [
            TextButton.icon(
              onPressed: _busy || rules.length >= 32 ? null : () => _rule(),
              icon: const Icon(Icons.add),
              label: Text(UiCopy.addRule()),
            ),
            FilledButton(
              onPressed: !_dirty || _busy
                  ? null
                  : () {
                      final error = validateAutomodPolicy(policy);
                      if (error != null) {
                        setState(() => _error = error);
                        return;
                      }
                      _mutate(
                        () => _api.setPolicy(
                          widget.scope,
                          copyAutomodJson(policy),
                        ),
                        policy: true,
                      );
                    },
              child: Text(UiCopy.savePolicy()),
            ),
            if (widget.scope != '*')
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: UiCopy.useServerPolicy(),
                          message: UiCopy.thisRemovesThisSpaceSOverrideAnd(),
                          confirmLabel: UiCopy.useServerPolicy2(),
                        );
                        if (mounted && confirmed == true) {
                          await _mutate(
                            () => _api.resetPolicy(widget.scope),
                            policy: true,
                          );
                        }
                      },
                child: Text(UiCopy.useServerPolicy2()),
              ),
          ],
        ),
      ],
    );
  }

  Widget _queue() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      DropdownButton<String>(
        value: _status,
        items: [
          for (final s in [
            'quarantined',
            'pending',
            'rejected',
            'published',
            'removed',
          ])
            DropdownMenuItem(value: s, child: Text(s)),
        ],
        onChanged: _busy
            ? null
            : (v) {
                setState(() => _status = v!);
                _load();
              },
      ),
      if (_uploads.isEmpty && !_loading) Text(UiCopy.noUploadsWithThisStatus()),
      for (final upload in _uploads)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asString(upload['filename'], UiCopy.attachment()),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Status: ${upload['status']} · Uploader: ${upload['author_id']}',
                ),
                if (asString(upload['reason']).isNotEmpty)
                  Text(asString(upload['reason'])),
                if (upload['result'] != null)
                  Text(_scanSummary(upload['result'])),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: _busy || upload['status'] == 'removed'
                          ? null
                          : () => _content(upload),
                      child: Text(UiCopy.viewEvidence()),
                    ),
                    for (final action in [
                      'release',
                      'quarantine',
                      'reject',
                      'retry',
                      'remove',
                    ])
                      if (upload['status'] != 'removed' &&
                          !(action == 'release' &&
                              upload['status'] == 'published'))
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _review(upload, action),
                          child: Text(
                            action[0].toUpperCase() + action.substring(1),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ),
      if (_uploads.length >= 100)
        TextButton(
          onPressed: _busy ? null : () => _more('uploads'),
          child: Text(UiCopy.loadOlderUploads()),
        ),
    ],
  );
  Widget _blocked() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(UiCopy.exactFileBlocksRemainActiveWithoutModel()),
      TextButton.icon(
        onPressed: _busy ? null : _blockDigest,
        icon: const Icon(Icons.block),
        label: Text(UiCopy.blockFileDigest()),
      ),
      if (_hashes.isEmpty && !_loading)
        Text(UiCopy.noBlockedFilesInThisScope()),
      for (final row in _hashes)
        Card(
          child: ListTile(
            title: SelectableText(asString(row['hash'])),
            subtitle: Text(
              '${row['reason']}\nAdded by ${row['added_by'] ?? 'unknown'}${row['created_at'] == null ? '' : ' · ${DateTime.fromMillisecondsSinceEpoch(asInt(row['created_at']) * 1000).toLocal()}'}',
            ),
            trailing: IconButton(
              tooltip: UiCopy.unblockFile(),
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy
                  ? null
                  : () async {
                      final ok = await showConfirmDialog(
                        context,
                        title: UiCopy.unblockFile2(),
                        message:
                            UiCopy.identicalCopiesWillBeAllowedUnlessAnother(),
                        confirmLabel: UiCopy.unblock(),
                      );
                      if (mounted && ok == true) {
                        await _mutate(
                          () => _api.unblockHash(
                            widget.scope,
                            asString(row['hash']),
                          ),
                        );
                      }
                    },
            ),
          ),
        ),
      if (_hashes.length >= 100)
        TextButton(
          onPressed: _busy ? null : () => _more('hashes'),
          child: Text(UiCopy.loadOlderBlocks()),
        ),
    ],
  );
  Map<String, dynamic> _decodeDetails(Object? value) {
    if (value is String) {
      try {
        return automodMap(jsonDecode(value));
      } catch (_) {
        return {};
      }
    }
    return automodMap(value);
  }

  String _timestamp(Object? value) => value is num
      ? DateTime.fromMillisecondsSinceEpoch(
          value.toInt() * 1000,
        ).toLocal().toString()
      : '';
  String _scanSummary(Object? value) {
    final result = _decodeDetails(value);
    final scores = automodMap(result['scores']);
    return [
      for (final entry in scores.entries)
        if (entry.value is num)
          '${entry.key.replaceAll('_', ' ').toLowerCase()}: ${((entry.value as num) * 100).toStringAsFixed(1)}%',
      if (automodList(result['sampled_timestamps_ms']).isNotEmpty)
        'Video samples (seconds): ${automodList(result['sampled_timestamps_ms']).whereType<num>().map((v) => (v / 1000).toStringAsFixed(1)).join(', ')}',
    ].join('\n');
  }

  String _detailsSummary(Object? value) {
    final details = _decodeDetails(value);
    return [
      if (details['reason'] != null) asString(details['reason']),
      if (details['rule_id'] != null) AppStrings.choose('Rule: ${details['rule_id']}', '规则：${details['rule_id']}'),
      if (details['hash'] != null) AppStrings.choose('File digest: ${details['hash']}', '文件指纹：${details['hash']}'),
      if (details['error'] != null) asString(details['error']),
    ].join('\n');
  }

  Widget _activity() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (_events.isEmpty && !_loading) Text(UiCopy.noModerationActivity()),
      for (final row in _events)
        ListTile(
          title: Text(asString(row['action'])),
          subtitle: SelectableText(
            AppStrings.choose('Actor: ${row['actor_id'] ?? 'AutoMod'} · ${_timestamp(row['created_at'])}\n${_detailsSummary(row['details'])}', '操作人：${row['actor_id'] ?? AppStrings.label('AutoMod')} · ${_timestamp(row['created_at'])}\n${_detailsSummary(row['details'])}'),
          ),
        ),
      if (_events.length >= 100)
        TextButton(
          onPressed: _busy ? null : () => _more('events'),
          child: Text(UiCopy.loadOlderActivity()),
        ),
    ],
  );
}
