import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/l10n/ui_copy.dart';
import 'package:bonfire/features/developer/controllers/mcp_server_controller.dart';
import 'package:bonfire/shared/components/settings_scaffold.dart';
import 'package:bonfire/shared/components/section_header.dart';
import 'package:bonfire/features/settings/controllers/settings.dart';
import 'package:bonfire/features/settings/models/accord_settings.dart';
import 'package:bonfire/shared/utils/rest_result_ext.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pushes the Developer / Client MCP settings page.
Future<void> showDeveloperSettings(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const DeveloperSettingsPage()));
}

/// Controls the local Client MCP server: enable toggle, bearer token
/// (generate/copy/rotate), port, exposed tool groups, live status, and a
/// recent-activity log. Mirrors the reference client's developer panel.
class DeveloperSettingsPage extends ConsumerWidget {
  const DeveloperSettingsPage({super.key});

  static const _groupLabels = <String, String>{
    'read': 'Read (state, spaces, channels, messages)',
    'navigate': 'Navigate (switch space/channel, open views)',
    'message': 'Message (send, edit, delete, react)',
    'moderate': 'Moderate (kick, ban, timeout)',
    'manage': 'Manage (roles, permissions, member roles)',
    'space_management': 'Space management (space setup, channels, deletion)',
    'voice': 'Voice (join, leave, mute, deafen)',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BonfireThemeExtension.of(context);
    // The page only reads these two settings fields; select them so unrelated
    // settings changes (theme, notifications, …) don't rebuild the page.
    final mcpEnabled = ref.watch(
      settingsControllerProvider.select((s) => s.mcpEnabled),
    );
    final mcpAllowedGroups = ref.watch(
      settingsControllerProvider.select((s) => s.mcpAllowedGroups),
    );
    final controller = ref.read(settingsControllerProvider.notifier);
    final server = ref.watch(mcpServerControllerProvider);

    return SettingsScaffold(
      title: UiCopy.developer(context: context),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          SectionHeader(UiCopy.clientMcpServer(context: context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              UiCopy.exposesALocalModelContextProtocolServer(context: context),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.gray),
            ),
          ),
          SwitchListTile(
            title: Text(UiCopy.enableMcpServer(context: context)),
            subtitle: Text(
              server.listening
                  ? UiCopy.listeningOn127001(
                      context: context,
                      arg0: server.port,
                    )
                  : UiCopy.stopped(context: context),
            ),
            value: mcpEnabled,
            onChanged: (v) => controller.setMcpEnabled(v),
          ),
          if (mcpEnabled) ...[
            const _PortField(),
            const _TokenTile(),
            const Divider(height: 24),
            SectionHeader(UiCopy.exposedToolGroups(context: context)),
            for (final group in AccordSettings.mcpToolGroups)
              CheckboxListTile(
                dense: true,
                title: Text(
                  AppStrings.label(
                    _groupLabels[group] ?? group,
                    context: context,
                  ),
                ),
                value: mcpAllowedGroups.contains(group),
                onChanged: (v) =>
                    controller.setMcpGroupAllowed(group, v ?? false),
              ),
            const Divider(height: 24),
            SectionHeader(
              UiCopy.recentActivity(context: context),
              trailing: TextButton(
                onPressed: () => ref
                    .read(mcpServerControllerProvider.notifier)
                    .clearActivity(),
                child: Text(UiCopy.clear(context: context)),
              ),
            ),
            if (server.activity.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  UiCopy.noToolCallsYet(context: context),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.gray),
                ),
              )
            else
              for (final entry in server.activity.reversed)
                ListTile(
                  dense: true,
                  leading: Icon(
                    entry.ok ? Icons.check_circle : Icons.error,
                    color: entry.ok ? colors.green : colors.red,
                    size: 18,
                  ),
                  title: Text(entry.tool),
                  trailing: Text(
                    _formatTime(entry.time),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.gray),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  static String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}

class _PortField extends ConsumerStatefulWidget {
  const _PortField();

  @override
  ConsumerState<_PortField> createState() => _PortFieldState();
}

class _PortFieldState extends ConsumerState<_PortField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(settingsControllerProvider).mcpPort.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed != null) {
      ref.read(settingsControllerProvider.notifier).setMcpPort(parsed);
    }
    final applied = ref.read(settingsControllerProvider).mcpPort;
    _controller.text = applied.toString();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                isDense: true,
                labelText: UiCopy.port(context: context),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _save,
            child: Text(UiCopy.save(context: context)),
          ),
        ],
      ),
    );
  }
}

class _TokenTile extends ConsumerWidget {
  const _TokenTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BonfireThemeExtension.of(context);
    final token = ref.watch(
      settingsControllerProvider.select((s) => s.mcpToken),
    );
    final masked = token.isEmpty
        ? '(none)'
        : '${token.substring(0, 8)}…${token.substring(token.length - 4)}';
    return ListTile(
      title: Text(UiCopy.bearerToken(context: context)),
      subtitle: Text(
        masked,
        style: TextStyle(fontFamily: 'monospace', color: colors.gray),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: UiCopy.copy(context: context),
            icon: const Icon(Icons.copy, size: 18),
            onPressed: token.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: token));
                    showInfoSnack(
                      context,
                      UiCopy.tokenCopied(context: context),
                    );
                  },
          ),
          IconButton(
            tooltip: UiCopy.regenerate(context: context),
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: () => ref
                .read(settingsControllerProvider.notifier)
                .regenerateMcpToken(),
          ),
        ],
      ),
    );
  }
}
