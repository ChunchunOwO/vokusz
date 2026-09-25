import 'package:bonfire/l10n/ui_copy.dart';
import 'package:bonfire/features/authentication/models/accord_auth_state.dart';
import 'package:bonfire/features/authentication/repositories/accord_auth.dart';
import 'package:bonfire/features/authentication/utils/credential_validation.dart';
import 'package:bonfire/features/authentication/utils/tos_gate.dart';
import 'package:bonfire/features/authentication/views/auth_form.dart';
import 'package:bonfire/features/authentication/views/password_reset_form.dart';
import 'package:bonfire/features/authentication/views/welcome_view.dart';
import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/shared/app_info.dart';
import 'package:bonfire/features/profiles/services/profile_store.dart';
import 'package:bonfire/features/server/models/accord_server.dart';
import 'package:bonfire/features/server/services/deep_link_navigation.dart';
import 'package:bonfire/features/server/utils/server_uri.dart';
import 'package:bonfire/features/spaces/views/accord_discovery.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Server-URL + credentials login against an Accord server. The Vokusz
/// replacement for Bonfire's `LoginScreen`: it drives [accordAuthProvider]
/// (restore-on-launch → sign in / register → optional MFA or forced password
/// change → connect) and, once a live session exists, hands off to the
/// messaging frame.
///
/// [initialMode] selects the Sign in / Register tab on entry; the `/register`
/// route uses it to land directly on registration.
///
/// [startOnCredentials] is ignored. Every signed-out entry opens the credentials
/// form for [kDefaultAccordServerUrl].
class AccordLoginScreen extends ConsumerStatefulWidget {
  const AccordLoginScreen({
    super.key,
    this.initialMode = AuthMode.signIn,
    this.startOnCredentials = false,
  });

  final AuthMode initialMode;
  final bool startOnCredentials;

  @override
  ConsumerState<AccordLoginScreen> createState() => _AccordLoginScreenState();
}

/// The signed-out sub-flow: branded onboarding → public server browser → the
/// credentials form for the chosen instance.
enum _LoggedOutView { welcome, browse, credentials }

class _AccordLoginScreenState extends ConsumerState<AccordLoginScreen> {
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _mfaController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AuthMode _mode = widget.initialMode;

  /// Signed-out entry is the credentials form for [kDefaultAccordServerUrl].
  late _LoggedOutView _view = _LoggedOutView.credentials;

  /// A space chosen from discovery while signed out: once the credentials in
  /// this form authenticate, we join it before handing off to the frame.
  String? _pendingJoinSpaceId;

  /// Client-side validation error for the password-change form.
  String? _resetLocalError;

  /// Client-side validation error for the credentials form (e.g. unaccepted ToS
  /// or too-short registration password).
  String? _authLocalError;

  // Terms-of-Service config, fetched per server when the Register tab is shown.
  // Absent until a fetch says otherwise, so no gate flashes before the answer.
  TosAvailability _tosAvailability = TosAvailability.absent;
  bool _tosAccepted = false;
  String? _tosUrl;
  String? _tosText;
  String? _tosFetchedServer;

  /// True until the launch-time session restore attempt settles, so we show a
  /// loader instead of flashing the login form for returning users.
  bool _restoring = true;
  bool _lookingUpAccount = false;
  bool _finishingLogin = false;

  @override
  void initState() {
    super.initState();
    final pending = ref.read(pendingServerJoinProvider);
    final pendingServer = pending?.server;
    _serverController.text = pendingServer?.baseUrl ?? kDefaultAccordServerUrl;
    _view = _LoggedOutView.credentials;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(accordAuthProvider.notifier);
      // Don't re-restore over a live session.
      if (ref.read(accordAuthProvider) is! AccordAuthLoggedIn) {
        await notifier.restoreSession();
      }
      if (mounted) setState(() => _restoring = false);

      // Landed straight on the Register tab (via /register): fetch the ToS gate.
      if (_mode == AuthMode.register) _fetchTos();
    });
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _mfaController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onModeChanged(AuthMode mode) {
    setState(() {
      _mode = mode;
      _authLocalError = null;
    });
    if (mode == AuthMode.register) _fetchTos();
  }

  AccordServer? _serverFromInput(String raw) {
    try {
      return AccordServer.fromBaseUrl(raw);
    } on FormatException catch (error) {
      if (mounted) setState(() => _authLocalError = error.message);
      return null;
    }
  }

  Future<void> _fetchTos() async {
    final raw = _serverController.text.trim();
    if (raw.isEmpty) return;
    final server = _serverFromInput(raw);
    if (server == null) return;
    if (_tosFetchedServer == server.baseUrl) return;
    final tos = await fetchTosConfig(
      ref.read(accordAuthProvider.notifier),
      server,
    );
    if (!mounted) return;
    setState(() {
      _tosFetchedServer = server.baseUrl;
      _tosAvailability = tos.availability;
      _tosUrl = tos.url;
      _tosText = tos.text;
      _tosAccepted = false;
    });
  }

  void _generatePassword() {
    _passwordController.text = generateAuthPassword();
  }

  Future<void> _openTos() => openTos(context, url: _tosUrl, text: _tosText);

  /// Discovery (the embedded browser while signed out) needs auth against
  /// `serverUrl` before joining `spaceId`: switch to the credentials form,
  /// pre-fill it, and remember the space so the next successful login joins it.
  void _onDiscoveryJoinRequiresAuth(String serverUrl, String spaceId) {
    ref
        .read(pendingServerJoinProvider.notifier)
        .hold(
          ParsedServerUrl(
            server: AccordServer.fromBaseUrl(serverUrl),
            spaceId: spaceId,
          ),
        );
    ProfileStore.sessionBox.put('last-server', serverUrl);
    setState(() {
      _serverController.text = serverUrl;
      _pendingJoinSpaceId = spaceId;
      _mode = AuthMode.signIn;
      _authLocalError = null;
      _view = _LoggedOutView.credentials;
    });
  }

  Future<void> _submit() async {
    if (_lookingUpAccount) return;
    final rawServer = _serverController.text.trim();
    if (rawServer.isEmpty) return;
    final parsed = ServerUri.parseServerUrl(rawServer);
    final server = parsed?.server;
    if (parsed == null || server == null) {
      setState(() => _authLocalError = UiCopy.enterAValidServerUrl());
      return;
    }
    final pending = ref.read(pendingServerJoinProvider);
    if (parsed.hasInvite ||
        parsed.spaceName != null ||
        pending == null ||
        pending.server == null ||
        !AccordServer.sameEndpoint(pending.server!.baseUrl, server.baseUrl)) {
      ref.read(pendingServerJoinProvider.notifier).hold(parsed);
    }
    ProfileStore.sessionBox.put('last-server', server.baseUrl);
    final notifier = ref.read(accordAuthProvider.notifier);
    setState(() => _lookingUpAccount = true);
    try {
      final key = await notifier.ensureConnectionForBaseUrl(server.baseUrl);
      if (!mounted) return;
      if (key != null) {
        notifier.setActiveServer(key);
        return;
      }
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _authLocalError = UiCopy.couldNotUseTheSavedAccount(arg0: error),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _lookingUpAccount = false);
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) return;

    if (_mode == AuthMode.register) {
      final validationError = validateRegistrationCredentials(
        username: username,
        password: password,
        tosRequired: _tosAvailability == TosAvailability.advertised,
        tosAccepted: _tosAccepted,
      );
      if (validationError != null) {
        setState(() => _authLocalError = validationError);
        return;
      }
      setState(() => _authLocalError = null);
      notifier.registerWithCredentials(
        server: server,
        username: username,
        password: password,
        displayName: _displayNameController.text.trim(),
      );
    } else {
      setState(() => _authLocalError = null);
      notifier.loginWithCredentials(
        server: server,
        username: username,
        password: password,
      );
    }
  }

  void _submitMfa() {
    final code = _mfaController.text.trim();
    if (code.isEmpty) return;
    ref.read(accordAuthProvider.notifier).submitMfa(code);
  }

  void _submitPasswordChange() {
    final oldPw = _oldPasswordController.text;
    final newPw = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    final validationError = validatePasswordChangeCredentials(
      oldPassword: oldPw,
      newPassword: newPw,
      confirmation: confirm,
    );
    if (validationError != null) {
      setState(() => _resetLocalError = validationError);
      return;
    }
    setState(() => _resetLocalError = null);
    ref
        .read(accordAuthProvider.notifier)
        .submitPasswordChange(oldPassword: oldPw, newPassword: newPw);
  }

  void _navigateToHome() => context.go('/spaces');

  Future<void> _finishLogin(AccordAuthLoggedIn loggedIn) async {
    if (_finishingLogin) return;
    _finishingLogin = true;
    final pending = ref.read(pendingServerJoinProvider);
    if (pending != null &&
        pending.server != null &&
        AccordServer.sameEndpoint(
          pending.server!.baseUrl,
          loggedIn.session.server.baseUrl,
        )) {
      try {
        final outcome = await ref
            .read(accordAuthProvider.notifier)
            .joinOnConnection(
              loggedIn.session.key,
              spaceId: pending.spaceId ?? pending.spaceName,
              invite: pending.invite,
            );
        if (!mounted) return;
        if (outcome.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(outcome.error!)));
        } else {
          // A newer link may have arrived while this join was in flight.
          if (identical(ref.read(pendingServerJoinProvider), pending)) {
            ref.read(pendingServerJoinProvider.notifier).clear();
          }
          final destination = outcome.spaceId == null
              ? (pending.spaceName != null || pending.channelName != null
                    ? PendingDeepLinkDestination.fromParsed(pending)
                    : null)
              : PendingDeepLinkDestination(
                  serverBaseUrl: loggedIn.session.server.baseUrl,
                  spaceId: outcome.spaceId,
                  channelName: pending.channelName,
                );
          if (destination != null) {
            ref.read(pendingDeepLinkProvider.notifier).hold(destination);
          }
        }
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(UiCopy.couldNotJoin(arg0: error))),
        );
      }
    }
    if (!mounted) return;
    _pendingJoinSpaceId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(pendingDeepLinkProvider) == null) {
        _navigateToHome();
      }
    });
    _finishingLogin = false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accordAuthProvider);
    ref.listen(pendingServerJoinProvider, (previous, next) {
      final server = next?.server;
      if (server == null) return;
      setState(() {
        _serverController.text = server.baseUrl;
        _view = _LoggedOutView.credentials;
      });
    });

    // Covers a login that completes *while this screen is showing* — a state
    // change doesn't re-run router redirects. Landing on a sign-in route while
    // *already* logged in never reaches build: the router redirects it straight
    // home (see `redirectLoggedInToHome` in `lib/router/controller.dart`), and
    // the signed-in screens are siblings of these routes, so this screen is not
    // mounted underneath them.
    ref.listen(accordAuthProvider, (previous, next) {
      if (next is AccordAuthLoggedIn) {
        _finishLogin(next);
      }
    });

    // Loading / MFA / forced-password-change: simple centered forms with no
    // onboarding chrome.
    if (_restoring ||
        _lookingUpAccount ||
        state is AccordAuthInProgress ||
        state is AccordAuthLoggedIn) {
      return _fill(
        _centered(
          _Loading(
            label: _restoring
                ? UiCopy.reconnecting(context: context)
                : UiCopy.signingIn(context: context),
          ),
        ),
      );
    }
    if (state is AccordAuthMfaRequired) {
      return _fill(
        _centered(
          _MfaForm(
            controller: _mfaController,
            onSubmit: _submitMfa,
            onCancel: () => ref.read(accordAuthProvider.notifier).logout(),
          ),
        ),
      );
    }
    if (state is AccordAuthPasswordResetRequired) {
      return _fill(
        _centered(
          PasswordResetForm(
            oldController: _oldPasswordController,
            newController: _newPasswordController,
            confirmController: _confirmPasswordController,
            onSubmit: _submitPasswordChange,
            onCancel: () => ref.read(accordAuthProvider.notifier).logout(),
            error: _resetLocalError ?? state.error,
          ),
        ),
      );
    }

    // Signed out: credentials for the default server, with browse behind it.
    // Intercept system back to
    // step through the sub-flow rather than leaving the screen, except at the
    // flow's entry view.
    final Widget signedOut = switch (_view) {
      _LoggedOutView.welcome => _centered(
        WelcomeView(
          onBrowse: () => setState(() => _view = _LoggedOutView.browse),
          onManualConnect: () =>
              setState(() => _view = _LoggedOutView.credentials),
        ),
        // Wide enough for the welcome screen's three-up highlights on a tablet
        // or desktop canvas; it collapses itself back to a phone layout below
        // `kWelcomeWideBreakpoint` (#292).
        maxWidth: 760,
      ),
      _LoggedOutView.browse => _BrowseView(
        onBack: _goBack,
        onManualConnect: () =>
            setState(() => _view = _LoggedOutView.credentials),
        onJoinRequiresAuth: _onDiscoveryJoinRequiresAuth,
      ),
      _LoggedOutView.credentials => _centered(
        _AuthForm(
          usernameController: _usernameController,
          passwordController: _passwordController,
          displayNameController: _displayNameController,
          mode: _mode,
          tosAvailability: _tosAvailability,
          tosAccepted: _tosAccepted,
          onBack: _atFlowRoot ? null : _goBack,
          onModeChanged: _onModeChanged,
          onGeneratePassword: _generatePassword,
          onTosChanged: (v) => setState(() => _tosAccepted = v),
          onTosLinkTap: _openTos,
          onSubmit: _submit,
          error:
              _authLocalError ??
              (state is AccordAuthFailed ? state.message : null),
        ),
      ),
    };

    return _fill(
      PopScope(
        canPop: _atFlowRoot,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goBack();
        },
        child: signedOut,
      ),
    );
  }

  /// Opaque full-viewport surface. On web the HTML page behind the view is not
  /// the app; without this the canvas only paints the form and the rest of the
  /// window stays the host page.
  Widget _fill(Widget child) {
    final colors = BonfireThemeExtension.of(context);
    return ColoredBox(
      color: colors.background,
      child: SizedBox.expand(child: child),
    );
  }

  Widget _centered(Widget child, {double maxWidth = 420}) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: child,
          ),
        ),
      ),
    );
  }

  /// The signed-out view from which a back gesture should leave the screen
  /// rather than step back through the onboarding sub-flow.
  bool get _atFlowRoot => _view == _LoggedOutView.credentials;

  void _goBack() {
    setState(() {
      if (_view == _LoggedOutView.browse || _view == _LoggedOutView.welcome) {
        _view = _LoggedOutView.credentials;
      } else if (_view == _LoggedOutView.credentials &&
          _pendingJoinSpaceId != null) {
        _view = _LoggedOutView.browse;
        _pendingJoinSpaceId = null;
        _authLocalError = null;
      }
    });
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).textTheme.bodyMedium!.color!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 30),
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(color: color),
        ),
      ],
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.usernameController,
    required this.passwordController,
    required this.displayNameController,
    required this.mode,
    required this.tosAvailability,
    required this.tosAccepted,
    required this.onModeChanged,
    required this.onGeneratePassword,
    required this.onTosChanged,
    required this.onTosLinkTap,
    required this.onSubmit,
    this.onBack,
    this.error,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController displayNameController;
  final AuthMode mode;
  final TosAvailability tosAvailability;
  final bool tosAccepted;
  final VoidCallback? onBack;
  final ValueChanged<AuthMode> onModeChanged;
  final VoidCallback onGeneratePassword;
  final ValueChanged<bool> onTosChanged;
  final VoidCallback onTosLinkTap;
  final VoidCallback onSubmit;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    final text = AppStrings.of(context);
    final isRegister = mode == AuthMode.register;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onBack != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(text.cancel),
            ),
          ),
        Text(
          text.welcome,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        AuthCredentialsFields(
          mode: mode,
          onModeChanged: onModeChanged,
          usernameController: usernameController,
          passwordController: passwordController,
          displayNameController: displayNameController,
          tosAvailability: tosAvailability,
          tosAccepted: tosAccepted,
          onTosChanged: onTosChanged,
          onTosLinkTap: onTosLinkTap,
          onGeneratePassword: onGeneratePassword,
          onSubmit: onSubmit,
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(
            AppStrings.label(error!, context: context),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!.copyWith(color: colors.red),
          ),
        ],
        const SizedBox(height: 24),
        _SubmitButton(
          label: isRegister ? text.register : text.logIn,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

/// The signed-out server browser: a back affordance + the shared public-space
/// directory ([AccordDiscoveryBody]) shown full-screen, with a manual
/// connect-by-URL escape hatch. Joining a listing routes auth back through the
/// hosting login screen via [onJoinRequiresAuth].
class _BrowseView extends StatelessWidget {
  const _BrowseView({
    required this.onBack,
    required this.onManualConnect,
    required this.onJoinRequiresAuth,
  });

  final VoidCallback onBack;
  final VoidCallback onManualConnect;
  final void Function(String serverUrl, String spaceId) onJoinRequiresAuth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = BonfireThemeExtension.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: UiCopy.back(context: context),
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 20),
                  ),
                  Icon(Icons.explore, size: 20, color: colors.dirtyWhite),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      UiCopy.discoverServers(context: context),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            // The connect-by-URL / host-your-own footer lives inside
            // [AccordDiscoveryBody] so the dialog variant gets it too (#292).
            Expanded(
              child: AccordDiscoveryBody(
                onJoinRequiresAuth: onJoinRequiresAuth,
                onManualConnect: onManualConnect,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MfaForm extends StatelessWidget {
  const _MfaForm({
    required this.controller,
    required this.onSubmit,
    required this.onCancel,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          UiCopy.twoFactorAuthentication(context: context),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          UiCopy.enterTheCodeFromYourAuthenticatorApp(context: context),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFC8C8C8),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),
        AuthField(
          controller: controller,
          label: UiCopy.message6DigitCode(context: context),
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 24),
        _SubmitButton(
          label: UiCopy.verify(context: context),
          onPressed: onSubmit,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onCancel,
          child: Text(
            UiCopy.cancel(context: context),
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colors.background,
          foregroundColor: colors.dirtyWhite,
          side: BorderSide(color: colors.primary),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall!.copyWith(color: colors.dirtyWhite),
        ),
      ),
    );
  }
}
