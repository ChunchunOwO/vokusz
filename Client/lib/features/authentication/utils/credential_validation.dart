import 'package:bonfire/l10n/ui_copy.dart';

/// Client-side registration credential rules, shared by the login screen
/// (`accord_login.dart`) and the Add-a-Server dialog (`add_server_dialog.dart`).
/// Rules are checked in order and the first failing rule's message is
/// returned (`null` when all pass), so callers keep their existing
/// first-error-wins banner behaviour.
///
/// The server enforces all of these authoritatively as well — these checks
/// only exist to fail fast with a friendly message before a network round
/// trip. `AccordAuth`'s register paths repeat the username rule server-side
/// of the forms for callers that bypass the UI.
String? validateRegistrationCredentials({
  required String username,
  required String password,
  required bool tosRequired,
  required bool tosAccepted,
}) {
  final usernameError = validateRegistrationUsername(username);
  if (usernameError != null) return usernameError;
  if (password.length < 8) {
    return UiCopy.passwordMustBeAtLeast8Characters2();
  }
  if (tosRequired && !tosAccepted) {
    return UiCopy.youMustAcceptTheTermsOfService();
  }
  return null;
}

/// The username rule on its own, for the `AccordAuth` register paths that
/// take already-validated forms but still guard callers that bypass the UI.
/// Usernames are the public login identifier (login looks up by username, not
/// email), so email-like input is rejected rather than silently accepted as a
/// misleading account name.
String? validateRegistrationUsername(String username) =>
    username.contains('@') ? UiCopy.usernameCanTBeAnEmailAddress() : null;

/// Client-side validation shared by both forced-password-reset surfaces.
String? validatePasswordChangeCredentials({
  required String oldPassword,
  required String newPassword,
  required String confirmation,
}) {
  if (oldPassword.isEmpty || newPassword.isEmpty) {
    return UiCopy.enterYourCurrentAndNewPassword();
  }
  if (newPassword.length < 8) {
    return UiCopy.newPasswordMustBeAtLeast8();
  }
  if (newPassword != confirmation) return UiCopy.passwordsDoNotMatch2();
  return null;
}
