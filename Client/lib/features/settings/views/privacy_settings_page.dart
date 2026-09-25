import 'package:bonfire/l10n/ui_copy.dart';
import 'dart:convert';
import 'package:bonfire/shared/components/settings_scaffold.dart';
import 'package:bonfire/shared/utils/rest_result_ext.dart';
import 'package:bonfire/shared/utils/confirm_dialog.dart';
import 'package:bonfire/shared/components/section_header.dart';
import 'package:bonfire/shared/utils/client_access.dart';
import 'dart:typed_data';

import 'package:accordkit/accordkit.dart';
import 'package:bonfire/features/spaces/controllers/spaces.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the Privacy & Data settings page (GDPR data export, per-space
/// leave-and-delete, and deletion/retention information). Ports the reference
/// client's `server_settings.gd` `_build_privacy_page`.
Future<void> showPrivacySettings(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()));
}

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key, this.embedded = false});

  /// When true, renders the privacy content on its own — no [SettingsScaffold]
  /// chrome and no internal scroll view — so the wide settings layout can
  /// inline it as a card in the Account pane instead of pushing a route.
  final bool embedded;

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _exporting = false;
  String? _exportStatus;
  bool _exportFailed = false;

  /// Space ids with a leave-and-delete in flight, so their buttons disable
  /// independently.
  final Set<String> _leaving = {};

  AccordClient? get _client => ref.accordClient;

  Future<void> _requestExport() async {
    final client = _client;
    if (client == null || _exporting) return;
    setState(() {
      _exporting = true;
      _exportStatus = null;
    });
    final result = await client.users.requestDataExport();
    if (!mounted) return;
    if (!result.ok) {
      setState(() {
        _exporting = false;
        _exportFailed = true;
        _exportStatus = UiCopy.exportFailedPleaseTryAgain();
      });
      return;
    }

    // The export is JSON (profile, messages, relationships). Offer a save
    // dialog; file_picker writes the bytes itself on every platform (desktop,
    // mobile, and web-as-download).
    final jsonStr = const JsonEncoder.withIndent('  ').convert(result.data);
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
    String? path;
    try {
      path = await FilePicker.platform.saveFile(
        dialogTitle: UiCopy.saveDataExport(),
        fileName: 'vokusz-data-export.json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _exporting = false;
        _exportFailed = true;
        _exportStatus = UiCopy.couldNotSaveTheExportFile();
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _exporting = false;
      _exportFailed = path == null;
      _exportStatus = path == null
          ? UiCopy.exportCancelled()
          : UiCopy.dataExportedSuccessfully();
    });
  }

  Future<void> _leaveAndDelete(AccordSpace space) async {
    final client = _client;
    if (client == null || _leaving.contains(space.id)) return;
    final confirmed = await showConfirmDialog(
      context,
      title: UiCopy.leaveDeleteData(),
      message: UiCopy.thisWillPermanentlyLeaveAndDeleteAll(arg0: space.name),
      confirmLabel: UiCopy.leaveDelete(),
      danger: true,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _leaving.add(space.id));
    final result = await client.members.leaveMe(space.id, deleteData: true);
    if (!mounted) return;
    setState(() => _leaving.remove(space.id));
    if (!result.ok) {
      showErrorSnack(context, result, prefix: UiCopy.failed());
      return;
    }
    // Drop the space from the cache immediately; the gateway member.leave echo
    // would do this too, but the local update keeps the page in sync.
    ref.read(spacesControllerProvider.notifier).removeSpace(space.id);
    showInfoSnack(context, UiCopy.leftAndDeletedYourData(arg0: space.name));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(UiCopy.privacyData(context: context)),
          ..._content(),
        ],
      );
    }
    return SettingsScaffold(
      title: UiCopy.privacyData(context: context),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: _content(),
      ),
    );
  }

  /// The page body, as a flat child list so it can be poured into either a
  /// [ListView] (pushed page) or a [Column] (embedded card).
  List<Widget> _content() {
    final colors = BonfireThemeExtension.of(context);
    final spaces = ref.watch(spacesControllerProvider) ?? const <AccordSpace>[];
    final userId = ref.watchUserId();

    return [
      SectionHeader(UiCopy.dataExport()),
      _Body(UiCopy.downloadACopyOfYourPersonalData()),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Row(
          children: [
            // Flexible so the label wraps rather than overflowing inside a
            // narrow settings card (notably at 150% UI scale).
            Flexible(
              child: FilledButton.icon(
                onPressed: _exporting ? null : _requestExport,
                icon: _exporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  _exporting ? UiCopy.exporting() : UiCopy.requestDataExport(),
                ),
              ),
            ),
          ],
        ),
      ),
      if (_exportStatus != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            _exportStatus!,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: _exportFailed ? colors.red : colors.green,
            ),
          ),
        ),
      const Divider(height: 24),
      SectionHeader(UiCopy.leaveDeleteData2()),
      _Body(UiCopy.leaveAServerAndPermanentlyDeleteAll()),
      if (spaces.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            UiCopy.youAreNotInAnySpaces(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: colors.gray),
          ),
        )
      else
        for (final space in spaces)
          _SpaceLeaveTile(
            name: space.name,
            isOwner: userId != null && space.ownerId == userId,
            busy: _leaving.contains(space.id),
            onLeave: () => _leaveAndDelete(space),
          ),
      const Divider(height: 24),
      SectionHeader(UiCopy.dataDeletion()),
      _Body(UiCopy.whenYouDeleteYourAccountAllPersonal()),
      const Divider(height: 24),
      SectionHeader(UiCopy.dataRetention()),
      _Body(UiCopy.dataIsRetainedForAsLongAs()),
      const SizedBox(height: 12),
    ];
  }
}

class _SpaceLeaveTile extends StatelessWidget {
  const _SpaceLeaveTile({
    required this.name,
    required this.isOwner,
    required this.busy,
    required this.onLeave,
  });

  final String name;
  final bool isOwner;
  final bool busy;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return ListTile(
      title: Text(name, overflow: TextOverflow.ellipsis),
      subtitle: isOwner
          ? Text(
              UiCopy.youAreTheOwnerTransferOwnershipBefore(context: context),
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: colors.gray),
            )
          : null,
      trailing: isOwner
          ? null
          : busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.red,
                side: BorderSide(color: colors.red),
              ),
              onPressed: onLeave,
              child: Text(UiCopy.leaveDelete(context: context)),
            ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall!.copyWith(color: colors.gray),
      ),
    );
  }
}
