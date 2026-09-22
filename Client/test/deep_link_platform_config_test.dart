import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String source(String path) => File(path).readAsStringSync();

void main() {
  test('mobile and Apple app bundles claim the vokusz custom scheme', () {
    final android = source('android/app/src/main/AndroidManifest.xml');
    expect(android, contains('<data android:scheme="vokusz" />'));

    for (final path in ['ios/Runner/Info.plist', 'macos/Runner/Info.plist']) {
      final plist = source(path);
      expect(plist, contains('<key>CFBundleURLSchemes</key>'), reason: path);
      expect(plist, contains('<string>vokusz</string>'), reason: path);
    }
  });

  test('Linux package passes the URL as the plugin command-line argument', () {
    final desktop = source('dist/vokusz.desktop');
    expect(desktop, contains('Exec=vokusz %u'));
    expect(desktop, contains('MimeType=x-scheme-handler/vokusz;'));
    expect(desktop, isNot(contains('--uri')));
  });

  test('Windows installer registers the direct URL command', () {
    final installer = source('dist/installer.iss');
    expect(installer, contains('Software\\Classes\\vokusz'));
    expect(installer, contains('""%1""'));
    expect(installer, isNot(contains('--uri')));
  });
}
