#include "foreground_app.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <dwmapi.h>
#include <objidl.h>
#include <shellapi.h>

#ifndef DWMWA_CLOAKED
#define DWMWA_CLOAKED 14
#endif

#include <algorithm>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

namespace Gdiplus {
using std::max;
using std::min;
}  // namespace Gdiplus
#include <gdiplus.h>

namespace {

constexpr char kChannel[] = "com.vokusz.app/foreground_app";
ULONG_PTR g_gdiplus = 0;

bool EnsureGdiplus() {
  if (g_gdiplus != 0) return true;
  Gdiplus::GdiplusStartupInput input;
  return Gdiplus::GdiplusStartup(&g_gdiplus, &input, nullptr) == Gdiplus::Ok;
}

std::string WideToUtf8(const std::wstring& text) {
  if (text.empty()) return {};
  const int size = WideCharToMultiByte(CP_UTF8, 0, text.data(),
                                       static_cast<int>(text.size()), nullptr,
                                       0, nullptr, nullptr);
  if (size <= 0) return {};
  std::string out(size, '\0');
  WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                      out.data(), size, nullptr, nullptr);
  return out;
}

std::wstring FileName(const std::wstring& path) {
  const auto slash = path.find_last_of(L"\\/");
  return slash == std::wstring::npos ? path : path.substr(slash + 1);
}

bool IgnoredProcess(const std::wstring& file) {
  static const wchar_t* kNames[] = {
      L"explorer.exe",
      L"searchhost.exe",
      L"searchapp.exe",
      L"shellexperiencehost.exe",
      L"startmenuexperiencehost.exe",
      L"textinputhost.exe",
      L"lockapp.exe",
      L"dwm.exe",
      L"vokusz.exe",
  };
  std::wstring lower = file;
  for (auto& ch : lower) {
    if (ch >= L'A' && ch <= L'Z') ch = static_cast<wchar_t>(ch - L'A' + L'a');
  }
  for (const auto* name : kNames) {
    if (lower == name) return true;
  }
  return false;
}

std::wstring VersionString(const std::wstring& path, const wchar_t* key) {
  DWORD handle = 0;
  const DWORD size = GetFileVersionInfoSizeW(path.c_str(), &handle);
  if (size == 0) return L"";
  std::vector<BYTE> data(size);
  if (!GetFileVersionInfoW(path.c_str(), 0, size, data.data())) return L"";
  struct Translation {
    WORD language;
    WORD code_page;
  };
  Translation* translation = nullptr;
  UINT bytes = 0;
  if (!VerQueryValueW(data.data(), L"\\VarFileInfo\\Translation",
                      reinterpret_cast<void**>(&translation), &bytes) ||
      translation == nullptr || bytes < sizeof(Translation)) {
    return L"";
  }
  wchar_t query[80];
  swprintf_s(query, L"\\StringFileInfo\\%04x%04x\\%s", translation->language,
             translation->code_page, key);
  wchar_t* value = nullptr;
  UINT length = 0;
  if (!VerQueryValueW(data.data(), query, reinterpret_cast<void**>(&value),
                      &length) ||
      value == nullptr || length == 0) {
    return L"";
  }
  return std::wstring(value);
}

std::wstring FriendlyName(const std::wstring& path) {
  const std::wstring description = VersionString(path, L"FileDescription");
  if (!description.empty()) return description;
  const std::wstring product = VersionString(path, L"ProductName");
  if (!product.empty()) return product;
  std::wstring file = FileName(path);
  const auto dot = file.rfind(L'.');
  if (dot != std::wstring::npos) file.resize(dot);
  return file;
}

bool CoversMonitor(HWND hwnd) {
  RECT window{};
  if (IsIconic(hwnd)) {
    WINDOWPLACEMENT place{};
    place.length = sizeof(place);
    if (!GetWindowPlacement(hwnd, &place)) return false;
    window = place.rcNormalPosition;
  } else if (!GetWindowRect(hwnd, &window)) {
    return false;
  }
  HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
  MONITORINFO info{};
  info.cbSize = sizeof(info);
  if (!GetMonitorInfoW(monitor, &info)) return false;
  const RECT& screen = info.rcMonitor;
  return window.left <= screen.left + 8 && window.top <= screen.top + 8 &&
         window.right >= screen.right - 8 && window.bottom >= screen.bottom - 8;
}

int EncoderClsid(const WCHAR* mime, CLSID* clsid) {
  UINT count = 0;
  UINT bytes = 0;
  if (Gdiplus::GetImageEncodersSize(&count, &bytes) != Gdiplus::Ok ||
      bytes == 0) {
    return -1;
  }
  std::vector<BYTE> buffer(bytes);
  auto* codecs = reinterpret_cast<Gdiplus::ImageCodecInfo*>(buffer.data());
  if (Gdiplus::GetImageEncoders(count, bytes, codecs) != Gdiplus::Ok) return -1;
  for (UINT i = 0; i < count; ++i) {
    if (wcscmp(codecs[i].MimeType, mime) == 0) {
      *clsid = codecs[i].Clsid;
      return static_cast<int>(i);
    }
  }
  return -1;
}

std::vector<uint8_t> IconPng(const std::wstring& path) {
  if (!EnsureGdiplus()) return {};
  SHFILEINFOW info{};
  if (SHGetFileInfoW(path.c_str(), 0, &info, sizeof(info),
                     SHGFI_ICON | SHGFI_LARGEICON) == 0 ||
      info.hIcon == nullptr) {
    return {};
  }
  Gdiplus::Bitmap bitmap(32, 32, PixelFormat32bppARGB);
  Gdiplus::Graphics graphics(&bitmap);
  graphics.Clear(Gdiplus::Color(0, 0, 0, 0));
  const HDC dc = graphics.GetHDC();
  DrawIconEx(dc, 0, 0, info.hIcon, 32, 32, 0, nullptr, DI_NORMAL);
  graphics.ReleaseHDC(dc);
  DestroyIcon(info.hIcon);

  CLSID png{};
  if (EncoderClsid(L"image/png", &png) < 0) return {};
  IStream* stream = nullptr;
  if (CreateStreamOnHGlobal(nullptr, TRUE, &stream) != S_OK || stream == nullptr) {
    return {};
  }
  if (bitmap.Save(stream, &png, nullptr) != Gdiplus::Ok) {
    stream->Release();
    return {};
  }
  HGLOBAL memory = nullptr;
  if (GetHGlobalFromStream(stream, &memory) != S_OK || memory == nullptr) {
    stream->Release();
    return {};
  }
  const auto size = static_cast<size_t>(GlobalSize(memory));
  void* locked = GlobalLock(memory);
  std::vector<uint8_t> bytes;
  if (locked != nullptr && size > 0 && size < 24000) {
    const auto* src = static_cast<const uint8_t*>(locked);
    bytes.assign(src, src + size);
    GlobalUnlock(memory);
  } else if (locked != nullptr) {
    GlobalUnlock(memory);
  }
  stream->Release();
  return bytes;
}

bool Cloaked(HWND hwnd) {
  DWORD cloaked = 0;
  if (DwmGetWindowAttribute(hwnd, DWMWA_CLOAKED, &cloaked, sizeof(cloaked)) !=
      S_OK) {
    return false;
  }
  return cloaked != 0;
}

// [walking] is the pass behind Vokusz. The window the user actually focused is
// kept even when it is small; windows merely sitting behind this client are
// skipped when they are minimized, tool windows, or tiny overlays.
bool SkipWindow(HWND hwnd, bool walking) {
  if (hwnd == nullptr || !IsWindowVisible(hwnd) || Cloaked(hwnd)) return true;
  if (!walking) return false;
  const auto style = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
  if ((style & WS_EX_TOOLWINDOW) != 0) return true;
  // A fullscreen game minimizes when Vokusz is focused. Its window rect
  // collapses, but it is still the program they were in.
  if (IsIconic(hwnd)) return false;
  RECT rect{};
  if (!GetWindowRect(hwnd, &rect)) return true;
  return rect.right - rect.left < 120 || rect.bottom - rect.top < 80;
}

bool FrameHost(const std::wstring& file) {
  std::wstring lower = file;
  for (auto& ch : lower) {
    if (ch >= L'A' && ch <= L'Z') ch = static_cast<wchar_t>(ch - L'A' + L'a');
  }
  return lower == L"applicationframehost.exe";
}

std::wstring WindowTitle(HWND hwnd) {
  const int length = GetWindowTextLengthW(hwnd);
  if (length <= 0) return L"";
  std::wstring text(static_cast<size_t>(length) + 1, L'\0');
  const int written = GetWindowTextW(hwnd, text.data(), length + 1);
  if (written <= 0) return L"";
  text.resize(static_cast<size_t>(written));
  return text;
}

bool Describe(HWND hwnd, flutter::EncodableMap* out, bool include_icon) {
  DWORD process_id = 0;
  GetWindowThreadProcessId(hwnd, &process_id);
  if (process_id == 0 || process_id == GetCurrentProcessId()) return false;
  HANDLE process =
      OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, process_id);
  if (process == nullptr) return false;
  wchar_t path[MAX_PATH];
  DWORD path_size = MAX_PATH;
  const BOOL ok = QueryFullProcessImageNameW(process, 0, path, &path_size);
  CloseHandle(process);
  if (!ok || path_size == 0) return false;
  const std::wstring full(path, path_size);
  const std::wstring file = FileName(full);
  const bool frame = FrameHost(file);
  if (IgnoredProcess(file) && !frame) return false;
  const std::wstring name = frame ? WindowTitle(hwnd) : FriendlyName(full);
  if (name.empty()) return false;
  // Store apps share one host process. The window title keeps them apart.
  const std::wstring identity = frame ? full + L"|" + name : full;

  (*out)[flutter::EncodableValue("path")] =
      flutter::EncodableValue(WideToUtf8(identity));
  (*out)[flutter::EncodableValue("name")] =
      flutter::EncodableValue(WideToUtf8(name));
  (*out)[flutter::EncodableValue("fullscreen")] =
      flutter::EncodableValue(CoversMonitor(hwnd));
  if (include_icon) {
    const std::vector<uint8_t> icon = IconPng(full);
    if (!icon.empty()) {
      (*out)[flutter::EncodableValue("icon")] = flutter::EncodableValue(icon);
    }
  }
  return true;
}

std::string MapPath(const flutter::EncodableMap& map) {
  const auto it = map.find(flutter::EncodableValue("path"));
  if (it == map.end()) return {};
  const auto* path = std::get_if<std::string>(&it->second);
  return path == nullptr ? std::string() : *path;
}

struct WindowCollect {
  flutter::EncodableList windows;
  std::vector<std::string> seen;
  std::string watch;
  flutter::EncodableMap match;
  bool matched = false;
  int limit = 24;
};

BOOL CALLBACK CollectWindow(HWND hwnd, LPARAM param) {
  auto* collect = reinterpret_cast<WindowCollect*>(param);
  if (SkipWindow(hwnd, true)) return TRUE;
  flutter::EncodableMap map;
  if (!Describe(hwnd, &map, false)) return TRUE;
  const std::string path = MapPath(map);
  if (path.empty()) return TRUE;
  for (const auto& seen : collect->seen) {
    if (seen == path) return TRUE;
  }
  collect->seen.push_back(path);
  if (!collect->watch.empty()) {
    if (path != collect->watch) return TRUE;
    map.clear();
    if (Describe(hwnd, &map, true)) {
      collect->match = map;
      collect->matched = true;
    }
    return FALSE;
  }
  collect->windows.push_back(flutter::EncodableValue(map));
  return static_cast<int>(collect->windows.size()) < collect->limit;
}

flutter::EncodableList ListApps() {
  WindowCollect collect;
  EnumWindows(CollectWindow, reinterpret_cast<LPARAM>(&collect));
  return collect.windows;
}

flutter::EncodableMap WatchApp(const std::string& path) {
  if (path.empty()) return {};
  WindowCollect collect;
  collect.watch = path;
  EnumWindows(CollectWindow, reinterpret_cast<LPARAM>(&collect));
  return collect.matched ? collect.match : flutter::EncodableMap();
}

HWND g_last = nullptr;

flutter::EncodableMap Remember(HWND hwnd, flutter::EncodableMap map) {
  g_last = hwnd;
  return map;
}

// The last real window, even if it is now cloaked or minimized. Cleared once
// that window is gone.
flutter::EncodableMap Kept() {
  if (g_last != nullptr && IsWindow(g_last)) {
    flutter::EncodableMap kept;
    if (Describe(g_last, &kept, true)) return kept;
  }
  g_last = nullptr;
  return {};
}

flutter::EncodableMap CurrentApp() {
  const HWND foreground = GetForegroundWindow();
  if (foreground == nullptr) return Kept();

  if (!SkipWindow(foreground, false)) {
    flutter::EncodableMap direct;
    if (Describe(foreground, &direct, true)) return Remember(foreground, direct);
  }

  // Vokusz, the desktop, and the shell are not the activity. The next real
  // window is. If nothing visible qualifies, keep the last one while it exists.
  HWND root = GetAncestor(foreground, GA_ROOT);
  if (root == nullptr) root = foreground;
  HWND hwnd = root;
  for (int i = 0; i < 40; ++i) {
    hwnd = GetWindow(hwnd, GW_HWNDNEXT);
    if (hwnd == nullptr) break;
    if (SkipWindow(hwnd, true)) continue;
    flutter::EncodableMap behind;
    if (Describe(hwnd, &behind, true)) return Remember(hwnd, behind);
  }
  return Kept();
}

}  // namespace

void ForegroundAppRegister(flutter::FlutterEngine* engine) {
  if (engine == nullptr) return;
  auto* registrar = new flutter::PluginRegistrarWindows(
      engine->GetRegistrarForPlugin("ForegroundApp"));
  auto* channel = new flutter::MethodChannel<flutter::EncodableValue>(
      registrar->messenger(), kChannel,
      &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() == "current") {
          result->Success(flutter::EncodableValue(CurrentApp()));
          return;
        }
        if (call.method_name() == "windows") {
          result->Success(flutter::EncodableValue(ListApps()));
          return;
        }
        if (call.method_name() == "watch") {
          std::string path;
          if (const auto* args =
                  std::get_if<flutter::EncodableMap>(call.arguments())) {
            const auto it = args->find(flutter::EncodableValue("path"));
            if (it != args->end()) {
              if (const auto* value = std::get_if<std::string>(&it->second)) {
                path = *value;
              }
            }
          }
          const flutter::EncodableMap found = WatchApp(path);
          if (found.empty()) {
            result->Success();
          } else {
            result->Success(flutter::EncodableValue(found));
          }
          return;
        }
        result->NotImplemented();
      });
}
