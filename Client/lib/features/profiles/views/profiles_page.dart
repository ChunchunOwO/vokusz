import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/l10n/ui_copy.dart';
import 'package:bonfire/features/profiles/controllers/profiles_controller.dart';
import 'package:bonfire/shared/utils/confirm_dialog.dart';
import 'package:bonfire/shared/utils/rest_result_ext.dart';
import 'package:bonfire/shared/utils/text_prompt_dialog.dart';
import 'package:bonfire/shared/components/label_pill.dart';
import 'package:bonfire/shared/components/settings_scaffold.dart';
import 'package:bonfire/features/profiles/models/device_profile.dart';
import 'package:bonfire/features/profiles/utils/profile_pin_security.dart';
import 'package:bonfire/features/profiles/views/app_restart.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the device-profiles management page (create / switch / rename / delete
/// / casually PIN-lock local profiles). Ports the reference's
/// `user_settings_profiles_page.gd`.
Future<void> showProfilesSettings(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const ProfilesScreen()));
}

class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BonfireThemeExtension.of(context);
    final profiles = ref.watch(profilesControllerProvider);
    final notifier = ref.read(profilesControllerProvider.notifier);
    final activeId = notifier.activeId;

    return SettingsScaffold(
      title: UiCopy.deviceProfiles(context: context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createProfile(context, ref),
        icon: const Icon(Icons.add),
        label: Text(UiCopy.newProfile(context: context)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              UiCopy.profilesAreIsolatedLocalSpacesEachWith(
                context: context,
                arg0: AppStrings.label(profilePinSecurityNotice, context: context),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: colors.gray),
            ),
          ),
          for (final p in profiles)
            _ProfileTile(
              profile: p,
              isActive: p.id == activeId,
              onSwitch: () => _switch(context, ref, p.id),
              onRename: () => _rename(context, ref, p),
              onDelete: p.isDefault ? null : () => _delete(context, ref, p),
              onTogglePin: () => _togglePin(context, ref, p),
            ),
        ],
      ),
    );
  }

  Future<void> _switch(BuildContext context, WidgetRef ref, String id) async {
    final notifier = ref.read(profilesControllerProvider.notifier);
    if (id == notifier.activeId) return;
    await notifier.switchProfile(id);
    if (context.mounted) AppRestart.restart(context);
  }

  Future<void> _createProfile(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String name, String pin})>(
      context: context,
      builder: (_) => const _CreateProfileDialog(),
    );
    if (result == null || result.name.trim().isEmpty) return;
    ref
        .read(profilesControllerProvider.notifier)
        .create(result.name, pin: result.pin.isEmpty ? null : result.pin);
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    DeviceProfile p,
  ) async {
    final name = await showTextPromptDialog(
      context,
      title: UiCopy.renameProfile(context: context),
      initial: p.name,
      confirmLabel: UiCopy.ok(context: context),
    );
    if (name == null) return;
    ref.read(profilesControllerProvider.notifier).rename(p.id, name);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    DeviceProfile p,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: UiCopy.deleteProfile(context: context),
      message: UiCopy.deleteAndAllItsAccountsAndSettings(
        context: context,
        arg0: p.name,
      ),
      confirmLabel: UiCopy.delete(context: context),
      danger: true,
    );
    if (confirmed != true) return;
    await ref.read(profilesControllerProvider.notifier).delete(p.id);
  }

  Future<void> _togglePin(
    BuildContext context,
    WidgetRef ref,
    DeviceProfile p,
  ) async {
    final notifier = ref.read(profilesControllerProvider.notifier);
    if (p.hasPin) {
      // Require the current PIN before clearing it.
      final pin = await showTextPromptDialog(
        context,
        title: UiCopy.enterCurrentPinToRemove(context: context),
        obscureText: true,
        keyboardType: TextInputType.number,
        confirmLabel: UiCopy.ok(context: context),
      );
      if (pin == null) return;
      if (!notifier.verifyPin(p.id, pin)) {
        if (context.mounted) {
          showInfoSnack(context, UiCopy.incorrectPin(context: context));
        }
        return;
      }
      notifier.setPin(p.id, null);
      return;
    }
    final pin = await showTextPromptDialog(
      context,
      title: UiCopy.setAPin(context: context),
      obscureText: true,
      keyboardType: TextInputType.number,
      helperText: AppStrings.label(profilePinSecurityNotice, context: context),
      confirmLabel: UiCopy.ok(context: context),
    );
    if (pin == null || pin.isEmpty) return;
    notifier.setPin(p.id, pin);
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.isActive,
    required this.onSwitch,
    required this.onRename,
    required this.onDelete,
    required this.onTogglePin,
  });

  final DeviceProfile profile;
  final bool isActive;
  final VoidCallback onSwitch;
  final VoidCallback onRename;
  final VoidCallback? onDelete;
  final VoidCallback onTogglePin;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isActive ? colors.primary : colors.darkGray,
        child: Icon(
          profile.hasPin ? Icons.lock : Icons.person,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Flexible(child: Text(profile.name, overflow: TextOverflow.ellipsis)),
          if (isActive) ...[
            const SizedBox(width: 8),
            LabelPill(
              UiCopy.active(context: context),
              color: colors.primary,
              filled: true,
            ),
          ],
        ],
      ),
      subtitle: Text(
        profile.hasPin
            ? UiCopy.casualPinLockNotEncrypted(context: context)
            : UiCopy.noPin(context: context),
        style: Theme.of(
          context,
        ).textTheme.bodySmall!.copyWith(color: colors.gray),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          switch (v) {
            case 'switch':
              onSwitch();
            case 'rename':
              onRename();
            case 'pin':
              onTogglePin();
            case 'delete':
              onDelete?.call();
          }
        },
        itemBuilder: (_) => [
          if (!isActive)
            PopupMenuItem(
              value: 'switch',
              child: Text(UiCopy.switchTo(context: context)),
            ),
          PopupMenuItem(
            value: 'rename',
            child: Text(UiCopy.rename(context: context)),
          ),
          PopupMenuItem(
            value: 'pin',
            child: Text(
              profile.hasPin
                  ? UiCopy.removePin(context: context)
                  : UiCopy.setPin(context: context),
            ),
          ),
          if (onDelete != null)
            PopupMenuItem(
              value: 'delete',
              child: Text(UiCopy.delete(context: context)),
            ),
        ],
      ),
    );
  }
}

/// Dialog collecting a new profile's name and optional PIN.
class _CreateProfileDialog extends StatefulWidget {
  const _CreateProfileDialog();

  @override
  State<_CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends State<_CreateProfileDialog> {
  final _name = TextEditingController();
  final _pin = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(UiCopy.newProfile(context: context)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: UiCopy.profileName(context: context),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: UiCopy.pinOptional(context: context),
              helperText: AppStrings.label(profilePinSecurityNotice, context: context),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(UiCopy.cancel(context: context)),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop((name: _name.text, pin: _pin.text)),
          child: Text(UiCopy.create(context: context)),
        ),
      ],
    );
  }
}
