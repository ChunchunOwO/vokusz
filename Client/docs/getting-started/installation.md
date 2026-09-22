---
title: Installing vokusz
description: Download and install vokusz on Linux, Windows, macOS, Android, or iOS.
order: 1
section: getting-started
---

# Installing vokusz

vokusz is available for Linux, Windows, macOS, Android, iOS, and the web.

## Download

Desktop builds, the Android APK, and the web zip are available from the [GitHub Releases page](https://github.com/ChunchunOwO/vokusz/releases). App Store and Google Play listings are not published yet.

Choose the right file for your platform:

| Platform | File |
|----------|------|
| Linux (x86_64, recommended) | `vokusz-linux-x86_64.deb` |
| Linux (x86_64, portable) | `vokusz-linux-x86_64.tgz` |
| Windows (installer) | `vokusz-windows-x86_64-setup.exe` |
| Windows (portable) | `vokusz-windows-x86_64.zip` |
| macOS | `vokusz-macos-universal.dmg` |
| Android | `vokusz-android.apk` |
| Web | `vokusz-web.zip` |

## Linux

**Package (recommended):** download `vokusz-linux-x86_64.deb` and install it with `sudo dpkg -i vokusz-linux-x86_64.deb` (or open it in your software centre). This is the build that keeps working with the in-app updater.

**Portable:**

1. Extract `vokusz-linux-x86_64.tgz`.
2. Run the `vokusz` executable.
3. On some distributions you may need to mark it as executable first: right-click the file, open Properties, and enable "Allow executing file as program".

The `.deb` registers `vokusz://` links with the desktop. The portable archive
does not alter desktop associations; links can still be pasted into the app.

> **Already on v0.2.6 or earlier?** Those builds could not replace a system
> (`.deb`) install and failed silently, so the app never updated itself. Install
> the `.deb` above by hand once; from v0.2.7 onward the in-app updater handles it
> for you.

## Windows

**Installer:** Download and run `vokusz-windows-x86_64-setup.exe`. It installs vokusz to Program Files, adds a Start Menu shortcut, and registers the `vokusz://` URL scheme so invite links open automatically. A per-user install (no admin rights required) is also supported.

**Portable:** Download and extract `vokusz-windows-x86_64.zip`, then double-click `vokusz.exe` to launch without installing.

The portable archive does not register the `vokusz://` scheme with Windows.

## macOS

1. Open the downloaded `.dmg` file.
2. Drag vokusz to your Applications folder.
3. Launch from Applications. On first launch, you may need to right-click and choose "Open" to bypass Gatekeeper.

## iOS

An App Store listing is not published yet. When a signed iOS build is available, install it from TestFlight or the store listing, then launch Vokusz and connect to your server. Requires iOS 15.6 or later.

## Android

Install the APK from GitHub Releases:

1. Download the `.apk` file to your device.
2. Open it and follow the installation prompts. You may need to allow installation from unknown sources in your device settings.
3. Launch Vokusz from your app drawer.

## Web (JavaScript)

The Web (JavaScript) build runs entirely in your browser with no installation required. Extract `vokusz-web.zip` and open it from a web server, or visit a hosted instance if your server operator provides one. Voice and video are supported via the web audio stack. Note that some features (such as automatic updates and file system access) are not available in the web build.

## Updates

App Store and Google Play installations receive updates through their respective stores.

Desktop and sideloaded Android builds check for updates automatically on startup. When a new version is available, a banner appears at the top of the window. Click it to download and install the update. You can also check manually from the user menu.
