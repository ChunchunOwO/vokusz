/// Web implementation of the service-worker update bridge. Reads the flags set
/// by `web/index.html`: `vokuszUpdateAvailable` flips to true once a new
/// service worker has installed in the background, and `vokuszApplyUpdate()`
/// activates it and reloads.
library;

import 'dart:js_interop';

@JS('vokuszUpdateAvailable')
external JSBoolean? get _available;

@JS('vokuszApplyUpdate')
external JSFunction? get _apply;

bool webUpdateAvailable() => _available?.toDart ?? false;

void applyWebUpdate() => _apply?.callAsFunction();
