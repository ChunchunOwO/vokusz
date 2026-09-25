import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

/// Encodes the selected crop as PNG, preserving alpha and its full framing.
/// Bounds large uploads without upscaling small sources. The crop package may
/// preserve the source JPEG/BMP encoding, even when the caller names it .png.
Future<Uint8List> prepareCroppedImage(
  Uint8List bytes, {
  int? maxDimension,
}) async {
  assert(maxDimension == null || maxDimension > 0);
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  // This API obtains dimensions on both web and native; encoded
  // ImageDescriptor.width/height throw UnsupportedError on Flutter web.
  final codec = await ui.instantiateImageCodecWithSize(
    buffer,
    getTargetSize: (width, height) {
      final scale = maxDimension == null
          ? 1.0
          : math.min(1.0, maxDimension / math.max(width, height));
      return ui.TargetImageSize(
        width: math.max(1, (width * scale).round()),
        height: math.max(1, (height * scale).round()),
      );
    },
  );
  try {
    final frame = await codec.getNextFrame();
    try {
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not encode cropped image');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

/// JPEG used for profile banners.
///
/// Flutter's PNG encoder keeps a 1024×576 crop near its raw size. Base64 then
/// pushes the profile save past the server's JSON body limit, so the banner
/// never lands and the profile card has nothing to draw. JPEG stays small
/// enough to save. Falls back to [pngBytes] when they are not an image.
Uint8List encodeBannerJpeg(Uint8List pngBytes, {int quality = 80}) {
  final decoded = img.decodeImage(pngBytes);
  if (decoded == null) return pngBytes;
  return Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
}

/// Whether [bytes] is a JPEG file, so the upload MIME matches the payload.
bool looksLikeJpeg(Uint8List bytes) =>
    bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
