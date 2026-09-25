import 'package:bonfire/l10n/ui_copy.dart';
import 'package:bonfire/features/authentication/models/accord_auth_state.dart';
import 'package:bonfire/features/authentication/models/accord_session.dart';
import 'package:bonfire/shared/components/color_swatch_chip.dart';
import 'package:bonfire/shared/components/section_header.dart';
import 'package:bonfire/features/authentication/repositories/accord_auth.dart';
import 'package:bonfire/features/authentication/utils/confirm_logout.dart';
import 'package:bonfire/features/developer/views/developer_settings_page.dart';
import 'package:bonfire/features/settings/controllers/settings.dart';
import 'package:bonfire/features/profiles/views/profiles_page.dart';
import 'package:bonfire/features/server/controllers/connections.dart';
import 'package:bonfire/features/settings/views/rich_presence_settings.dart';
import 'package:bonfire/features/settings/views/server_accounts_section.dart';
import 'package:bonfire/features/settings/views/connections_settings_page.dart';
import 'package:bonfire/features/settings/views/privacy_settings_page.dart';
import 'package:bonfire/features/settings/views/settings_backup.dart';
import 'package:bonfire/features/member/utils/member_display.dart';
import 'package:bonfire/features/onboarding/views/onboarding_tour.dart';
import 'package:bonfire/features/onboarding/views/onboarding_help.dart';
import 'package:bonfire/features/updates/views/updates_page.dart';
import 'package:bonfire/features/settings/models/accord_settings.dart';
import 'package:bonfire/features/user/views/accord_account_settings.dart';
import 'package:bonfire/features/user/views/accord_profile_edit.dart';
import 'package:bonfire/l10n/app_strings.dart';
import 'package:bonfire/shared/app_info.dart';
import 'package:bonfire/shared/utils/rest_result_ext.dart';
import 'package:bonfire/features/voice/views/voice_settings_screen.dart';
import 'package:bonfire/theme/app_theme.dart';
import 'package:bonfire/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Client settings: appearance (theme preset + accent), notifications, account.
///
/// Two layouts share the same section widgets:
///
/// * **Narrow** (< [kSettingsWideBreakpoint]) — the original single flat
///   `ListView` of all eleven sections. Unchanged.
/// * **Wide** — a left category sidebar (Account / App / System / Advanced)
///   plus one ordered, width-capped content column. See [_DesktopSettings].
class AccordSettingsScreen extends ConsumerWidget {
  const AccordSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = BonfireThemeExtension.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final session = ref.watch(
      accordAuthProvider.select(
        (s) => s is AccordAuthLoggedIn ? s.session : null,
      ),
    );

    Future<void> logOut() async {
      if (!await confirmLogout(context)) return;
      if (!context.mounted) return;
      ref.read(accordAuthProvider.notifier).logout();
      if (context.mounted) context.go('/');
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.foreground,
        title: Text(AppStrings.of(context).settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/spaces'),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= kSettingsWideBreakpoint) {
            return _DesktopSettings(onLogOut: logOut);
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _AppearanceSection(settings: settings, controller: controller),
              const Divider(height: 24),
              _NotificationsSection(settings: settings, controller: controller),
              const Divider(height: 24),
              _SoundsSection(settings: settings, controller: controller),
              const Divider(height: 24),
              const _VoiceVideoSection(),
              const Divider(height: 24),
              _AccountSection(
                session: session,
                hasMultipleConnections: ref
                    .watch(connectionsControllerProvider)
                    .hasMultiple,
                onPickServerProfile: () => _pickServerProfile(context, ref),
              ),
              const Divider(height: 24),
              const ServerAccountsSection(),
              const Divider(height: 24),
              const _ServerDirectorySection(),
              const Divider(height: 24),
              // Store builds update through the store and never expose the
              // GitHub self-updater; Developer Mode is desktop-only (#292).
              if (isSelfUpdateEnabled) ...[
                const _UpdatesSection(),
                const Divider(height: 24),
              ],
              const _BackupSection(),
              const Divider(height: 24),
              if (isDeveloperModeAvailable) ...[
                _DeveloperSection(settings: settings, controller: controller),
                const Divider(height: 24),
              ],
              const OnboardingHelpSection(),
              const Divider(height: 24),
              const _AboutSection(),
              const Divider(height: 24),
              _LogOutTile(onLogOut: logOut),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wide (desktop) layout
// ---------------------------------------------------------------------------

/// Width at which the settings screen swaps the flat scroll for the sidebar +
/// multi-column pane.
///
/// Deliberately *not* `shouldUseDesktopLayout`: that helper also requires
/// height > 1000, so it is false on short-but-wide desktop windows — exactly
/// the shape that needs a multi-column settings layout most. Column count is a
/// pure function of width, so it is measured with a width-only breakpoint.
const double kSettingsWideBreakpoint = 1000;

/// Maximum width of the ordered settings content. Caps every control row so a label and
/// its switch stay visually paired instead of sitting at opposite ends of an
/// ultrawide window.
const double kSettingsContentMaxWidth = 760;

const double _kSidebarWidth = 232;
const double _kPanePadding = 16;

/// The four sidebar categories the eleven settings sections group into.
enum SettingsCategory {
  account('Account', Icons.person_outline),
  app('App', Icons.tune),
  system('System', Icons.settings_applications_outlined),
  advanced('Advanced', Icons.code);

  const SettingsCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Sidebar + content pane. Owns which category is selected.
class _DesktopSettings extends StatefulWidget {
  const _DesktopSettings({required this.onLogOut});

  final VoidCallback onLogOut;

  @override
  State<_DesktopSettings> createState() => _DesktopSettingsState();
}

class _DesktopSettingsState extends State<_DesktopSettings> {
  SettingsCategory _selected = SettingsCategory.account;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategorySidebar(
          selected: _selected,
          onSelect: (category) => setState(() => _selected = category),
          onLogOut: widget.onLogOut,
        ),
        VerticalDivider(width: 1, thickness: 1, color: colors.background),
        Expanded(child: _CategoryPane(category: _selected)),
      ],
    );
  }
}

/// Fixed-width category list, with Log out pinned to the bottom so it stays
/// reachable from every category.
class _CategorySidebar extends StatelessWidget {
  const _CategorySidebar({
    required this.selected,
    required this.onSelect,
    required this.onLogOut,
  });

  final SettingsCategory selected;
  final ValueChanged<SettingsCategory> onSelect;
  final VoidCallback onLogOut;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return Material(
      key: const ValueKey('settings-sidebar'),
      color: colors.foreground,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: SizedBox(
          width: _kSidebarWidth,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final category in SettingsCategory.values)
                      FocusTraversalOrder(
                        key: ValueKey('settings-category-${category.name}'),
                        order: NumericFocusOrder(category.index.toDouble()),
                        child: _SidebarTile(
                          category: category,
                          selected: category == selected,
                          onTap: () => onSelect(category),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: colors.background),
              FocusTraversalOrder(
                order: const NumericFocusOrder(100),
                child: _LogOutTile(onLogOut: onLogOut),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final SettingsCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        dense: true,
        selected: selected,
        selectedTileColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: selected ? colors.primary : Colors.transparent,
          ),
        ),
        leading: Icon(
          category.icon,
          size: 20,
          color: selected ? colors.primary : colors.dirtyWhite,
        ),
        title: Text(
          AppStrings.of(context).settingsCategory(category.name),
          style: TextStyle(color: selected ? colors.primary : null),
        ),
        onTap: onTap,
      ),
    );
  }
}

/// The selected category's sections in one predictable top-to-bottom sequence.
/// Unequal sections retain their natural visual weight instead of each becoming
/// an equal card or being distributed round-robin across columns.
class _CategoryPane extends ConsumerWidget {
  const _CategoryPane({required this.category});

  final SettingsCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final session = ref.watch(
      accordAuthProvider.select(
        (s) => s is AccordAuthLoggedIn ? s.session : null,
      ),
    );

    final sections = switch (category) {
      SettingsCategory.account => <Widget>[
        _AccountSection(
          session: session,
          hasMultipleConnections: ref
              .watch(connectionsControllerProvider)
              .hasMultiple,
          onPickServerProfile: () => _pickServerProfile(context, ref),
          // Connections and Privacy & Data are cards in this same pane, so
          // their "push a sub-page" tiles would be redundant here.
          showSubPageTiles: false,
        ),
        const ServerAccountsSection(),
        const ConnectionsScreen(embedded: true),
        const PrivacySettingsScreen(embedded: true),
        const _ServerDirectorySection(),
      ],
      SettingsCategory.app => <Widget>[
        _AppearanceSection(settings: settings, controller: controller),
        _NotificationsSection(settings: settings, controller: controller),
        _SoundsSection(settings: settings, controller: controller),
        const _VoiceVideoSection(),
      ],
      SettingsCategory.system => <Widget>[
        // Store builds update through the store and never expose the GitHub
        // self-updater (#292).
        if (isSelfUpdateEnabled) const _UpdatesSection(),
        const _BackupSection(),
      ],
      SettingsCategory.advanced => <Widget>[
        // The local MCP server is desktop-only and never in a store build.
        if (isDeveloperModeAvailable)
          _DeveloperSection(settings: settings, controller: controller),
        const OnboardingHelpSection(),
        const _AboutSection(),
      ],
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        _kPanePadding,
        _kPanePadding,
        _kPanePadding,
        32,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kSettingsContentMaxWidth),
          child: Column(
            key: const ValueKey('settings-content-column'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) const Divider(height: 32),
                sections[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Theme preset chips, accent-colour swatches, compact mode, emoticon
/// conversion, reduced motion, and the UI scale slider.
class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({required this.settings, required this.controller});

  final AccordSettings settings;
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(AppStrings.of(context).appearance),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(
            AppStrings.of(context).language,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('中文'),
                selected: settings.languageCode != 'en',
                onSelected: (_) => controller.setLanguage('zh'),
              ),
              ChoiceChip(
                label: const Text('English'),
                selected: settings.languageCode == 'en',
                onSelected: (_) => controller.setLanguage('en'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in AppThemePreset.values)
                ChoiceChip(
                  label: Text(AppStrings.of(context).themeName(preset.name)),
                  selected: settings.themePreset == preset,
                  onSelected: (_) => controller.setThemePreset(preset),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(
            AppStrings.of(context).accent,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ColorSwatchChip(
                color: defaultAccentFor(settings.themePreset),
                selected: settings.accentColor == null,
                label: AppStrings.of(context).accentDefault,
                borderRadius: BorderRadius.circular(4),
                onTap: () => controller.setAccentColor(null),
              ),
              for (final (argb, name) in avatarColorPalette)
                ColorSwatchChip(
                  color: Color(argb),
                  selected: settings.accentColor == argb,
                  label: name,
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => controller.setAccentColor(argb),
                ),
            ],
          ),
        ),
        SwitchListTile(
          title: Text(UiCopy.showEmbedsAndLinkPreviews(context: context)),
          subtitle: Text(
            UiCopy.hidePreviewsOnlyForYouMessageText(context: context),
          ),
          value: settings.showEmbeds,
          onChanged: controller.setShowEmbeds,
        ),
        SwitchListTile(
          title: Text(UiCopy.compactMode(context: context)),
          subtitle: Text(
            UiCopy.denserMessageLayoutSmallerSpacing(context: context),
          ),
          value: settings.compactMode,
          onChanged: controller.setCompactMode,
        ),
        SwitchListTile(
          title: Text(UiCopy.convertEmoticonsToEmoji(context: context)),
          subtitle: Text(UiCopy.turnAnd3IntoAndAsYou(context: context)),
          value: settings.convertEmoticons,
          onChanged: controller.setConvertEmoticons,
        ),
        SwitchListTile(
          title: Text(UiCopy.reducedMotion(context: context)),
          subtitle: Text(UiCopy.minimiseUiAnimations(context: context)),
          value: settings.reducedMotion,
          onChanged: controller.setReducedMotion,
        ),
        ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(UiCopy.uiScale(context: context)),
              Text('${(settings.uiScale * 100).round()}%'),
            ],
          ),
          subtitle: Slider(
            value: settings.uiScale.clamp(
              AccordSettings.minUiScale,
              AccordSettings.maxUiScale,
            ),
            min: AccordSettings.minUiScale,
            max: AccordSettings.maxUiScale,
            divisions:
                ((AccordSettings.maxUiScale - AccordSettings.minUiScale) / 0.1)
                    .round(),
            label: '${(settings.uiScale * 100).round()}%',
            onChanged: controller.setUiScale,
          ),
        ),
      ],
    );
  }
}

/// Mention-notification toggles.
class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection({
    required this.settings,
    required this.controller,
  });

  final AccordSettings settings;
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(AppStrings.of(context).notifications),
        SwitchListTile(
          title: Text(UiCopy.enableNotifications(context: context)),
          subtitle: Text(
            UiCopy.showASystemNotificationWhenMentioned(context: context),
          ),
          value: settings.notificationsEnabled,
          onChanged: controller.setNotificationsEnabled,
        ),
        SwitchListTile(
          title: Text(UiCopy.suppressEveryone(context: context)),
          subtitle: Text(
            UiCopy.neverNotifyForEveryoneHereMentions(context: context),
          ),
          value: settings.suppressEveryone,
          onChanged: settings.notificationsEnabled
              ? controller.setSuppressEveryone
              : null,
        ),
        // Android sideload builds only — see [isBackgroundConnectionAvailable].
        // Without this entry the foreground service could not be turned on at
        // all, so the whole feature was unreachable from the UI (#306).
        if (isBackgroundConnectionAvailable)
          SwitchListTile(
            key: const Key('background-connection-switch'),
            title: Text(UiCopy.stayConnectedInTheBackground(context: context)),
            subtitle: Text(
              UiCopy.keepsNotificationsArrivingWhileTheAppIs(context: context),
            ),
            value: settings.backgroundConnection,
            onChanged: controller.setBackgroundConnection,
          ),
      ],
    );
  }
}

/// SFX toggle + volume slider.
class _SoundsSection extends StatelessWidget {
  const _SoundsSection({required this.settings, required this.controller});

  final AccordSettings settings;
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(AppStrings.of(context).sounds),
        SwitchListTile(
          title: Text(UiCopy.enableSounds(context: context)),
          subtitle: Text(
            UiCopy.playSfxForMessagesAndMentions(context: context),
          ),
          value: settings.soundsEnabled,
          onChanged: controller.setSoundsEnabled,
        ),
        ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(UiCopy.volume(context: context)),
              Text('${(settings.sfxVolume * 100).round()}%'),
            ],
          ),
          subtitle: Slider(
            value: settings.sfxVolume,
            onChanged: settings.soundsEnabled ? controller.setSfxVolume : null,
          ),
        ),
      ],
    );
  }
}

/// Entry point into the dedicated voice & video settings screen.
class _VoiceVideoSection extends StatelessWidget {
  const _VoiceVideoSection();

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(AppStrings.of(context).voiceAndVideo),
        ListTile(
          leading: Icon(Icons.mic_none, color: colors.dirtyWhite),
          title: Text(UiCopy.voiceVideoSettings(context: context)),
          subtitle: Text(
            UiCopy.microphoneSpeakerSensitivityCameraMicTest(context: context),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showVoiceSettings(context),
        ),
      ],
    );
  }
}

/// Current session summary plus profile, security, account-switching,
/// connections, privacy, and (for admins) server administration entries.
class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.session,
    required this.hasMultipleConnections,
    required this.onPickServerProfile,
    this.showSubPageTiles = true,
  });

  final AccordSession? session;
  final bool hasMultipleConnections;
  final VoidCallback onPickServerProfile;

  /// Whether to include the Connections / Privacy & Data tiles that push their
  /// own sub-page. The wide layout renders both as sibling cards in the same
  /// pane instead, so it turns these off.
  final bool showSubPageTiles;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    final session = this.session;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(AppStrings.of(context).account),
        if (session != null)
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.foreground,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colors.darkGray),
              ),
              child: Text(
                accordInitial(session.username),
                style: TextStyle(color: colors.dirtyWhite),
              ),
            ),
            title: Text(session.username),
            subtitle: Text(session.server.baseUrl),
          ),
        const RichPresenceSettings(),
        ListTile(
          leading: Icon(Icons.edit_outlined, color: colors.dirtyWhite),
          title: Text(AppStrings.of(context).editProfile),
          subtitle: Text(AppStrings.of(context).editProfileHint),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showAccordProfileEdit(context),
        ),
        ListTile(
          leading: Icon(Icons.lock_outline, color: colors.dirtyWhite),
          title: Text(AppStrings.of(context).passwordSecurity),
          subtitle: Text(AppStrings.of(context).passwordSecurityHint),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showAccordAccountSettings(context),
        ),
        if (hasMultipleConnections)
          ListTile(
            leading: Icon(Icons.dns_outlined, color: colors.dirtyWhite),
            title: Text(UiCopy.perServerProfile(context: context)),
            subtitle: Text(
              UiCopy.overrideNameBioAvatarOnOneServer(context: context),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onPickServerProfile,
          ),
        ListTile(
          leading: Icon(Icons.devices, color: colors.dirtyWhite),
          title: Text(UiCopy.deviceProfiles2(context: context)),
          subtitle: Text(
            UiCopy.localProfilesWithAnOptionalCasualPin(context: context),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showProfilesSettings(context),
        ),
        if (showSubPageTiles) ...[
          ListTile(
            leading: Icon(Icons.link, color: colors.dirtyWhite),
            title: Text(UiCopy.connections(context: context)),
            subtitle: Text(
              UiCopy.linkedThirdPartyOauthAccounts(context: context),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showConnectionsSettings(context),
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: colors.dirtyWhite),
            title: Text(UiCopy.privacyData(context: context)),
            subtitle: Text(
              UiCopy.dataExportLeaveDeleteDataRetention(context: context),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showPrivacySettings(context),
          ),
        ],
        if (session?.isAdmin ?? false)
          ListTile(
            leading: Icon(Icons.admin_panel_settings, color: colors.dirtyWhite),
            title: Text(UiCopy.serverAdministration(context: context)),
            subtitle: Text(UiCopy.spacesUsersReportsSettings(context: context)),
            onTap: () => context.push('/admin'),
          ),
      ],
    );
  }
}

/// Master-server directory URL used to browse public spaces.
class _ServerDirectorySection extends StatelessWidget {
  const _ServerDirectorySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(UiCopy.serverDirectory(context: context)),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: _MasterServerField(),
        ),
      ],
    );
  }
}

/// Entry point into the updates / release-check page.
class _UpdatesSection extends StatelessWidget {
  const _UpdatesSection();

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(UiCopy.updates(context: context)),
        ListTile(
          leading: Icon(Icons.system_update, color: colors.dirtyWhite),
          title: Text(UiCopy.updates(context: context)),
          subtitle: Text(
            UiCopy.currentVersionCheckForNewReleases(context: context),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showUpdatesSettings(context),
        ),
      ],
    );
  }
}

/// Settings export/import.
class _BackupSection extends StatelessWidget {
  const _BackupSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(UiCopy.backup(context: context)),
        const SettingsBackupSection(),
      ],
    );
  }
}

/// Developer-mode toggle and the Client MCP server page it unlocks.
class _DeveloperSection extends StatelessWidget {
  const _DeveloperSection({required this.settings, required this.controller});

  final AccordSettings settings;
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(UiCopy.developer(context: context)),
        SwitchListTile(
          title: Text(UiCopy.developerMode(context: context)),
          subtitle: Text(
            UiCopy.unlockTheLocalClientMcpServerFor(context: context),
          ),
          value: settings.developerMode,
          onChanged: controller.setDeveloperMode,
        ),
        if (settings.developerMode)
          ListTile(
            leading: Icon(Icons.terminal, color: colors.dirtyWhite),
            title: Text(UiCopy.clientMcpServer(context: context)),
            subtitle: Text(
              UiCopy.tokenPortToolGroupsActivity(context: context),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDeveloperSettings(context),
          ),
      ],
    );
  }
}

/// App name, licence, and version.
class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(UiCopy.about(context: context)),
        ListTile(
          title: const Text('Vokusz'),
          subtitle: Text(
            UiCopy.freeScreenSharingAndStableVoiceNo(context: context),
          ),
          trailing: Text('v$kAppVersion'),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(UiCopy.privacyPolicy(context: context)),
          subtitle: Text(
            UiCopy.howTheAppAndIndependentServersHandle(context: context),
          ),
          trailing: const Icon(Icons.open_in_new, size: 16),
          onTap: () => openOnboardingHelpUrl(kVokuszPrivacyPolicyUrl),
        ),
      ],
    );
  }
}

/// Signs the current account out and returns to the entry route.
class _LogOutTile extends StatelessWidget {
  const _LogOutTile({required this.onLogOut});

  final VoidCallback onLogOut;

  @override
  Widget build(BuildContext context) {
    final colors = BonfireThemeExtension.of(context);
    return ListTile(
      leading: Icon(Icons.logout, color: colors.red),
      title: Text(
        AppStrings.of(context).logOut,
        style: TextStyle(color: colors.red),
      ),
      onTap: onLogOut,
    );
  }
}

/// Lets the user pick which connected server's profile to edit, then opens the
/// per-server profile editor for it.
Future<void> _pickServerProfile(BuildContext context, WidgetRef ref) async {
  final connections = ref.read(connectionsControllerProvider).connections;
  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final conn in connections)
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(
                conn.session.server.name ?? conn.session.server.baseUrl,
              ),
              subtitle: Text(conn.session.username),
              onTap: () {
                Navigator.of(ctx).pop();
                showAccordProfileEdit(context, serverKey: conn.key);
              },
            ),
        ],
      ),
    ),
  );
}

/// Editable master-server directory URL,
/// used to browse public spaces without an account.
class _MasterServerField extends ConsumerStatefulWidget {
  const _MasterServerField();

  @override
  ConsumerState<_MasterServerField> createState() => _MasterServerFieldState();
}

class _MasterServerFieldState extends ConsumerState<_MasterServerField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(settingsControllerProvider).masterServerUrl,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    ref
        .read(settingsControllerProvider.notifier)
        .setMasterServerUrl(_controller.text);
    final applied = ref.read(settingsControllerProvider).masterServerUrl;
    _controller.text = applied;
    FocusScope.of(context).unfocus();
    showInfoSnack(context, UiCopy.masterServerUrlSaved());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              isDense: true,
              labelText: UiCopy.masterServerUrl(context: context),
              hintText: AccordSettings.defaultMasterServerUrl,
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
    );
  }
}
