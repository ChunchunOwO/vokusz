import 'package:bonfire/features/authentication/models/accord_auth_state.dart';
import 'package:bonfire/features/authentication/models/accord_session.dart';
import 'package:bonfire/features/authentication/repositories/accord_auth.dart';
import 'package:bonfire/features/server/controllers/connections.dart';
import 'package:bonfire/features/server/models/accord_server.dart';
import 'package:bonfire/features/server/views/add_server_dialog.dart';
import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/shared/components/section_header.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Saved servers under the account section. Each row is one server's account;
/// switching it brings that account's domains forward.
class ServerAccountsSection extends ConsumerStatefulWidget {
  const ServerAccountsSection({super.key});

  @override
  ConsumerState<ServerAccountsSection> createState() =>
      _ServerAccountsSectionState();
}

class _ServerAccountsSectionState extends ConsumerState<ServerAccountsSection> {
  List<AccordSession> _saved = const [];
  String? _busyKey;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final accounts = await ref
          .read(accordAuthProvider.notifier)
          .listAccounts();
      if (mounted) setState(() => _saved = accounts);
    } catch (_) {
      // Settings can open before the session box exists. The live account
      // still renders from auth state.
    }
  }

  Future<void> _report(Future<String?> action) async {
    final error = await action;
    if (!mounted || error == null || error.isEmpty) {
      await _reload();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _switchTo(AccordSession session) async {
    setState(() => _busyKey = session.key);
    await _report(ref.read(accordAuthProvider.notifier).useAccount(session));
    if (mounted) setState(() => _busyKey = null);
  }

  Future<void> _edit(AccordSession session) async {
    final next = await showDialog<String>(
      context: context,
      builder: (context) => _ServerAddressDialog(initial: session.server.baseUrl),
    );
    if (next == null || !mounted) return;
    setState(() => _busyKey = session.key);
    await _report(
      ref.read(accordAuthProvider.notifier).updateAccountServer(session, next),
    );
    if (mounted) setState(() => _busyKey = null);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(connectionsControllerProvider, (_, _) => _reload());
    final colors = BonfireThemeExtension.of(context);
    final connections = ref.watch(connectionsControllerProvider);
    final live = ref.watch(
      accordAuthProvider.select(
        (auth) => auth is AccordAuthLoggedIn ? auth.session : null,
      ),
    );
    final accounts = _rows(_saved, live);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(AppStrings.choose('Servers', '服务器', context: context)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            AppStrings.choose(
              'Switch server to use that server\'s account and domains. Edit an address to save it and reconnect.',
              '切换服务器后，使用该服务器上的账号和域。修改地址会保存并重新连接。',
              context: context,
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.gray,
            ),
          ),
        ),
        if (accounts.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              AppStrings.choose(
                'No saved server yet',
                '还没有保存的服务器',
                context: context,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        for (final session in accounts)
          _ServerRow(
            session: session,
            active: _isActive(session, connections, live),
            domains: _domains(session, connections),
            busy: _busyKey == session.key,
            onOpen: () => _switchTo(session),
            onEdit: () => _edit(session),
          ),
        ListTile(
          leading: Icon(Icons.add, color: colors.dirtyWhite),
          title: Text(AppStrings.choose('Add server', '添加服务器', context: context)),
          onTap: () => showAddServerDialog(context),
        ),
      ],
    );
  }

  List<AccordSession> _rows(List<AccordSession> saved, AccordSession? live) {
    if (saved.isNotEmpty) return saved;
    return [if (live != null) live];
  }

  bool _isActive(
    AccordSession session,
    ConnectionsState connections,
    AccordSession? live,
  ) {
    if (connections.activeKey == session.key) return true;
    final active = live;
    return active != null &&
        AccordServer.sameEndpoint(active.server.baseUrl, session.server.baseUrl);
  }

  int? _domains(AccordSession session, ConnectionsState connections) {
    for (final connection in connections.connections) {
      if (connection.key == session.key ||
          AccordServer.sameEndpoint(
            connection.session.server.baseUrl,
            session.server.baseUrl,
          )) {
        return connection.spaces.length;
      }
    }
    return null;
  }
}

class _ServerRow extends StatelessWidget {
  const _ServerRow({
    required this.session,
    required this.active,
    required this.domains,
    required this.busy,
    required this.onOpen,
    required this.onEdit,
  });

  final AccordSession session;
  final bool active;
  final int? domains;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final domainLabel = domains == null
        ? null
        : AppStrings.choose(
            '$domains domains',
            '$domains 个域',
            context: context,
          );
    final detail = [
      session.username,
      if (domainLabel != null) domainLabel,
    ].join(' · ');
    return ListTile(
      leading: Icon(
        active ? Icons.check_circle : Icons.dns_outlined,
        color: active ? colors.primary : colors.dirtyWhite,
      ),
      title: Text(
        session.server.baseUrl,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, color: colors.gray),
            ),
      onTap: active || busy ? null : onOpen,
    );
  }
}

class _ServerAddressDialog extends StatefulWidget {
  const _ServerAddressDialog({required this.initial});

  final String initial;

  @override
  State<_ServerAddressDialog> createState() => _ServerAddressDialogState();
}

class _ServerAddressDialogState extends State<_ServerAddressDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppStrings.choose('Server address', '服务器地址', context: context),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          hintText: 'https://vokusz.shiinasuki.com',
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => Navigator.of(context).pop(_controller.text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.choose('Cancel', '取消', context: context)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(AppStrings.choose('Save', '保存', context: context)),
        ),
      ],
    );
  }
}
