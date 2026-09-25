import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/l10n/ui_copy.dart';
import 'package:accordkit/accordkit.dart';
import 'package:bonfire/shared/components/async_state_views.dart';
import 'package:bonfire/shared/utils/rest_result_ext.dart';
import 'package:bonfire/shared/utils/client_access.dart';
import 'package:bonfire/shared/utils/responsive_dialog.dart';
import 'package:bonfire/features/authentication/models/accord_auth_state.dart';
import 'package:bonfire/features/authentication/repositories/accord_auth.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Extracts the bare TOTP secret from an `otpauth://` URI, or returns the
/// input unchanged when it is not an otpauth URI (e.g. already a plain secret).
///
/// `otpauth://totp/label?secret=BASE32SECRET&issuer=…` → `BASE32SECRET`
String? extractTotpSecret(String? uri) {
  if (uri == null) return null;
  final match = RegExp(
    r'[?&]secret=([^&]+)',
    caseSensitive: false,
  ).firstMatch(uri);
  return match?.group(1) ?? uri;
}

/// Opens the account settings dialog: change password and manage two-factor
/// authentication. The Accord analogue of a "My Account" panel.
Future<void> showAccordAccountSettings(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _AccountSettingsDialog(),
  );
}

class _AccountSettingsDialog extends ConsumerStatefulWidget {
  const _AccountSettingsDialog();

  @override
  ConsumerState<_AccountSettingsDialog> createState() =>
      _AccountSettingsDialogState();
}

class _AccountSettingsDialogState
    extends ConsumerState<_AccountSettingsDialog> {
  bool? _mfaEnabled;

  @override
  void initState() {
    super.initState();
    _loadMfaState();
  }

  AccordClient? get _client => ref.accordClient;

  Future<void> _loadMfaState() async {
    final client = _client;
    if (client == null) return;
    final result = await client.users.getMe();
    if (!mounted) return;
    final user = result.data;
    setState(() {
      _mfaEnabled = user is AccordUser ? user.mfaEnabled : false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    return Dialog(
      backgroundColor: colors.foreground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: dialogConstraints(context, maxWidth: 460, maxHeight: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      UiCopy.passwordSecurity(context: context),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: UiCopy.close(context: context),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, size: 20, color: colors.gray),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                UiCopy.password(context: context),
                style: theme.textTheme.labelSmall!.copyWith(
                  color: colors.gray,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const _PasswordSection(),
              const SizedBox(height: 20),
              Divider(height: 1, color: colors.background),
              const SizedBox(height: 16),
              Text(
                UiCopy.twoFactorAuthentication2(context: context),
                style: theme.textTheme.labelSmall!.copyWith(
                  color: colors.gray,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_mfaEnabled == null)
                const Padding(padding: EdgeInsets.all(8), child: LoadingView())
              else
                _TwoFactorSection(
                  enabled: _mfaEnabled!,
                  onChanged: (v) => setState(() => _mfaEnabled = v),
                ),
              const SizedBox(height: 20),
              Divider(height: 1, color: colors.background),
              const SizedBox(height: 16),
              Text(
                UiCopy.dangerZone2(context: context),
                style: theme.textTheme.labelSmall!.copyWith(
                  color: colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const _DangerZoneSection(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Account-deletion section: password + type-to-confirm "DELETE", calling
/// `users.deleteMe` then removing the account locally. Ports the reference's
/// `user_settings_danger.gd`.
class _DangerZoneSection extends ConsumerStatefulWidget {
  const _DangerZoneSection();

  @override
  ConsumerState<_DangerZoneSection> createState() => _DangerZoneSectionState();
}

class _DangerZoneSectionState extends ConsumerState<_DangerZoneSection> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  AccordClient? get _client => ref.accordClient;

  Future<void> _delete() async {
    final client = _client;
    if (client == null || _busy) return;
    if (_password.text.isEmpty) {
      setState(() => _error = UiCopy.passwordIsRequired());
      return;
    }
    if (_confirm.text.trim() != 'DELETE') {
      setState(() => _error = UiCopy.typeDeleteToConfirm());
      return;
    }
    final session = ref.read(accordAuthProvider);
    if (session is! AccordAuthLoggedIn) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await client.users.deleteMe({'password': _password.text});
    if (!mounted) return;
    if (!result.ok) {
      setState(() {
        _busy = false;
        _error = result.errorOr(UiCopy.failedToDeleteAccount());
      });
      return;
    }
    // Account gone server-side — drop it locally (switches to another server
    // or signs out when none remain).
    await ref.read(accordAuthProvider.notifier).removeAccount(session.session);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          UiCopy.permanentlyDeletesYourAccountOnThisServer(context: context),
          style: theme.textTheme.bodySmall!.copyWith(color: colors.gray),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _password,
          enabled: !_busy,
          obscureText: true,
          decoration: InputDecoration(
            isDense: true,
            labelText: UiCopy.password2(context: context),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirm,
          enabled: !_busy,
          decoration: InputDecoration(
            isDense: true,
            labelText: UiCopy.typeDeleteToConfirm(context: context),
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          InlineError(_error!, centered: false),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: _busy ? null : _delete,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_forever, size: 18),
            label: Text(UiCopy.deleteMyAccount(context: context)),
          ),
        ),
      ],
    );
  }
}

class _PasswordSection extends ConsumerStatefulWidget {
  const _PasswordSection();

  @override
  ConsumerState<_PasswordSection> createState() => _PasswordSectionState();
}

class _PasswordSectionState extends ConsumerState<_PasswordSection> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  bool _busy = false;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final client = ref.read(
      accordAuthProvider.select(
        (s) => s is AccordAuthLoggedIn ? s.client : null,
      ),
    );
    if (client == null) return;
    final oldPw = _old.text;
    final newPw = _new.text;
    if (oldPw.isEmpty || newPw.length < 8 || newPw.length > 128) {
      setState(() {
        _success = false;
        _message = UiCopy.enterYourCurrentPasswordAndANew();
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = await client.auth.changePassword({
      'old_password': oldPw,
      'new_password': newPw,
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      _success = result.ok;
      _message = result.ok
          ? UiCopy.passwordUpdated()
          : result.errorOr(UiCopy.failedToChangePassword());
      if (result.ok) {
        _old.clear();
        _new.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _old,
          enabled: !_busy,
          obscureText: true,
          decoration: InputDecoration(
            labelText: UiCopy.currentPassword(context: context),
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _new,
          enabled: !_busy,
          obscureText: true,
          decoration: InputDecoration(
            labelText: UiCopy.newPassword(context: context),
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(
            _message!,
            style: theme.textTheme.bodySmall!.copyWith(
              color: _success ? colors.green : colors.red,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(UiCopy.changePassword2(context: context)),
          ),
        ),
      ],
    );
  }
}

class _TwoFactorSection extends ConsumerStatefulWidget {
  const _TwoFactorSection({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  ConsumerState<_TwoFactorSection> createState() => _TwoFactorSectionState();
}

class _TwoFactorSectionState extends ConsumerState<_TwoFactorSection> {
  final _password = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  // Set after a successful enable() call: the secret/otpauth the user must add
  // to their authenticator before verifying.
  String? _secret;
  String? _otpauth;
  List<String>? _backupCodes;

  @override
  void dispose() {
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  AccordClient? get _client => ref.accordClient;

  Future<void> _enable() async {
    final client = _client;
    if (client == null) return;
    if (_password.text.isEmpty) {
      setState(() => _error = UiCopy.enterYourPassword());
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await client.auth.enable2fa({'password': _password.text});
    if (!mounted) return;
    final data = result.data;
    setState(() {
      _busy = false;
      if (result.ok && data is Map) {
        _secret = data['secret']?.toString();
        _otpauth = data['otpauth_uri']?.toString() ?? data['uri']?.toString();
      } else {
        _error = result.errorOr(UiCopy.failedToStart2faSetup());
      }
    });
  }

  Future<void> _verify() async {
    final client = _client;
    if (client == null) return;
    if (_code.text.trim().isEmpty) {
      setState(() => _error = UiCopy.enterThe6DigitCode());
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await client.auth.verify2fa({'code': _code.text.trim()});
    if (!mounted) return;
    final data = result.data;
    setState(() {
      _busy = false;
      if (result.ok) {
        _backupCodes = data is Map && data['backup_codes'] is List
            ? (data['backup_codes'] as List).map((e) => e.toString()).toList()
            : null;
        _secret = null;
        _otpauth = null;
        _password.clear();
        _code.clear();
        widget.onChanged(true);
      } else {
        _error = result.errorOr(UiCopy.invalidCode());
      }
    });
  }

  Future<void> _disable() async {
    final client = _client;
    if (client == null) return;
    if (_password.text.isEmpty) {
      setState(() => _error = UiCopy.enterYourPasswordToDisable2fa());
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await client.auth.disable2fa({'password': _password.text});
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.ok) {
        _password.clear();
        _backupCodes = null;
        widget.onChanged(false);
      } else {
        _error = result.errorOr(UiCopy.failedToDisable2fa());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_backupCodes != null) {
      return _BackupCodesView(codes: _backupCodes!);
    }

    if (widget.enabled) {
      return _TwoFactorEnabledView(
        password: _password,
        busy: _busy,
        error: _error,
        onDisable: _disable,
      );
    }

    return _TwoFactorSetupView(
      password: _password,
      code: _code,
      busy: _busy,
      error: _error,
      secret: _secret,
      otpauth: _otpauth,
      onEnable: _enable,
      onVerify: _verify,
    );
  }
}

/// Shown right after verification succeeds: the one-time backup codes with a
/// copy-to-clipboard shortcut.
class _BackupCodesView extends StatelessWidget {
  const _BackupCodesView({required this.codes});

  final List<String> codes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          UiCopy.message2faIsNowEnabledSaveTheseBackup(context: context),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.darkGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            codes.join('\n'),
            style: theme.textTheme.bodyMedium!.copyWith(fontFeatures: const []),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: codes.join('\n'))),
            icon: const Icon(Icons.copy, size: 16),
            label: Text(UiCopy.copyCodes(context: context)),
          ),
        ),
      ],
    );
  }
}

/// 2FA already on: password prompt + disable button.
class _TwoFactorEnabledView extends StatelessWidget {
  const _TwoFactorEnabledView({
    required this.password,
    required this.busy,
    required this.error,
    required this.onDisable,
  });

  final TextEditingController password;
  final bool busy;
  final String? error;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.verified_user, size: 18, color: colors.green),
            const SizedBox(width: 8),
            Text(
              UiCopy.message2faIsEnabled(context: context),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: password,
          enabled: !busy,
          obscureText: true,
          decoration: InputDecoration(
            labelText: UiCopy.password2(context: context),
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          InlineError(error!, centered: false),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: busy ? null : onDisable,
            style: TextButton.styleFrom(foregroundColor: colors.red),
            child: Text(AppStrings.label('Disable 2FA', context: context)),
          ),
        ),
      ],
    );
  }
}

/// Not yet enabled: either prompt for password (start), or show the secret +
/// verification field after enable() succeeded.
class _TwoFactorSetupView extends StatelessWidget {
  const _TwoFactorSetupView({
    required this.password,
    required this.code,
    required this.busy,
    required this.error,
    required this.secret,
    required this.otpauth,
    required this.onEnable,
    required this.onVerify,
  });

  final TextEditingController password;
  final TextEditingController code;
  final bool busy;
  final String? error;
  final String? secret;
  final String? otpauth;
  final VoidCallback onEnable;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    final setupStarted = secret != null || otpauth != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!setupStarted) ...[
          Text(
            UiCopy.protectYourAccountWithAnAuthenticatorApp(context: context),
            style: theme.textTheme.bodySmall!.copyWith(color: colors.gray),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: password,
            enabled: !busy,
            obscureText: true,
            decoration: InputDecoration(
              labelText: UiCopy.password2(context: context),
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            InlineError(error!, centered: false),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: busy ? null : onEnable,
              child: Text(AppStrings.label('Enable 2FA', context: context)),
            ),
          ),
        ] else ...[
          Text(
            UiCopy.scanThisQrCodeWithYourAuthenticator(context: context),
            style: theme.textTheme.bodySmall!.copyWith(color: colors.gray),
          ),
          if (otpauth != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                // White quiet zone so scanners read the code regardless of theme.
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: otpauth!,
                  size: 180,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.darkGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    secret ?? extractTotpSecret(otpauth) ?? '',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  tooltip: UiCopy.copySecret(context: context),
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () => Clipboard.setData(
                    ClipboardData(
                      text: secret ?? extractTotpSecret(otpauth) ?? '',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: code,
            enabled: !busy,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!busy) onVerify();
            },
            decoration: InputDecoration(
              labelText: UiCopy.message6DigitCode(context: context),
              isDense: true,
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            InlineError(error!, centered: false),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: busy ? null : onVerify,
              child: Text(UiCopy.verifyActivate(context: context)),
            ),
          ),
        ],
      ],
    );
  }
}
