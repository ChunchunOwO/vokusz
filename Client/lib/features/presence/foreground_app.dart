import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The foreground program on this Windows desktop, if it is worth showing.
class ForegroundApp {
  const ForegroundApp({
    required this.path,
    required this.name,
    required this.fullscreen,
    this.icon,
  });

  final String path;
  final String name;
  final bool fullscreen;
  final Uint8List? icon;
}

class ForegroundApps {
  ForegroundApps._();

  static const _channel = MethodChannel('com.vokusz.app/foreground_app');

  static bool get _desktop =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  static Future<ForegroundApp?> current() async {
    if (!_desktop) return null;
    try {
      final raw = await _channel.invokeMethod<dynamic>('current');
      return _parse(raw);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Windows this client would recognize, frontmost first. No icons.
  static Future<List<ForegroundApp>> windows() async {
    if (!_desktop) return const [];
    try {
      final raw = await _channel.invokeMethod<dynamic>('windows');
      if (raw is! List) return const [];
      final apps = <ForegroundApp>[];
      for (final item in raw) {
        final app = _parse(item);
        if (app != null) apps.add(app);
      }
      return apps;
    } on MissingPluginException {
      return const [];
    } on PlatformException {
      return const [];
    }
  }

  /// The recognized window with [path], including its icon, if it is open.
  static Future<ForegroundApp?> watch(String path) async {
    if (!_desktop || path.isEmpty) return null;
    try {
      final raw = await _channel.invokeMethod<dynamic>('watch', {
        'path': path,
      });
      return _parse(raw);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static ForegroundApp? _parse(Object? raw) {
    if (raw is! Map) return null;
    final path = raw['path'] as String? ?? '';
    final name = (raw['name'] as String? ?? '').trim();
    if (path.isEmpty || name.isEmpty) return null;
    final icon = raw['icon'];
    return ForegroundApp(
      path: path,
      name: name,
      fullscreen: raw['fullscreen'] == true,
      icon: icon is Uint8List && icon.isNotEmpty ? icon : null,
    );
  }
}
