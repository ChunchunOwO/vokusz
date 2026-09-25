#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "foreground_app.h"
#include "speaker_overlay.h"
#include "taskbar_badge.h"
#include "window_corners.h"

extern "C" __declspec(dllimport) void VokuszStopObsCapture();

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  // Unread taskbar overlay icon (see taskbar_badge.cpp) — registered here
  // because it needs both the engine and this window's HWND.
  TaskbarBadgeRegister(flutter_controller_->engine(), GetHandle());
  WindowCornersRegister(flutter_controller_->engine(), GetHandle());
  SpeakerOverlayRegister(flutter_controller_->engine());
  ForegroundAppRegister(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  SpeakerOverlayDestroy();
  VokuszStopObsCapture();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  // The shell drops overlay icons when it (re)creates the taskbar button — at
  // first show, and after an explorer.exe restart — so re-push the last badge.
  const UINT taskbar_button_created = TaskbarBadgeButtonCreatedMessage();
  if (taskbar_button_created != 0 && message == taskbar_button_created) {
    TaskbarBadgeReapply();
  }

  if (message == WM_FONTCHANGE) {
    flutter_controller_->engine()->ReloadSystemFonts();
  }

  // Size the Flutter view first. The rounded region is applied after that,
  // otherwise the view keeps the previous square until the next resize.
  const LRESULT result =
      Win32Window::MessageHandler(hwnd, message, wparam, lparam);
  if (message == WM_SIZE || message == WM_DPICHANGED) {
    WindowCornersOnSize();
  }
  return result;
}
