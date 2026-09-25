import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Windows virtual-key poll used by push-to-talk and the speaker overlay.
///
/// `GetAsyncKeyState` reads the keyboard even when Vokusz is not the focused
/// window, which is what a voice hotkey has to do.
class DesktopKeys {
  DesktopKeys._();

  /// True while a settings row is waiting for a new binding, so the live
  /// hotkeys do not fire on the key the user is choosing.
  static bool capturing = false;

  static final int Function(int vk)? _getAsyncKeyState = _bind();

  static int Function(int vk)? _bind() {
    if (kIsWeb || !Platform.isWindows) return null;
    try {
      final user32 = DynamicLibrary.open('user32.dll');
      return user32.lookupFunction<Int16 Function(Int32), int Function(int)>(
        'GetAsyncKeyState',
      );
    } catch (_) {
      return null;
    }
  }

  static bool get available => _getAsyncKeyState != null;

  static bool isDown(int virtualKey) {
    final poll = _getAsyncKeyState;
    if (poll == null || virtualKey <= 0) return false;
    return (poll(virtualKey) & 0x8000) != 0;
  }

  /// The first virtual key currently held, skipping [ignore] (mouse buttons
  /// that are still down from clicking the bind control).
  static int? heldKey({Set<int> ignore = const {}}) {
    final poll = _getAsyncKeyState;
    if (poll == null) return null;
    for (var vk = 1; vk <= 254; vk++) {
      if (ignore.contains(vk)) continue;
      if ((poll(vk) & 0x8000) != 0) return vk;
    }
    return null;
  }
}
