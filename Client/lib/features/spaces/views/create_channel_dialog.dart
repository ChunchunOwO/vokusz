import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/authentication/repositories/accord_auth.dart';
import 'package:bonfire/features/server/controllers/connections.dart';
import 'package:bonfire/features/spaces/controllers/spaces.dart';
import 'package:bonfire/features/spaces/utils/new_space_permissions.dart';
import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/l10n/ui_copy.dart';
import 'package:bonfire/shared/utils/client_access.dart';
import 'package:bonfire/shared/utils/rest_result_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The rail's + button operates on domains in the current community.
Future<void> showAddChannelDialog(BuildContext context, WidgetRef ref) async {
  final serverKey = ref.readActiveServerKey();
  if (serverKey == null) {
    showInfoSnack(context, UiCopy.connectionUnavailable(context: context));
    return;
  }
  final id = await showDialog<String>(
    context: context,
    builder: (_) => DomainEntryDialog(serverKey: serverKey),
  );
  if (id == null || !context.mounted) return;
  ref.read(accordAuthProvider.notifier).setActiveServer(serverKey);
  context.go('/spaces?space=${Uri.encodeComponent(id)}');
}

class DomainEntryDialog extends ConsumerStatefulWidget {
  const DomainEntryDialog({super.key, required this.serverKey});
  final String serverKey;

  @override
  ConsumerState<DomainEntryDialog> createState() => _DomainEntryDialogState();
}

class _DomainEntryDialogState extends ConsumerState<DomainEntryDialog> {
  final _input = TextEditingController();
  bool? _creating;
  bool _allowIdJoin = true;
  bool _busy = false;
  String? _error;

  String _copy(String en, String zh) =>
      AppStrings.choose(en, zh, context: context);

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _select(bool? creating) => setState(() {
    _creating = creating;
    _input.clear();
    _error = null;
  });

  Future<void> _submit() async {
    if (_busy || _creating == null) return;
    final value = _input.text.trim();
    if (value.isEmpty ||
        (_creating!
            ? value.length > 100
            : !RegExp(r'^[0-9]{1,20}$').hasMatch(value))) {
      setState(
        () => _error = _creating!
            ? _copy(
                'Enter a domain name (1–100 characters).',
                '请输入域名称（1–100 个字符）。',
              )
            : _copy('Enter a valid numeric domain ID.', '请输入有效的数字域 ID。'),
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(accordAuthProvider.notifier);
      final client = auth.clientForKey(widget.serverKey);
      if (client == null) {
        throw StateError(UiCopy.connectionUnavailable(context: context));
      }
      String id;
      if (!_creating!) {
        final result = await auth.joinOnConnection(
          widget.serverKey,
          spaceId: value,
        );
        if (!mounted) return;
        if (result.error != null || result.spaceId == null) {
          setState(
            () => _error =
                result.error ?? _copy('Could not join domain.', '加入域失败。'),
          );
          return;
        }
        id = result.spaceId!;
      } else {
        final result = await client.spaces.create({
          'name': value,
          'public': _allowIdJoin,
        });
        if (!mounted) return;
        final space = result.data;
        if (!result.ok || space is! AccordSpace) {
          setState(
            () => _error = result.errorMessageOr(
              _copy('Could not create domain.', '创建域失败。'),
            ),
          );
          return;
        }
        id = space.id;
        ref
            .read(connectionsControllerProvider.notifier)
            .upsertSpace(widget.serverKey, space);
        if (ref.readActiveServerKey() == widget.serverKey) {
          ref.read(spacesControllerProvider.notifier).upsertSpace(space);
        }
        // Creation has succeeded. A failed optional setup must not invite a
        // retry that creates another domain.
        var partial = false;
        try {
          final normalized = await normalizeNewSpaceEveryoneRole(client, space);
          partial = normalized != null && !normalized.ok;
          if (!mounted) return;
          final channel = await client.spaces.createChannel(id, {
            'name': _copy('Voice', '语音'),
            'type': 'voice',
          });
          partial = partial || !channel.ok;
        } catch (_) {
          partial = true;
        }
        if (!mounted) return;
        if (partial) {
          showInfoSnack(
            context,
            _copy(
              'Domain created. Finish channel setup in domain settings.',
              '域已创建，部分频道配置未完成，可在域设置中继续配置。',
            ),
          );
        }
      }
      if (mounted) Navigator.of(context).pop(id);
    } catch (error) {
      if (mounted) {
        setState(() => _error = _copy('Request failed: $error', '请求失败：$error'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _creating == null
        ? _copy('Join / create domain', '加入 / 创建域')
        : _creating!
        ? _copy('Create domain', '创建域')
        : _copy('Join domain', '加入域');
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_creating == null) ...[
                  OutlinedButton.icon(
                    onPressed: () => _select(false),
                    icon: const Icon(Icons.login),
                    label: Text(_copy('Join domain', '加入域')),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _select(true),
                    icon: const Icon(Icons.add),
                    label: Text(_copy('Create domain', '创建域')),
                  ),
                ] else ...[
                  TextField(
                    key: ValueKey(_creating),
                    controller: _input,
                    autofocus: true,
                    enabled: !_busy,
                    maxLength: _creating! ? 100 : 20,
                    keyboardType: _creating!
                        ? TextInputType.text
                        : TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: _creating!
                          ? _copy('Domain name', '域名称')
                          : _copy('Domain ID', '域 ID'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (_creating!)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _copy('Allow joining by domain ID', '允许通过域 ID 加入'),
                      ),
                      subtitle: Text(
                        _copy(
                          'Creates a public domain; turn off to require invitations.',
                          '开启后为公开域；关闭后需要邀请才能加入。',
                        ),
                      ),
                      value: _allowIdJoin,
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _allowIdJoin = value),
                    )
                  else
                    Text(
                      _copy(
                        'Enter a public domain ID in this community. Private domains require an invitation.',
                        '输入当前社区的公开域 ID；私有域需要邀请才能加入。',
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy
                ? null
                : () => _creating == null
                      ? Navigator.of(context).pop()
                      : _select(null),
            child: Text(
              _creating == null ? _copy('Cancel', '取消') : _copy('Back', '返回'),
            ),
          ),
          if (_creating != null)
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _creating! ? _copy('Create', '创建') : _copy('Join', '加入'),
                    ),
            ),
        ],
      ),
    );
  }
}
