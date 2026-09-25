#ifndef RUNNER_WINDOW_CORNERS_H_
#define RUNNER_WINDOW_CORNERS_H_

#include <flutter/flutter_engine.h>
#include <windows.h>

// Slight corner radius for compact voice mode. `com.vokusz.app/window_corners`
// method `set` takes `{rounded: bool}`. A size change reapplies the region.
void WindowCornersRegister(flutter::FlutterEngine* engine, HWND window);
void WindowCornersOnSize();

#endif  // RUNNER_WINDOW_CORNERS_H_
