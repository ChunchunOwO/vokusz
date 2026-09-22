import 'dart:io';

import 'package:bonfire/shared/app_info.dart';
import 'package:bonfire/shared/package_manager_install_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('package wrappers opt out without changing a direct download', () {
    final directory = Directory.systemTemp.createTempSync('package-manager');
    addTearDown(() => directory.deleteSync(recursive: true));
    final executable = '${directory.path}/vokusz';
    expect(
      detectPackageManagerInstall(environment: {}, executable: executable),
      isFalse,
    );
    for (final manager in [
      'winget',
      'scoop',
      'chocolatey',
      'homebrew',
      'flatpak',
    ]) {
      expect(
        detectPackageManagerInstall(
          environment: {'VOKUSZ_PACKAGE_MANAGER': manager},
          executable: executable,
        ),
        isTrue,
      );
    }
    expect(
      detectPackageManagerInstall(
        environment: {'FLATPAK_ID': 'io.github.ChunchunOwO.vokusz'},
        executable: executable,
      ),
      isTrue,
    );
    expect(
      detectPackageManagerInstall(
        environment: {
          'VOKUSZ_PACKAGE_MANAGER': '',
          'FLATPAK_ID': 'unrelated.app',
        },
        executable: executable,
      ),
      isFalse,
    );
  });

  test('only the marker beside this executable opts an installation out', () {
    final directory = Directory.systemTemp.createTempSync('package-manager');
    addTearDown(() => directory.deleteSync(recursive: true));
    final managed = Directory('${directory.path}/managed')..createSync();
    final portable = Directory('${directory.path}/portable')..createSync();
    File('${managed.path}/vokusz.package-manager').writeAsStringSync('scoop');
    expect(
      detectPackageManagerInstall(
        environment: {},
        executable: '${managed.path}/vokusz.exe',
      ),
      isTrue,
    );
    expect(
      detectPackageManagerInstall(
        environment: {},
        executable: '${portable.path}/vokusz.exe',
      ),
      isFalse,
    );
  });

  test('package management leaves desktop developer capability unchanged', () {
    addTearDown(() {
      debugPackageManagerBuild = null;
      debugAppStoreBuild = null;
    });
    debugAppStoreBuild = false;
    debugPackageManagerBuild = false;
    final developerAvailable = isDeveloperModeAvailable;
    expect(isSelfUpdateEnabled, isTrue);
    debugPackageManagerBuild = true;
    expect(isSelfUpdateEnabled, isFalse);
    expect(isAppStoreBuild, isFalse);
    expect(isDeveloperModeAvailable, developerAvailable);
  });
}
