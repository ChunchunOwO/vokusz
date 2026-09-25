# AGENTS.md

This file provides guidance to Grok when working with code in this repository.

## What this project is

This repository is the **Flutter/Dart client for Vokusz** — community chat whose differentiators are **free screen sharing** and **smooth, stable voice**. It is a **fork of [Bonfire](https://github.com/OpenBonfire/bonfire)**.

We reuse Bonfire's Flutter UI and talk to Vokusz servers over the Accord protocol. Screen share and voice (LiveKit/WebRTC) are first-class features, not paid add-ons.

### Hard requirements (do not violate)

- **Accord only.** This client talks **only** to Vokusz/Accord servers. Do not add third-party chat-network hosts, gateways, OAuth/token flows, or Firebase-push code paths.
- **License stays GPLv3.** Bonfire is licensed GPL-3.0 and we retain it. See `LICENSE`. AccordKit-Dart is MIT — GPLv3 may incorporate MIT-licensed code, so depending on `accordkit` is fine. Keep the `LICENSE` file as GPL-3.0; any new files inherit GPLv3.
- **Reuse Bonfire.** Prefer adapting existing Bonfire widgets, controllers, routing, theming, and caching over rewriting. The networking/models swap is the bulk of the work; the UI should change as little as possible.
- **Voice, video & screen sharing are implemented.** Real-time voice, video, and screen sharing (LiveKit/WebRTC transport) are fully supported. Maintain and extend the existing voice stack; don't stub or hide voice UI.

## Layout of this monorepo

| Path | What it is | Language | Role here |
|------|-----------|----------|-----------|
| **this directory** (`Client/`) | Flutter UI | Dart/Flutter | The client we ship |
| [`../Server`](../Server) | Accord server backend and desktop host | Rust | Voice, API, gateway |
| `packages/accordkit` | Accord protocol SDK (vendored) | Dart | Networking layer (replaces firebridge) |

## Architecture (inherited from Bonfire)

- **State management:** Riverpod 3 (`flutter_riverpod`, `riverpod_annotation` with codegen → `*.g.dart`).
- **Models / serialization:** primarily provided by `accordkit` (`Accord*` types). The handful of client-local models (server config, session, device profile, space folders, settings) hand-roll `fromJson`/`toJson` — they're small and Hive-backed, so codegen serializers aren't used. The only generated files in `lib/` are Riverpod's `*.g.dart` files.
- **Routing:** `go_router`.
- **Local storage:** `hive_ce` — boxes opened in `setupHive()`: `auth`, `last-location`, `added-accounts`, `space-cache`, `window-state`, `pending-uploads` (per-connection AutoMod-held upload IDs), plus the per-profile `accord-session` and `accord-settings`.
- **Networking:** `accordkit` (vendored in-tree at `packages/accordkit`, maintained here). **The firebridge → accordkit swap is complete** — `packages/firebridge` and `firebridge_extensions` no longer exist and nothing in `lib/` imports them (a few doc comments still mention "firebridge" to describe what a controller replaced). Do not try to re-add firebridge.
- **Voice/video/screen share:** `livekit_client` (a local fork at `packages/livekit_client`, see #68) over WebRTC; credentials fetched via accordkit's `client.voice`. See `lib/features/voice/`.
- **Media:** `media_kit` (a local fork at `packages/media_kit`; `media_kit_video` and `video_player_media_kit` stay pinned git forks) / `cached_network_image` / `file_picker` — re-point CDN URLs at the Accord server. The fork defers closing libmpv's wakeup `NativeCallable` until after `mpv_terminate_destroy`; closing it early aborted the process whenever a video attachment was disposed (upstream PR #1424).
- **Riverpod generation is required after changing annotated providers:** run
  `dart run build_runner build -d` once, or keep
  `dart run build_runner watch -d` running while editing them. Client model
  serialization is handwritten; there is no JSON-model generation step.

### Layout

```
lib/
  features/        # feature modules: authentication, spaces, channels, messaging,
    <feature>/     #   member, user, admin, server, events, voice, notifications,
      controllers/ #   settings, developer, profiles, updates, ...
      repositories/# data access (accordkit-backed)
      views/       # screens
      models/      # feature models
  shared/          # shared components, models, repositories, utils
  theme/           # theming
  router/          # go_router config
  main.dart        # startup: media_kit, Hive, ProviderScope, ProfileGate, deep links
packages/
  accordkit/       # Accord protocol SDK (REST + gateway + models) — networking layer, maintained here
  livekit_client/  # local fork of livekit_client 2.8.0 (#68 native-release fix) — voice transport
  media_kit/       # local fork of media_kit 1.1.11 (player-dispose SIGABRT fix) — video decode
  markdown_viewer/ # custom markdown rendering — protocol-agnostic, KEEP
tool/
  store_capture/   # on-demand App Store screenshot harness: a web entry point that
                   #   boots the real app against an offline fixture, plus the
                   #   headless-Chromium driver. Not part of `flutter test`; see
                   #   docs/app-store-deploy.md ("Guideline 2.3.10").
docs/              # product + technical specs (see below)
windows/ web/      # Windows is the main line. Other runners live in ../../MutiVersion/
```

Cross-cutting startup features wired in `lib/main.dart`:
- **Server config:** `lib/features/server/models/accord_server.dart` defines `AccordServer` (`baseUrl`/`gatewayUrl`/`cdnUrl`, derived from a base URL). The live per-server `AccordClient` instances are owned by `AccordAuth` (`lib/features/authentication/repositories/accord_auth.dart`, exposed as `accordAuthProvider`); `lib/features/server/controllers/connections.dart` holds the rail's per-connection UI state (session + status + cached spaces), not the clients.
- **Multi-profile:** the app is wrapped in `AppRestart` for switching between accounts, and `ProfileGate` (the PIN lock) is hosted from the router app's `MaterialApp.builder` via `buildAppShell` (`lib/shared/components/app_shell.dart`) together with the incoming-call banner. Do not wrap `MainWindow` in another `MaterialApp`/Navigator: go_router's navigator must stay the root navigator (#324).
- **Deep links:** `vokusz://` URLs (navigate / connect / invite) are parsed via `ServerUri.parseDeepLink()`. Qualified navigation is held by `pendingDeepLinkProvider` until authentication and the owning connection's live space cache are ready; the `/spaces` route then hands channel/message targeting to `AccordHomeScreen`.
- **Developer mode:** an MCP server (`mcpServerControllerProvider`) for in-app tooling. HTTP notifications are acknowledged with status 202 and an empty body; see `docs/troubleshooting/common-issues.md` for the local connection settings.

## Domain mapping: Bonfire → Accord

Bonfire's leftover vocabulary differs from Accord. When migrating a feature, translate:

| Bonfire / firebridge | Accord (accordkit) | Notes |
|----------------------|--------------------|-------|
| Guild | **Space** (`AccordSpace`) | server/community |
| Channel | **Channel** (`AccordChannel`) | types: text, voice, forum, category |
| Message | **Message** (`AccordMessage`) | |
| Member | **Member** (`AccordMember`) | |
| User | **User** (`AccordUser`) | |
| Role | **Role** (`AccordRole`) | |
| Snowflake | snowflake (string or int) | accordkit parses leniently |
| Gateway | Gateway (Accord) | `wss://<server>/ws?v=1&encoding=json` |
| Third-party CDN hosts | `<server>/cdn` | configurable per-server |
| User token / OAuth | Accord token (`Bot`/`User` token type) | sent in REST headers + gateway IDENTIFY |

## AccordKit-Dart: the new networking layer

Vendored in-tree and wired via a path dependency in `pubspec.yaml`:

```yaml
dependencies:
  accordkit:
    path: packages/accordkit
```

The SDK source now lives at `packages/accordkit` and is maintained in this repo (no longer a git dependency on `ChunchunOwO/accordkit-dart`). Edit it directly here.

Entry point is `AccordClient` (`package:accordkit/accordkit.dart`):

```dart
final client = AccordClient(
  token: token,
  tokenType: 'User',            // or 'Bot'
  baseUrl: 'https://your.accord.server',
  gatewayUrl: 'wss://your.accord.server/ws',
  intents: [GatewayIntents.spaces, GatewayIntents.messages, GatewayIntents.messageContent],
);
client.login(); // opens the gateway
```

- **REST:** namespaced APIs on the client — `client.spaces`, `client.channels`, `client.messages`, `client.members`, `client.roles`, `client.users`, `client.invites`, `client.reactions`, `client.emojis`, `client.auth`, etc. Each call returns a `RestResult` with `.ok`, `.data`, `.error` and `.statusCode`. Rate-limit (429) retry is built in, as is a per-attempt request timeout (`AccordConfig.defaultRequestTimeout`, overridable via `AccordClient(requestTimeout: …)`) that surfaces as a normal `RestResult` failure. Endpoint paths are bare — the `/api/v1` prefix lives on the `AccordRest` base URL.
- **Gateway:** ~50 typed `Stream` properties — `client.onMessageCreate`, `onMessageUpdate`, `onMessageDelete`, `onPresenceUpdate`, `onTypingStart`, `onMemberJoin`, `onChannelCreate`, `onReady`, `onReconnecting`, … plus `onRawEvent`. Wire these into Riverpod controllers the same way Bonfire wires firebridge cache events today (see `lib/features/events/`).
- **Voice:** `client.voice.join(channelId)` / `client.voice.leave(channelId)` return LiveKit credentials (`AccordVoiceServerUpdate` with `livekitUrl` + `token`); the `livekit_client` SDK (`packages/livekit_client`) is the actual transport. State lives in `VoiceConnection` (Riverpod) over a `VoiceSession` that wraps a LiveKit `Room`. Gateway `voice.server_update` events drive credential-refresh reconnects. See `lib/features/voice/`.

The actual wiring: a single gateway dispatcher (`lib/features/events/services/accord_event_handler.dart`, which delegates the message domain to `accord_message_events.dart` and the READY bootstrap to `accord_ready_sync.dart`) subscribes to every gateway stream and calls imperative mutators on the per-feature Riverpod cache controllers (`accord_messages`, `accord_members`, `accord_channels`, …). Those same controllers own the REST reads/writes for their domain, and screens `watch` them. A dedicated per-feature `repositories/` layer exists only for `authentication` (`AccordAuth`, which owns the clients) — elsewhere data access lives in the controllers (and, for some admin/moderation screens, directly in the views).

## Build / run / test

- Public support/privacy URLs live in `lib/shared/app_info.dart` (GitHub docs in this repo).

```bash
flutter pub get
dart run build_runner watch -d        # keep running during dev (codegen)
scripts/codegen.sh --check             # regenerate + verify committed *.g.dart

flutter run -d windows
flutter analyze --no-fatal-infos
flutter test
flutter test test/features/voice/voice_logic_test.dart

flutter build windows -v
```

CI is at the repo root (`.github/workflows/`): Windows analyze/test, and tagged Windows releases.

## Migration status

The firebridge → Accord migration is **essentially complete**: firebridge is gone, all 50+ feature files use `accordkit`, auth/spaces/channels/messaging/members/roles/voice are implemented, and third-party chat-network / Firebase code paths are gone. Remaining work is product polish — especially **smooth, stable voice** and **free screen sharing** — not a wholesale protocol swap.

When in doubt about Accord behaviour, read `packages/accordkit` (the vendored SDK source) and `../Server` (the Rust backend).

## Conventions

- Match the surrounding code's style; Bonfire is feature-modular — keep new code inside the relevant `lib/features/<feature>/` module.
- Run `scripts/codegen.sh --check` after changing any `@riverpod`-annotated
  file. It regenerates `*.g.dart` and fails with the tracked or untracked paths
  that still need to be committed.
- Documentation is part of the change: authors who alter dependencies,
  generation, build/test commands, CI, or supported behavior must update
  `README.md`, this file, and relevant `docs/` pages in the same PR. Reviewers
  should verify commands against `pubspec.yaml` and workflows rather than copy
  volatile dependency versions or test counts.
- Keep changes minimal and reuse-first; this is a port, not a rewrite.
- Session credential references remain random and profile-local. Platform vault operations share an isolate-wide queue because the Linux backend rewrites the entire vault; see `test/features/authentication/session_credential_vault_test.dart`.
- Don't reintroduce third-party chat-network endpoints, branding, or Firebase push without explicit instruction.

## Read state

Read-state updates live in `accord_message_events.dart`; READY cursors are
parsed in `accord_ready_sync.dart`. Use `ReadStateController.acknowledge` for
local reads so retries, monotonic cursors and notification dismissal stay
consistent. Details: `docs/notification-read-state-audit.md`.

## AutoMod

`lib/features/automod/` owns the policy/review UI and block-before-delete flow.
Keep configuration (`manage_space`), review (`moderate_members`), and stored-file
blocking (effective channel `manage_messages`) separate; instance scope requires
an administrator. `docs/automod.md` documents the client contract. Private
evidence must use the authenticated SDK endpoint and must be cleared on account
changes. Moderator mutations opt out of automatic 429 retry. Tests live in
`test/features/automod/` and `packages/accordkit/test/automod_management_test.dart`.

## Space media, composer and voice behavior

Space settings retain pending image bytes and export bounded PNG crops; banner
previews preserve 16:9 framing. `SpaceMediaCache` evicts only replaced assets and
revisions their provider URLs so mounted rail/settings images refresh. Channel
header management actions use the permission-filtered Space actions menu.
The web composer leaves paste shortcuts to the browser editor; native clients
retain image and large-text clipboard handling. `voiceRelayOnly` is an opt-in
persisted setting passed to LiveKit on initial connection and every reconnect;
it requires TURN support and never falls back to direct candidates on failure.

MCP's optional `space_management` group provides create/update space and
create/update/delete/reorder channel tools. Its schemas and validated handlers
live in `mcp_tools/space_management.dart`; mutations fetch fresh permissions and
return entity data while refreshing caches. See `docs/developer/mcp-space-management.md`.

Saved-account joins use `AccordAuth.ensureConnectionForBaseUrl` and
`joinOnConnection` before requesting credentials. Endpoint identity preserves
transport/port/path boundaries. `pendingServerJoinProvider` retains the invite
through login; `pendingDeepLinkProvider` opens the hydrated space on its account.

YouTube embeds use validated provider URLs and the official iframe API through
the direct `web` dependency. The conditional native implementation offers
external playback. Keep poster/player requests behind explicit consent and
release player resources on visibility/lifecycle changes. `showEmbeds` is a
local preference; the message suppression bit is separate. Server-side author
suppression and asynchronous unfurl policy remain tracked by #352.

### Package-manager distribution

`docs/packaging.md` tracks manifest generation, distribution credentials and
catalogue acceptance. Run `python3 -m unittest discover -s test/packaging -p 'test_*.py'`
for changes to the generator or recipes; CI includes it in Release tooling. Package-managed builds use `--dart-define=PACKAGE_MANAGER=true`;
wrappers can set `VOKUSZ_PACKAGE_MANAGER`, and Windows installers/Scoop write
`vokusz.package-manager` beside the executable. The shared `isSelfUpdateEnabled`
gate disables checks, downloads and staged installation without disabling desktop
Developer Mode. Existing releases predating this gate must not be submitted with
marker-based recipes. Do not advertise catalogue install commands before acceptance.
Collapsed rail folders reuse the size-aware space icon renderer for their first
four resolved members; keep normal and drag previews consistent.

## Interface localization

Web and Windows share `lib/l10n/app_strings.dart`, `ui_copy.dart` and `static_copy.dart`. Keep both Simplified Chinese and English. Use context-aware copy during widget builds; callbacks without a usable context use the active application locale. Translate fixed display catalogs, never protocol identifiers or user content. Run `flutter test test/l10n` after localization changes; see `docs/localization-review.md`.

Image crop export uses `instantiateImageCodecWithSize`: encoded `ImageDescriptor.width/height` are unsupported on web. Attachment defaults are 1 GiB, with a 60-minute upload timeout. Run the crop tests on Chrome as well as native when changing image preparation.

Screen sharing: choose resolution (480p–1440p) and frame rate (5–60 FPS) in the desktop source picker or Voice & Video settings. New profiles default to 720p/30 FPS; existing saved choices are retained. Changes apply to the next share. Use 480p/10–15 FPS for lower resource usage, or 60 FPS for motion. Windows x64 uses bundled OBS core with Windows Graphics Capture for GPU scaling and color conversion before WebRTC encoding. No separate OBS installation is required. Web and other platforms retain their existing backends.

Space settings use PopScope to save changed overview drafts before route exit; errors keep the route open. Keep the top save action accessible. Regression: `flutter test test/features/spaces/space_settings_save_test.dart`.


Domain permissions: 社区 is the server-wide community; 域 maps to Space; a domain
contains category groups and text/voice channels. The domain creator is 域主.
Default groups are 高级管理员 (structure and moderation), 管理员 (moderation),
嘉宾 (no administrative grants), and 普通成员 (the implicit position-zero role).
Only the domain owner or community administrator creates permission groups;
role edits and assignments respect hierarchy. Community administrators manage
all domains and their names use a distinct color. Channel overrides refine
existing domain roles; channels do not have a separate owner/role system.

Do not expose the removed `/switcher` route or account-switcher UI. Keep saved-session restoration and multi-server connection handling intact.

Sidebar groups use server-scoped collapse preferences. Members with manage_channels
can drag channels directly onto a group header or the Ungrouped drop area; group
headers can also be reordered. Members with move_members can drag voice participants
onto another voice channel in the same domain. The server validates both channel
permissions, hierarchy, current source, and the moved member's destination access.

OBS capture build, lifecycle and native verification: [docs/voice-and-video/obs-capture.md](docs/voice-and-video/obs-capture.md).

Domain entry: the rail + uses DomainEntryDialog and the existing joinOnConnection repository path. Public domains support numeric ID joins within the active community; private domains retain invite authorization. The header's square ID badge copies the full ID. Ungrouped channel drops retain an unlabeled target. Regression: flutter test test/features/spaces/domain_entry_dialog_test.dart.
