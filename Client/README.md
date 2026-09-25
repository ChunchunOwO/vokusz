# Vokusz — Flutter Client

### Communication without compromise.

**Vokusz** is community chat with native clients, real-time messaging, and a voice stack that is meant to stay **smooth, stable, and free — including screen sharing**. This repository is the **Flutter client**. It talks to *your* Vokusz server, not someone else's cloud.

No ads. No first-party analytics or tracking. No paywall on the call. **Your server, your data, your rules.**

<p align="left">
  <img alt="License: GPLv3" src="https://img.shields.io/badge/license-GPLv3-blue.svg">
  <a href="https://github.com/ChunchunOwO/vokusz/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/ChunchunOwO/vokusz"></a>
  <img alt="Built with Flutter" src="https://img.shields.io/badge/built%20with-Flutter-027DFD.svg">
  <img alt="Platforms" src="https://img.shields.io/badge/platform-Windows-success.svg">
  <img alt="Status: early development" src="https://img.shields.io/badge/status-early%20development-orange.svg">
</p>

> ⚠️ **Early development.** Vokusz is moving fast and things may change. Expect rough edges — and help us file them down.

📖 **[User documentation](docs/index.md)** · 📥 **[Download](https://github.com/ChunchunOwO/vokusz/releases/latest)** · 🐛 **[Issues](https://github.com/ChunchunOwO/vokusz/issues)**

---

## Why Vokusz?

Vokusz is built around the call first:

- 🎙️ **Smooth, stable voice.** LiveKit/WebRTC voice that is meant to hold up in real groups, not just a demo channel.
- 🖥️ **Screen sharing stays free.** Camera and screen share are part of the client. No paid upgrade to share a window.
- 🔒 **Your data, your rules.** No ads, first-party analytics, telemetry, or crash reporting. See the [network and privacy disclosure](docs/privacy-network.md) for the requests normal operation can make.
- 🏠 **Self-hosted by design.** Don't just *join* a server — run your own. Keep full control of community data, accounts, uploads, and voice traffic; Vokusz does not proxy that traffic.
- 🖥️ **Windows first.** The shipping client is the Windows app. Other platforms sit in `MutiVersion/` until they are taken on separately.

This client is the front door: one native app for every screen you own.

---

## ✨ Features

**Messaging**

- 💬 **Real-time messaging** — send, edit, delete, and reply over the Accord gateway, with typing indicators and live presence.
- 🧵 **Threads, forums & pins** — branch a conversation into a thread, run forum-style channels, and pin what matters.
- 😀 **Reactions & emoji** — full unicode support plus custom server emoji, all behind a slick built-in picker.
- 📎 **Files & media** — drag and drop attachments, with inline images, video, and audio playback and a full-screen lightbox.
- 🔍 **Search** — space-scoped message search that jumps you straight to the hit.
- ✉️ **Direct messages & DM calls** — private conversations, one-to-one and group, with voice and video.

**Voice & video**

- 🎙️ **Voice, video & free screen sharing** — crystal-clear, stable calls powered by **LiveKit/WebRTC**. Camera and screen share are built in and not paywalled.

**Servers & communities**

- 🌐 **Multi-server** — connect to many Vokusz servers at once and switch between them seamlessly. Your work crew and your gaming crew, side by side.
- 📁 **Space folders** — collapsed folders show a 2×2 preview of their first four available space icons.
- 🧭 **Discovery** — browse public spaces from the server directory and join them, even before you've signed in anywhere.
- 🛡️ **Server admin tools** — manage channels, roles, permissions, bans, invites, and custom emoji without ever leaving the app.
- 🔗 **Destination-aware app links** — `vokusz://` links open the right server, space, channel, thread, or message once the owning account is ready.

**The app itself**

- 🎨 **Themes** — Dark, Light, Nord, Monokai, and Solarized built in, plus fully custom colors you can copy, paste, and share in chat.
- 👥 **Multiple profiles** — keep separate local profiles on one device and switch between them without signing out.
- 🔐 **Secure sign-in** — session tokens live in the OS credential vault, with optional TOTP two-factor authentication; each device profile keeps its own credential, even for the same account.
- ⬆️ **In-app updates** — direct-download desktop and sideloaded Android builds check for, download, and install new releases themselves. Package-managed builds leave updates to their manager.
- 📱 **Responsive everywhere** — one UI that flows from phone to desktop, sharp at every size.
- 🛠️ **Local MCP tools** — opt-in desktop automation with bearer authentication and configurable tool groups. See [local MCP troubleshooting](docs/troubleshooting/common-issues.md#local-mcp-tools-not-connecting).

---

## 📥 Download

Grab the latest build from the **[Releases page](https://github.com/ChunchunOwO/vokusz/releases/latest)**. App Store and Google Play listings are not published yet.

| Platform | File |
|---|---|
| Windows (installer) | `vokusz-windows-x86_64-setup.exe` |
| Windows (portable) | `vokusz-windows-x86_64.zip` |

Every release ships a `SHA256SUMS.txt` so you can verify what you downloaded. Step-by-step instructions live in [Installing vokusz](docs/getting-started/installation.md).

Windows is the shipping platform. Android, Linux, macOS, and iOS are parked in [`MutiVersion/`](../MutiVersion).

---

## 🚀 Getting started

Vokusz connects only to **Vokusz/Accord servers**. You don't sign in to a central service; you connect directly to a server.

1. Open the app.
2. Click the **`+`** at the bottom of the space bar on the left.
3. Enter the server's address — a hostname is enough:

   ```
   chat.example.com
   ```

   Self-hosting on your own machine or LAN? Include the scheme, e.g. `http://localhost:39099`.

4. Sign in with your username and password, or switch to **Register** to create an account on that server.
5. That's it — you're in. 🎉

You can add as many servers as you like; each gets its own icon in the space bar.

The address also accepts extras: a port (`chat.example.com:8443`), a space (`chat.example.com#my-space`), an invite code (`?invite=…`), or a pre-issued token (`?token=…`, which signs you straight in). See [Adding a Server](docs/getting-started/adding-a-server.md) for the full format.

No address at all? Open **Discovery** and browse public spaces from the server directory.

### Don't have a server yet?

Run your own. **AccordServer** is the open-source, Rust-powered backend that powers every Vokusz community — your infrastructure, your rules.

The easiest route is the **Accord desktop app**: a tray application that bundles the server and a LiveKit voice server, configures itself on first launch, and keeps itself updated — no Docker, no command line. For an always-on public server, deploy `accordserver` with Docker or from source.

➡️ **[Server backend](../Server)** · [Self-hosting guide](docs/self-hosting/overview.md)

---

## 📚 Documentation

End-user documentation lives in [`docs/`](docs/index.md):

- [Installing vokusz](docs/getting-started/installation.md) · [Adding a server](docs/getting-started/adding-a-server.md) · [Creating an account](docs/getting-started/creating-an-account.md)
- [Spaces and channels](docs/navigation/spaces-and-channels.md) · [Sending messages](docs/messaging/sending-messages.md) · [Voice and video](docs/voice-and-video/voice-channels.md)
- [Themes and appearance](docs/customization/themes.md) · [Profiles](docs/customization/profiles.md)
- [Managing your space](docs/administration/managing-your-space.md) · [Moderation](docs/administration/moderation.md) · [Invites](docs/administration/invites.md)
- [Self-hosting](docs/self-hosting/overview.md) · [Network behavior and privacy](docs/privacy-network.md) · [Troubleshooting](docs/troubleshooting/common-issues.md)

Maintainer-facing notes: [release signing](docs/release-signing.md).
CI checks Mac upload metadata isolation before release builds; see the store deployment guide for retrying a failed Mac upload.
Manual CI includes platform build checks by default (`build_artifacts=true`); store recovery runs the test gates and its selected store build.

---

## 🧱 How it's built

Vokusz stands on the shoulders of giants. It's a fork of **[Bonfire](https://github.com/OpenBonfire/bonfire)** — a mature, fast, cross-platform Flutter chat client. We reuse Bonfire's polished UI, theming, routing, and caching, and **replaced its original networking layer entirely** with the **Accord protocol** via **accordkit**.

The result: Bonfire's battle-tested experience pointed at a platform that's actually free and open — Vokusz, with voice and screen sharing as first-class features.

A single gateway dispatcher subscribes to Accord's event streams, updates per-feature caches, and exposes Riverpod providers to the UI.

### Current limitations

The core messaging, administration, and LiveKit calling paths are implemented, but early-development gaps still affect day-to-day expectations:

- Background push delivery is not implemented; notifications are currently foreground-only ([#81](https://github.com/ChunchunOwO/vokusz/issues/81)).
- Attaching MP3 files fails on Windows ([#196](https://github.com/ChunchunOwO/vokusz/issues/196)).
- Bearer tokens can still be embedded in server URLs instead of exchanged for one-time codes ([#269](https://github.com/ChunchunOwO/vokusz/issues/269)), and self-update integrity verification does not yet fail closed against a signed manifest ([#264](https://github.com/ChunchunOwO/vokusz/issues/264)).
- Store signing and distribution setup is still being completed for some release targets ([#90](https://github.com/ChunchunOwO/vokusz/issues/90), [#123](https://github.com/ChunchunOwO/vokusz/issues/123)), and the iOS App Store submission is still working through review ([#285](https://github.com/ChunchunOwO/vokusz/issues/285), [#286](https://github.com/ChunchunOwO/vokusz/issues/286)).

See the [open issue tracker](https://github.com/ChunchunOwO/vokusz/issues) for the current backlog rather than treating this list as exhaustive.

### Tech stack

| Concern | Choice | Notes |
|---|---|---|
| Language / framework | Dart / Flutter | |
| State management | [Riverpod 3](https://riverpod.dev/) | `flutter_riverpod` + `riverpod_annotation` codegen (`*.g.dart`) |
| Routing | [`go_router`](https://pub.dev/packages/go_router) | |
| Local storage | [`hive_ce`](https://pub.dev/packages/hive_ce) | device boxes `auth`, `last-location`, `added-accounts`, `space-cache`, `window-state`; `accord-session` / `accord-settings` are opened per local profile |
| Credentials | [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | session tokens live in the OS credential vault; Hive keeps only opaque references |
| Networking | `accordkit` | Accord protocol SDK — REST + gateway WebSocket + models. Vendored in-tree at `packages/accordkit` and maintained here |
| Voice / video / screen share | [`livekit_client`](https://pub.dev/packages/livekit_client) | local fork at `packages/livekit_client`, over WebRTC |
| Media | [`media_kit`](https://pub.dev/packages/media_kit) / [`video_player`](https://pub.dev/packages/video_player) / `cached_network_image` | media_kit everywhere except iOS, which uses AVFoundation via `video_player`; local fork at `packages/media_kit` for a player-dispose crash; CDN URLs point at the Accord server |
| Markdown | `markdown_viewer` | custom renderer at `packages/markdown_viewer` |
| Serialization | Hand-written JSON | most model types come from `accordkit` (`Accord*`) |

### Domain model

Accord vocabulary:

| Term | accordkit type | Meaning |
|---|---|---|
| **Space** | `AccordSpace` | a server / community |
| **Channel** | `AccordChannel` | text, voice, forum, or category |
| **Message** | `AccordMessage` | |
| **Member** | `AccordMember` | a user within a space |
| **User** | `AccordUser` | |
| **Role** | `AccordRole` | |

---

## 🛠️ Building from source

You'll need the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed. The helper scripts in [`scripts/`](scripts/README.md) wrap the common flows and prefer [fvm](https://fvm.app) when it's available:

```bash
scripts/setup.sh                 # deps + one-shot codegen (also installs Linux desktop build deps)
scripts/codegen.sh --watch       # keep this open while developing
scripts/start.sh --flavor github # run on an Android device/emulator
scripts/start.sh -d chrome       # run in Chrome
```

Or drive Flutter directly:

```bash
flutter pub get
dart run build_runner watch -d        # keep running during dev (Riverpod codegen)
flutter run --flavor github            # Android device/emulator (a flavor is required)
flutter run -d chrome                  # browser; non-Android platforms have no flavor
```

`build_runner watch -d` regenerates Riverpod `*.g.dart` files. Keep it running
while developing, or run the same one-shot generation check as CI after editing
any `@riverpod`-annotated file:

```bash
scripts/codegen.sh --check
```

`scripts/codegen.sh --check` is the same check CI runs: it performs a
deterministic one-shot build and lists any tracked or untracked `*.g.dart`
outputs that still need to be committed.

### Lint & test

```bash
flutter analyze --no-fatal-infos       # --no-fatal-infos keeps inherited Bonfire-style infos non-fatal
flutter test                           # unit/widget tests (voice/settings/server logic)
(cd packages/accordkit && dart analyze && dart test)
(cd packages/markdown_viewer && \
  flutter analyze --no-fatal-infos && flutter test)
gradle --project-dir android :livekit_client:testDebugUnitTest \
  --tests io.livekit.plugin.AudioResamplerTest
```

CI treats the root analyze/test job, the full vendored-package suites (including
all Markdown renderer corpus cases), the Android native seam, and the accordkit
protocol-integration job as merge and release gates. Broader client ↔ server,
UI end-to-end, multi-instance, and LiveKit SFU scenarios run advisory
(`continue-on-error`).

### Release builds

```bash
scripts/build.sh windows
flutter build windows
```

Tagging `v<version>` (matching `pubspec.yaml`) runs the Windows release workflow. See [release signing](docs/release-signing.md).

---

## ❓ FAQ

**Is Vokusz really free?**
Yes — completely free and open source under the GPLv3. Nothing is locked behind a paywall.

**Where is my data stored?**
Community data is stored on whichever Accord server you connect to — including one you host yourself. Vokusz does not proxy that server or voice traffic. Your session tokens are kept in your operating system's credential vault. The client can still make ancillary requests for discovery, updates, and explicitly approved external media; see [Network behavior and privacy](docs/privacy-network.md).

**Do I need one account per server?**
Yes. Accounts live on the server you register with, so each server you add has its own sign-in. You can be signed in to many at once, and switch local profiles to keep identities separate on a shared device.

**Do I need to run a server to use Vokusz?**
No — you can join any Accord server you have an address for, or find one through Discovery. But hosting your own gives you full control. See [Don't have a server yet?](#dont-have-a-server-yet)

**How do I update?**
Desktop and sideloaded Android builds check on startup and can install the update for you. Otherwise grab the newest build from [Releases](https://github.com/ChunchunOwO/vokusz/releases/latest).

**Which platforms are supported?**
Android, iOS, Windows, macOS, Linux, and the Web.

---

## 🤝 Be part of it

> This only works if we do it together.

Vokusz grows because people like you show up. It's open source and community-driven — every contribution, bug report, and pull request makes it better for everyone.

- 🐛 **Report bugs** — open an [issue](https://github.com/ChunchunOwO/vokusz/issues) and help us improve.
- 💻 **Contribute code** — pull requests are welcome.
- 🚀 **Launch a server** — host your own backend from [`../Server`](../Server) and grow a community.

If you're contributing code, a few house rules keep this a port rather than a rewrite:

- Keep changes **minimal and reuse-first** — prefer adapting existing Bonfire widgets, controllers, routing, and theming.
- Keep new code inside the relevant `lib/features/<feature>/` module and match the surrounding style.
- Run `scripts/codegen.sh --check` after touching any `@riverpod`-annotated file.
- Update contributor and user documentation in the same PR when changing dependencies, generation, build/test commands, CI, supported platforms, or feature behavior. Reviewers should verify those instructions against `pubspec.yaml` and the workflows instead of preserving volatile version or test-count claims.
- Don't reintroduce third-party chat-network endpoints, branding, or Firebase push. This client talks only to Accord servers.
- Run `flutter analyze --no-fatal-infos` and `flutter test` before opening a PR.

---

## Related code in this repo

| Path | What it is | Language |
|---|---|---|
| **this directory** (`Client/`) | Flutter client (what you ship) | Dart / Flutter |
| [`../Server`](../Server) | Chat/voice backend and desktop host app | Rust |

`accordkit`, `livekit_client`, and `markdown_viewer` are vendored in-tree under `packages/` and maintained here.

---

## 📄 License

Licensed under the **[GNU General Public License v3.0](LICENSE)** (GPLv3), inherited from Bonfire. AccordKit-Dart is MIT-licensed; GPLv3 may incorporate MIT-licensed code, so depending on `accordkit` is fine.

### Automatic moderation

Configure server and space rules, review held uploads, and block repeated file
uploads through the AutoMod controls. See [the client AutoMod guide](docs/automod.md)
for permissions, video sampling, private evidence, and cooldown behavior.

Read positions synchronize across connected devices, with retries for failed
acknowledgements and replay suppression for notifications. See the
[read-state audit](docs/notification-read-state-audit.md) for behavior and limits.

Space image edits preview the selected crop immediately and refresh saved icons
and banners in the current session. Channel administration is available from the
**Space actions** menu beside the channel panel's search button. **Voice & Video**
settings includes optional relay-only connections; see [network privacy](docs/privacy-network.md).

The opt-in [MCP space management tools](docs/developer/mcp-space-management.md)
create spaces and manage their settings, categories and channels through the
active account's permissions.

Discovery and invite joins reuse saved accounts, including during startup;
see [adding a server](docs/getting-started/adding-a-server.md#joining-with-a-saved-account).

YouTube previews offer consent-gated playback on Web and an external link on
native clients. Appearance settings can hide embeds locally; see
[link previews](docs/messaging/sending-messages.md#link-previews).

## 界面语言

Web 与 Windows 共用简体中文和英文界面，可在“设置 → 外观 → 语言”中切换。文案规范、验证与部署记录见 [中英双语复核](docs/localization-review.md)。

Attachment uploads default to 1 GB per file; see [file sharing](docs/messaging/file-sharing.md) for server limits and upgrade behavior.

Screen sharing: choose resolution (480p–1440p) and frame rate (5–60 FPS) in the desktop source picker or Voice & Video settings. New profiles default to 720p/30 FPS; existing saved choices are retained. Changes apply to the next share. Use 480p/10–15 FPS for lower resource usage, or 60 FPS for motion. Windows x64 uses bundled OBS core with Windows Graphics Capture for GPU scaling and color conversion before WebRTC encoding. No separate OBS installation is required. Web and other platforms retain their existing backends.

Space overview changes are saved before leaving settings; failed saves retain the draft and show an error.


Domain permissions: 社区 is the server-wide community; 域 maps to Space; a domain
contains category groups and text/voice channels. The domain creator is 域主.
Default groups are 高级管理员 (structure and moderation), 管理员 (moderation),
嘉宾 (no administrative grants), and 普通成员 (the implicit position-zero role).
Only the domain owner or community administrator creates permission groups;
role edits and assignments respect hierarchy. Community administrators manage
all domains and their names use a distinct color. Channel overrides refine
existing domain roles; channels do not have a separate owner/role system.

The account-switcher screen has been removed. Use Log out and the normal sign-in form to sign in with another account.

OBS capture build, lifecycle and native verification: [docs/voice-and-video/obs-capture.md](docs/voice-and-video/obs-capture.md).

The rail **+** opens Join / Create domain. Copy the domain ID from the square badge below its name. ID joins use public domains in the current community; private domains require an invitation. Creation exposes an explicit public-ID-join toggle.
