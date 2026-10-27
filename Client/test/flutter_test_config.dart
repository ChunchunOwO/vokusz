import 'dart:async';

import 'package:bonfire/shared/app_info.dart';

/// The in-app updater is switched off in shipped builds via
/// [kSelfUpdateDisabled]; keep exercising it in tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  debugSelfUpdateDisabled = false;
  await testMain();
}
