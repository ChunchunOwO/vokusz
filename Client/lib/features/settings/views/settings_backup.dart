import 'package:bonfire/l10n/ui_copy.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bonfire/features/settings/controllers/settings.dart';
import 'package:bonfire/shared/utils/rest_result_ext.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Export / import of the local client settings (theme, notifications, voice,
/// etc.) as a JSON file. Ports the reference client's profile export/import
/// (`config_export.gd`); secrets (the local MCP token) are stripped on export
/// and never overwritten on import.
class SettingsBackupSection extends ConsumerWidget {
  const SettingsBackupSection({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final json = ref.read(settingsControllerProvider.notifier).exportJson();
    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(json)),
    );
    String? path;
    try {
      path = await FilePicker.platform.saveFile(
        dialogTitle: UiCopy.exportSettings(context: context),
        fileName: 'vokusz-settings.json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
    } catch (_) {
      if (context.mounted) {
        showInfoSnack(
          context,
          UiCopy.couldNotSaveTheSettingsFile(context: context),
        );
      }
      return;
    }
    if (path != null && context.mounted) {
      showInfoSnack(context, UiCopy.settingsExported(context: context));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        dialogTitle: UiCopy.importSettings(context: context),
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
    } catch (_) {
      if (context.mounted) {
        showInfoSnack(
          context,
          UiCopy.couldNotOpenTheSettingsFile(context: context),
        );
      }
      return;
    }
    if (picked == null || picked.files.isEmpty) return; // cancelled
    final bytes = picked.files.first.bytes;
    if (bytes == null) return;
    Map<dynamic, dynamic>? map;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map) map = decoded;
    } catch (_) {
      map = null;
    }
    if (map == null) {
      if (context.mounted) {
        showInfoSnack(
          context,
          UiCopy.thatFileIsNotAValidSettings(context: context),
        );
      }
      return;
    }
    final ok = ref.read(settingsControllerProvider.notifier).importJson(map);
    if (context.mounted) {
      showInfoSnack(
        context,
        ok
            ? UiCopy.settingsImported(context: context)
            : UiCopy.couldNotImportSettings(context: context),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BonfireThemeExtension.of(context);
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.upload_file, color: colors.dirtyWhite),
          title: Text(UiCopy.exportSettings(context: context)),
          subtitle: Text(
            UiCopy.saveYourPreferencesToAJsonFile(context: context),
          ),
          onTap: () => _export(context, ref),
        ),
        ListTile(
          leading: Icon(
            Icons.download_for_offline_outlined,
            color: colors.dirtyWhite,
          ),
          title: Text(UiCopy.importSettings(context: context)),
          subtitle: Text(
            UiCopy.restorePreferencesFromAJsonFile(context: context),
          ),
          onTap: () => _import(context, ref),
        ),
      ],
    );
  }
}
