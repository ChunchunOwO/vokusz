import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Slightly rounds the Windows window while compact voice mode is open.
class WindowCorners {
  WindowCorners._();

  static const _channel = MethodChannel('com.vokusz.app/window_corners');

  static Future<void> setRounded(bool rounded, {int radius = 16}) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('set', {
        'rounded': rounded,
        'radius': radius,
      });
    } on MissingPluginException {
      // The desktop runner is the only host that can shape the window.
    } on PlatformException {
      // Ignore a runner that predates the channel.
    }
  }
}
