#include "window_corners.h"

#include <dwmapi.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

namespace {

constexpr char kChannelName[] = "com.vokusz.app/window_corners";
constexpr int kRadiusDip = 16;
// Same packing window_manager uses for the startup color 0xFF27292C.
constexpr int kSolidAccent = static_cast<int>(
    (255u << 24) | (0x2Cu << 16) | (0x29u << 8) | 0x27u);

#ifndef DWMWA_SYSTEMBACKDROP_TYPE
#define DWMWA_SYSTEMBACKDROP_TYPE 38
#endif

HWND g_hwnd = nullptr;
bool g_rounded = false;
int g_radius_dip = kRadiusDip;
bool g_applying = false;

struct AccentPolicy {
  int state;
  int flags;
  int color;
  int animation;
};

struct CompositionAttribute {
  int attribute;
  PVOID data;
  ULONG size;
};

HWND FlutterView(HWND hwnd) {
  HWND view = FindWindowExW(hwnd, nullptr, L"FLUTTERVIEW", nullptr);
  if (view != nullptr) return view;
  return GetWindow(hwnd, GW_CHILD);
}

void SetAccent(HWND hwnd, bool transparent) {
  const HMODULE user32 = GetModuleHandleW(L"user32.dll");
  if (user32 == nullptr) return;
  using SetAttribute = BOOL(WINAPI*)(HWND, CompositionAttribute*);
  auto set_attribute = reinterpret_cast<SetAttribute>(
      GetProcAddress(user32, "SetWindowCompositionAttribute"));
  if (set_attribute == nullptr) return;
  // Gradient accent paints an opaque rectangle over every corner. Disable it
  // while rounded so pixels the UI does not draw stay transparent.
  AccentPolicy policy = {
      transparent ? 0 : 1, 2, transparent ? 0 : kSolidAccent, 0};
  CompositionAttribute data = {19, &policy, sizeof(policy)};
  set_attribute(hwnd, &data);
}

void SetGlass(HWND hwnd, bool transparent) {
  MARGINS margins = {};
  if (transparent) {
    margins = {-1, -1, -1, -1};
  }
  DwmExtendFrameIntoClientArea(hwnd, &margins);
  // DWMSBT_NONE while rounded, otherwise the system backdrop fills the corner.
  INT backdrop = transparent ? 1 : 0;
  DwmSetWindowAttribute(hwnd, DWMWA_SYSTEMBACKDROP_TYPE, &backdrop,
                        sizeof(backdrop));
}

void SetRoundRegion(HWND hwnd, int width, int height, int radius) {
  if (hwnd == nullptr || width <= 0 || height <= 0) return;
  if (radius <= 0) {
    SetWindowRgn(hwnd, nullptr, TRUE);
    return;
  }
  HRGN region =
      CreateRoundRectRgn(0, 0, width + 1, height + 1, radius * 2, radius * 2);
  if (region == nullptr) return;
  if (SetWindowRgn(hwnd, region, TRUE) == 0) {
    DeleteObject(region);
  }
}

void Apply() {
  if (g_hwnd == nullptr || g_applying) return;
  g_applying = true;

  SetAccent(g_hwnd, g_rounded);
  SetGlass(g_hwnd, g_rounded);

  int radius = 0;
  if (g_rounded) {
    UINT dpi = GetDpiForWindow(g_hwnd);
    if (dpi == 0) dpi = 96;
    radius = MulDiv(g_radius_dip, static_cast<int>(dpi), 96);
  }

  RECT outer{};
  if (GetWindowRect(g_hwnd, &outer)) {
    SetRoundRegion(g_hwnd, outer.right - outer.left, outer.bottom - outer.top,
                   radius);
  }
  HWND view = FlutterView(g_hwnd);
  RECT client{};
  if (view != nullptr && GetClientRect(view, &client)) {
    SetRoundRegion(view, client.right - client.left, client.bottom - client.top,
                   radius);
  }

  g_applying = false;
}

bool ReadRounded(const flutter::EncodableMap& map) {
  const auto it = map.find(flutter::EncodableValue("rounded"));
  if (it == map.end()) return false;
  const auto* value = std::get_if<bool>(&it->second);
  return value != nullptr && *value;
}

}  // namespace

void WindowCornersRegister(flutter::FlutterEngine* engine, HWND window) {
  if (engine == nullptr || window == nullptr) return;
  g_hwnd = window;
  auto* registrar = new flutter::PluginRegistrarWindows(
      engine->GetRegistrarForPlugin("WindowCorners"));
  auto* channel = new flutter::MethodChannel<flutter::EncodableValue>(
      registrar->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() != "set") {
          result->NotImplemented();
          return;
        }
        g_rounded = false;
        g_radius_dip = kRadiusDip;
        if (const auto* args =
                std::get_if<flutter::EncodableMap>(call.arguments())) {
          g_rounded = ReadRounded(*args);
          const auto radius = args->find(flutter::EncodableValue("radius"));
          if (radius != args->end()) {
            if (const auto* value = std::get_if<int32_t>(&radius->second)) {
              if (*value > 0) g_radius_dip = *value;
            }
          }
        }
        Apply();
        result->Success();
      });
}

void WindowCornersOnSize() {
  if (g_rounded) Apply();
}
