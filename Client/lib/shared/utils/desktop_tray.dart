import 'dart:async';

import 'package:bonfire/l10n/app_strings.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:window_manager/window_manager.dart';

bool get _desktopTrayEnabled =>
    !UniversalPlatform.isWeb &&
    (UniversalPlatform.isWindows ||
        UniversalPlatform.isLinux ||
        UniversalPlatform.isMacOS);

const _trayIcon = 'windows/runner/resources/app_icon.ico';

final _tray = _DesktopTray();

/// Hides the window into the tray instead of quitting. The tray menu's exit
/// item is what actually ends the process.
Future<void> hideDesktopWindowToTray() async {
  if (!_desktopTrayEnabled) return;
  await windowManager.hide();
}

Future<void> showDesktopWindow() async {
  if (!_desktopTrayEnabled) return;
  if (await windowManager.isMinimized()) await windowManager.restore();
  await windowManager.show();
  await windowManager.focus();
}

Future<void> quitDesktopApp() async {
  if (!_desktopTrayEnabled) return;
  await windowManager.setPreventClose(false);
  await trayManager.destroy();
  await windowManager.destroy();
}

/// Tray icon and the right-click menu. Safe to call again when the language
/// changes; the menu labels are rebuilt.
Future<void> setupDesktopTray() async {
  if (!_desktopTrayEnabled) return;
  await _tray.install();
}

class _DesktopTray with TrayListener {
  bool _installed = false;

  Future<void> install() async {
    if (!_installed) {
      trayManager.addListener(this);
      _installed = true;
    }
    await trayManager.setIcon(_trayIcon);
    await trayManager.setToolTip('Vokusz');
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(
            key: 'show',
            label: AppStrings.choose('Show main window', '显示主界面'),
          ),
          MenuItem(
            key: 'exit',
            label: AppStrings.choose('Exit', '退出'),
          ),
        ],
      ),
    );
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(showDesktopWindow());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        unawaited(showDesktopWindow());
      case 'exit':
        unawaited(quitDesktopApp());
    }
  }
}
