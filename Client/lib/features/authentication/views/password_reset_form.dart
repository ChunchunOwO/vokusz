import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/l10n/ui_copy.dart';
import 'package:bonfire/features/authentication/views/auth_form.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';

/// Shared forced-password-reset form used by primary and add-server login.
class PasswordResetForm extends StatelessWidget {
  const PasswordResetForm({
    super.key,
    required this.oldController,
    required this.newController,
    required this.confirmController,
    required this.onSubmit,
    required this.onCancel,
    this.error,
    this.enabled = true,
  });

  final TextEditingController oldController;
  final TextEditingController newController;
  final TextEditingController confirmController;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final String? error;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          UiCopy.changeYourPassword(context: context),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          UiCopy.theServerRequiresANewPasswordBefore(context: context),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFC8C8C8),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),
        AuthField(
          controller: oldController,
          label: UiCopy.currentPassword(context: context),
          obscureText: true,
          enabled: enabled,
        ),
        const SizedBox(height: 12),
        AuthField(
          controller: newController,
          label: UiCopy.newPassword(context: context),
          obscureText: true,
          enabled: enabled,
        ),
        const SizedBox(height: 12),
        AuthField(
          controller: confirmController,
          label: UiCopy.confirmNewPassword(context: context),
          obscureText: true,
          enabled: enabled,
          onSubmitted: (_) => enabled ? onSubmit() : null,
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(
            AppStrings.label(error!, context: context),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: BonfireThemeExtension.of(context).red,
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: enabled ? onSubmit : null,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: BonfireThemeExtension.of(context).background,
              foregroundColor: BonfireThemeExtension.of(context).dirtyWhite,
              side: BorderSide(
                color: BonfireThemeExtension.of(context).primary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: enabled
                ? Text(
                    UiCopy.changePassword(context: context),
                    style: theme.textTheme.titleSmall!.copyWith(
                      color: BonfireThemeExtension.of(context).dirtyWhite,
                    ),
                  )
                : const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: enabled ? onCancel : null,
          child: Text(
            UiCopy.cancel(context: context),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
