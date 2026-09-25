import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Builds `multipart/form-data` request bodies for file uploads and mixed
/// payloads. Add parts with [addField]/[addJson]/[addFile], then send a
/// streaming [request]. [build] is available when a buffered body is needed.
class MultipartForm {
  final String _boundary;
  final List<Uint8List> _parts = [];

  MultipartForm({String? boundary})
      : _boundary = boundary ?? '----AccordForm${Random().nextInt(1 << 31)}';

  static const List<int> _crlf = [13, 10]; // "\r\n"

  /// Adds a plain text field.
  void addField(String name, String value) {
    final header =
        '--$_boundary\r\nContent-Disposition: form-data; name="$name"\r\n\r\n';
    final part = BytesBuilder()
      ..add(utf8.encode(header))
      ..add(utf8.encode(value))
      ..add(_crlf);
    _parts.add(part.toBytes());
  }

  /// Adds a JSON field. [data] is encoded with [jsonEncode].
  void addJson(String name, Object? data) {
    final jsonStr = jsonEncode(data);
    final header = '--$_boundary\r\nContent-Disposition: form-data; '
        'name="$name"\r\nContent-Type: application/json\r\n\r\n';
    final part = BytesBuilder()
      ..add(utf8.encode(header))
      ..add(utf8.encode(jsonStr))
      ..add(_crlf);
    _parts.add(part.toBytes());
  }

  /// Adds a binary file part.
  void addFile(
    String name,
    String filename,
    List<int> content, {
    String contentType = 'application/octet-stream',
  }) {
    if (filename.contains('\r') || filename.contains('\n')) {
      throw ArgumentError.value(
        filename,
        'filename',
        'must not contain carriage returns or line feeds',
      );
    }

    final fallbackFilename = _asciiFilenameFallback(filename);
    final encodedFilename = _encodeRfc5987(filename);
    final header = '--$_boundary\r\nContent-Disposition: form-data; '
        'name="$name"; filename="$fallbackFilename"; '
        "filename*=UTF-8''$encodedFilename\r\n"
        'Content-Type: $contentType\r\n\r\n';
    // Keep the file buffer intact instead of copying a potentially 1 GiB file.
    _parts.addAll([
      utf8.encode(header),
      content is Uint8List ? content : Uint8List.fromList(content),
      Uint8List.fromList(_crlf),
    ]);
  }

  /// Produces a safe quoted-string fallback for clients without `filename*`.
  ///
  /// The RFC 5987 value carries the exact filename. The fallback remains ASCII
  /// and replaces control/non-ASCII characters rather than putting them raw in
  /// a MIME header.
  static String _asciiFilenameFallback(String filename) {
    final result = StringBuffer();
    for (final rune in filename.runes) {
      if (rune == 0x22 || rune == 0x5c) {
        result
          ..writeCharCode(0x5c)
          ..writeCharCode(rune);
      } else if (rune >= 0x20 && rune <= 0x7e) {
        result.writeCharCode(rune);
      } else {
        result.write('_');
      }
    }
    return result.toString();
  }

  /// Encodes a UTF-8 value using RFC 5987's `attr-char` allowlist.
  static String _encodeRfc5987(String value) {
    const attrChars = r'!#$&+-.^_`|~';
    final result = StringBuffer();
    for (final byte in utf8.encode(value)) {
      final isAlphaNumeric = (byte >= 0x30 && byte <= 0x39) ||
          (byte >= 0x41 && byte <= 0x5a) ||
          (byte >= 0x61 && byte <= 0x7a);
      if (isAlphaNumeric || attrChars.contains(String.fromCharCode(byte))) {
        result.writeCharCode(byte);
      } else {
        result
          ..write('%')
          ..write(byte.toRadixString(16).toUpperCase().padLeft(2, '0'));
      }
    }
    return result.toString();
  }

  /// The `Content-Type` header value, including the boundary.
  String contentType() => 'multipart/form-data; boundary=$_boundary';

  /// Sends the existing buffers without assembling another full-size body.
  http.BaseRequest request(String method, Uri uri) => _MultipartRequest(
        method,
        uri,
        [..._parts, utf8.encode('--$_boundary--\r\n')],
      )..headers['Content-Type'] = contentType();

  /// Assembles all parts plus the closing boundary into the final body.
  Uint8List build() {
    final result = BytesBuilder();
    for (final part in _parts) {
      result.add(part);
    }
    result.add(utf8.encode('--$_boundary--\r\n'));
    return result.toBytes();
  }
}

class _MultipartRequest extends http.BaseRequest {
  _MultipartRequest(super.method, super.url, this.parts) {
    contentLength = parts.fold<int>(0, (size, part) => size + part.length);
  }

  final List<Uint8List> parts;

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(Stream.fromIterable(parts));
  }
}
