import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/shared/utils/confirm_dialog.dart';
import 'package:flutter/material.dart';

/// Confirmation dialog shown before logging out.
///
/// Returns `true` only when the user explicitly confirms; `false` when they
/// cancel or dismiss it. Shared by the settings screen and the home rail so
/// both logout entry points use identical copy and neither signs the user out
/// on a single accidental tap.
Future<bool> confirmLogout(BuildContext context) async {
  final confirmed = await showConfirmDialog(
    context,
    title: AppStrings.of(context).logOutTitle,
    message: AppStrings.of(context).logOutMessage,
    confirmLabel: AppStrings.of(context).logOut,
    danger: true,
  );
  return confirmed ?? false;
}
