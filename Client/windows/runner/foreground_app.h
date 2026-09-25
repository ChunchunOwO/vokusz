#ifndef RUNNER_FOREGROUND_APP_H_
#define RUNNER_FOREGROUND_APP_H_

#include <flutter/flutter_engine.h>

// Reports the foreground program (name, path, fullscreen, 32px PNG icon) on
// com.vokusz.app/foreground_app. Vokusz itself and the Windows shell are omitted.
// When Vokusz is the foreground window, the real window behind it is reported.
void ForegroundAppRegister(flutter::FlutterEngine* engine);

#endif  // RUNNER_FOREGROUND_APP_H_
