import 'dart:typed_data';

/// Web and other hosts have no native overlay, so avatars are not fetched.
Future<Uint8List?> loadOverlayAvatar(String url) async => null;
