import 'dart:ui';

import 'package:bonfire/shared/utils/desktop_window.dart';
import 'package:bonfire/shared/utils/window_corners.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

/// The small always-on-top voice window. Geometry only — the bar widget is
/// separate so the title-bar button does not pull the voice stack into tests.
class CompactVoiceMode extends ChangeNotifier {
  CompactVoiceMode._();

  static final CompactVoiceMode instance = CompactVoiceMode._();

  static const double width = 336;
  static const double cornerRadius = 16;
  static const double barHeight = 48;
  static const double rule = 1;
  static const double stripHeight = 80;

  /// Bar only. The avatar strip adds [stripHeight] once people are in the channel.
  static const Size windowSize = Size(width, barHeight + rule);
  static const double expandedHeight = barHeight + rule + stripHeight;

  bool active = false;
  bool allowEnter = true;
  Rect? _restore;
  bool _wasMaximized = false;
  Size _size = windowSize;

  /// Latest [fit] wins. An earlier shrink must not land after a later grow,
  /// or the strip stays clipped and the people in the channel look hidden
  /// until the next speaking update rebuilds the bar.
  int _fitSerial = 0;

  /// Height last applied to the window. The avatar strip waits for this so it
  /// does not paint past the locked bar for a frame.
  double get appliedHeight => _size.height;

  Future<void> enter() async {
    if (active || !allowEnter || !desktopChromeEnabled()) return;
    try {
      _wasMaximized = await windowManager.isMaximized();
      await flushWindowGeometry();
      suppressWindowGeometryPersistence = true;
      if (_wasMaximized) await windowManager.unmaximize();
      _restore = await windowManager.getBounds();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setMinimumSize(windowSize);
      await windowManager.setMaximumSize(Size(width, expandedHeight));
      // Start tall enough for the avatar strip. A later fit shrinks this when
      // the channel is empty. Starting at the bar height clips the strip until
      // that resize lands, so silent users never appear.
      final opened = Size(width, expandedHeight);
      await windowManager.setSize(opened);
      _size = opened;
      await WindowCorners.setRounded(true, radius: cornerRadius.round());
      active = true;
      notifyListeners();
    } catch (error, stack) {
      suppressWindowGeometryPersistence = false;
      await WindowCorners.setRounded(false);
      debugPrint('Compact voice mode failed: $error\n$stack');
    }
  }

  /// Grows or shrinks the locked window. Width stays [windowSize]'s width.
  /// The temporary size is not written to the saved window geometry.
  Future<void> fit(double height) async {
    if (!active) return;
    final next = Size(width, height);
    if (_size == next) return;
    final serial = ++_fitSerial;
    try {
      final grow = next.height >= _size.height;
      if (grow) {
        await windowManager.setMaximumSize(next);
        if (!_fitCurrent(serial)) return;
        await windowManager.setSize(next);
        if (!_fitCurrent(serial)) return;
        await windowManager.setMinimumSize(next);
      } else {
        await windowManager.setMinimumSize(next);
        if (!_fitCurrent(serial)) return;
        await windowManager.setSize(next);
        if (!_fitCurrent(serial)) return;
        await windowManager.setMaximumSize(next);
      }
      if (!_fitCurrent(serial) || _size == next) return;
      _size = next;
      notifyListeners();
    } catch (error, stack) {
      debugPrint('Compact voice resize failed: $error\n$stack');
    }
  }

  bool _fitCurrent(int serial) => active && serial == _fitSerial;

  Future<void> exit() async {
    if (!active) return;
    active = false;
    notifyListeners();
    suppressWindowGeometryPersistence = false;
    await WindowCorners.setRounded(false);
    try {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setMinimumSize(const Size(200, 120));
      await windowManager.setMaximumSize(const Size(8192, 8192));
      if (_wasMaximized) {
        await windowManager.maximize();
      } else {
        final restore = _restore;
        if (restore != null) await windowManager.setBounds(restore);
      }
    } catch (error, stack) {
      debugPrint('Leaving compact voice mode failed: $error\n$stack');
    }
  }
}
