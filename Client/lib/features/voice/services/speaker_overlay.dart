import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One person drawn by the Windows speaker overlay.
typedef SpeakerOverlayUser = ({
  String id,
  String name,
  bool speaking,
  Uint8List? avatar,
});

/// Talks to the Windows always-on-top speaker window. No-op off Windows.
class SpeakerOverlay {
  SpeakerOverlay._();

  static const _channel = MethodChannel('com.vokusz.app/speaker_overlay');
  static bool _listening = false;
  static void Function(Rect frame)? onFrame;

  static Future<void> ensureListening() async {
    if (_listening || kIsWeb || defaultTargetPlatform != TargetPlatform.windows) {
      return;
    }
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'frame') return;
      final args = call.arguments;
      if (args is! Map) return;
      final x = (args['x'] as num?)?.toDouble();
      final y = (args['y'] as num?)?.toDouble();
      final width = (args['width'] as num?)?.toDouble();
      final height = (args['height'] as num?)?.toDouble();
      if (x == null || y == null || width == null || height == null) return;
      onFrame?.call(Rect.fromLTWH(x, y, width, height));
    });
  }

  /// Returns whether the native window accepted the update. Avatar bytes are
  /// cached over there, so a failed call should be sent again.
  static Future<bool> update({
    required bool visible,
    required bool editing,
    required bool applyFrame,
    required Rect frame,
    required String empty,
    required String hint,
    required List<SpeakerOverlayUser> users,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return false;
    await ensureListening();
    try {
      await _channel.invokeMethod<void>('update', {
        'visible': visible,
        'editing': editing,
        'applyFrame': applyFrame,
        'x': frame.left.round(),
        'y': frame.top.round(),
        'width': frame.width.round(),
        'height': frame.height.round(),
        'empty': empty,
        'hint': hint,
        'users': [
          for (final user in users)
            {
              'id': user.id,
              'name': user.name,
              'speaking': user.speaking,
              if (user.avatar != null) 'avatar': user.avatar,
            },
        ],
      });
      return true;
    } on MissingPluginException {
      // The desktop runner is the only host that draws the overlay.
      return false;
    } on PlatformException {
      return false;
    }
  }
}
