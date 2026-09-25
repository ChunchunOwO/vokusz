import 'dart:io';

import 'package:flutter/foundation.dart';

/// Downloads one avatar for the native overlay. Failures become an initial.
Future<Uint8List?> loadOverlayAvatar(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    return null;
  }
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri).timeout(const Duration(seconds: 8));
    final response = await request.close().timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      await response.drain<void>();
      return null;
    }
    final bytes = await consolidateHttpClientResponseBytes(response);
    if (bytes.length > 1500000) return null;
    return bytes;
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
