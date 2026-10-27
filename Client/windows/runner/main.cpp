#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <shellapi.h>
#include <windows.h>

#include <string>

#include "flutter_window.h"
#include "utils.h"

namespace {

// Same id app_links listens for on WM_COPYDATA.
constexpr ULONG_PTR kAppLinkMessageId = WM_USER + 2;

// A vokusz:// invite starts a second process. Its window is created blank and
// stays white while startup waits on files the first process already holds.
// Hand the link to the running window and exit before any window exists.
bool ForwardLinkToRunningInstance() {
  HWND hwnd = nullptr;
  while ((hwnd = ::FindWindowEx(nullptr, hwnd, L"FLUTTER_RUNNER_WIN32_WINDOW",
                                 nullptr)) != nullptr) {
    DWORD window_pid = 0;
    ::GetWindowThreadProcessId(hwnd, &window_pid);
    if (window_pid != 0 && window_pid != ::GetCurrentProcessId()) break;
  }
  if (hwnd == nullptr) return false;

  int argc = 0;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv != nullptr && argc >= 2) {
    const std::wstring wide(argv[1]);
    ::LocalFree(argv);
    const int bytes = ::WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1,
                                             nullptr, 0, nullptr, nullptr);
    if (bytes > 1) {
      std::string link(static_cast<size_t>(bytes), '\0');
      ::WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, link.data(), bytes,
                            nullptr, nullptr);
      COPYDATASTRUCT copy{};
      copy.dwData = kAppLinkMessageId;
      copy.cbData = static_cast<DWORD>(bytes);
      copy.lpData = link.data();
      ::SendMessage(hwnd, WM_COPYDATA, reinterpret_cast<WPARAM>(hwnd),
                    reinterpret_cast<LPARAM>(&copy));
    }
  } else if (argv != nullptr) {
    ::LocalFree(argv);
  }

  ::ShowWindow(hwnd, SW_RESTORE);
  ::SetForegroundWindow(hwnd);
  return true;
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command)
{
  if (ForwardLinkToRunningInstance()) {
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent())
  {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Vokusz", origin, size))
  {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0))
  {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
