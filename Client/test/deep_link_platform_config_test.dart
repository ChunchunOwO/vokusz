import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String source(String path) => File(path).readAsStringSync();

void main() {
  test('Windows installer registers the direct URL command', () {
    final installer = source('dist/installer.iss');
    expect(installer, contains('Software\\Classes\\vokusz'));
    expect(installer, contains('""%1""'));
    expect(installer, isNot(contains('--uri')));
  });
}
