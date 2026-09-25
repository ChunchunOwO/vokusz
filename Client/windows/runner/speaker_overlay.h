#ifndef RUNNER_SPEAKER_OVERLAY_H_
#define RUNNER_SPEAKER_OVERLAY_H_

#include <flutter/flutter_engine.h>
#include <windows.h>

// Always-on-top speaker list. Dart pushes the people to draw and whether the
// window can be dragged; the window reports its frame after a move or resize.
void SpeakerOverlayRegister(flutter::FlutterEngine* engine);

void SpeakerOverlayDestroy();

#endif  // RUNNER_SPEAKER_OVERLAY_H_
