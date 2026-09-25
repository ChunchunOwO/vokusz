#include "speaker_overlay.h"

#include <objidl.h>
#include <windowsx.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cstring>
#include <map>
#include <memory>
#include <string>
#include <vector>

// gdiplus.h needs min/max; the runner builds with NOMINMAX.
namespace Gdiplus {
using std::max;
using std::min;
}  // namespace Gdiplus
#include <gdiplus.h>
#ifndef PixelFormat32bppPARGB
using Gdiplus::PixelFormat32bppPARGB;
#endif
#ifndef PixelFormat32bppARGB
using Gdiplus::PixelFormat32bppARGB;
#endif

namespace {

constexpr char kChannelName[] = "com.vokusz.app/speaker_overlay";
constexpr wchar_t kClassName[] = L"VokuszSpeakerOverlay";
constexpr int kPad = 12;
constexpr int kAvatar = 40;
constexpr int kGap = 8;
constexpr int kRowGap = 8;
constexpr int kNameW = 132;
constexpr int kRing = 3;
constexpr int kSpeakingR = 77;
constexpr int kSpeakingG = 163;
constexpr int kSpeakingB = 255;

int AtLeast(int value, int floor) { return value < floor ? floor : value; }

struct Person {
  std::wstring id;
  std::wstring name;
  bool speaking = false;
};

struct Layout {
  int columns = 1;
  int chips = 0;
  int extra = 0;
  int width = 0;
  int height = 0;
};

flutter::PluginRegistrarWindows* g_registrar = nullptr;
flutter::MethodChannel<flutter::EncodableValue>* g_channel = nullptr;
HWND g_hwnd = nullptr;
bool g_class_ready = false;
bool g_visible = false;
bool g_editing = false;
bool g_apply_frame = false;
bool g_dragging = false;
bool g_user_moved = false;
bool g_have_origin = false;
int g_x = 0;
int g_y = 0;
int g_origin_x = 0;
int g_origin_y = 0;
ULONG_PTR g_gdiplus = 0;
std::wstring g_empty;
std::wstring g_hint;
std::vector<Person> g_people;
std::map<std::wstring, std::unique_ptr<Gdiplus::Bitmap>> g_avatars;

bool EnsureGdiplus() {
  if (g_gdiplus != 0) return true;
  Gdiplus::GdiplusStartupInput input;
  return Gdiplus::GdiplusStartup(&g_gdiplus, &input, nullptr) == Gdiplus::Ok;
}

void ShutdownGdiplus() {
  g_avatars.clear();
  if (g_gdiplus == 0) return;
  Gdiplus::GdiplusShutdown(g_gdiplus);
  g_gdiplus = 0;
}

std::wstring Utf8ToWide(const std::string& text) {
  if (text.empty()) return L"";
  const int size = MultiByteToWideChar(
      CP_UTF8, 0, text.data(), static_cast<int>(text.size()), nullptr, 0);
  if (size <= 0) return L"";
  std::wstring wide(size, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                      wide.data(), size);
  return wide;
}

int ReadInt(const flutter::EncodableMap& map, const char* key, int fallback) {
  const auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) return fallback;
  if (const auto* value = std::get_if<int32_t>(&it->second)) return *value;
  if (const auto* value = std::get_if<int64_t>(&it->second)) {
    return static_cast<int>(*value);
  }
  if (const auto* value = std::get_if<double>(&it->second)) {
    return static_cast<int>(*value);
  }
  return fallback;
}

bool ReadBool(const flutter::EncodableMap& map, const char* key) {
  const auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) return false;
  const auto* value = std::get_if<bool>(&it->second);
  return value != nullptr && *value;
}

std::wstring ReadString(const flutter::EncodableMap& map, const char* key) {
  const auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) return L"";
  const auto* value = std::get_if<std::string>(&it->second);
  return value == nullptr ? L"" : Utf8ToWide(*value);
}

const std::vector<uint8_t>* ReadBytes(const flutter::EncodableMap& map,
                                      const char* key) {
  const auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) return nullptr;
  return std::get_if<std::vector<uint8_t>>(&it->second);
}

std::unique_ptr<Gdiplus::Bitmap> DecodeAvatar(const std::vector<uint8_t>& bytes) {
  if (bytes.empty() || !EnsureGdiplus()) return nullptr;
  HGLOBAL memory = GlobalAlloc(GMEM_MOVEABLE, bytes.size());
  if (memory == nullptr) return nullptr;
  void* locked = GlobalLock(memory);
  if (locked == nullptr) {
    GlobalFree(memory);
    return nullptr;
  }
  memcpy(locked, bytes.data(), bytes.size());
  GlobalUnlock(memory);
  IStream* stream = nullptr;
  if (CreateStreamOnHGlobal(memory, TRUE, &stream) != S_OK || stream == nullptr) {
    GlobalFree(memory);
    return nullptr;
  }
  auto streamed =
      std::unique_ptr<Gdiplus::Bitmap>(Gdiplus::Bitmap::FromStream(stream));
  std::unique_ptr<Gdiplus::Bitmap> copy;
  if (streamed && streamed->GetLastStatus() == Gdiplus::Ok &&
      streamed->GetWidth() > 0 && streamed->GetHeight() > 0) {
    copy.reset(streamed->Clone(0, 0, streamed->GetWidth(), streamed->GetHeight(),
                               PixelFormat32bppARGB));
    if (copy && copy->GetLastStatus() != Gdiplus::Ok) copy.reset();
  }
  streamed.reset();
  stream->Release();
  return copy;
}

int Dpi() {
  if (g_hwnd != nullptr) {
    const UINT dpi = GetDpiForWindow(g_hwnd);
    if (dpi != 0) return static_cast<int>(dpi);
  }
  return GetDpiForSystem();
}

int S(int value) { return MulDiv(value, Dpi(), 96); }

struct RowMetrics {
  int pad;
  int avatar;
  int ring;
  int gap;
  int rowGap;
  int nameW;
  int rowW;
  int rowH;
};

RowMetrics Metrics() {
  RowMetrics m;
  m.pad = S(kPad);
  m.avatar = S(kAvatar);
  m.ring = S(kRing);
  m.gap = S(kGap);
  m.rowGap = S(kRowGap);
  m.nameW = S(kNameW);
  m.rowH = m.avatar + m.ring * 2;
  m.rowW = m.ring * 2 + m.avatar + m.gap + m.nameW;
  return m;
}

HWND HostWindow() {
  if (g_registrar == nullptr || g_registrar->GetView() == nullptr) return nullptr;
  return g_registrar->GetView()->GetNativeWindow();
}

RECT WorkRect() {
  HWND target = nullptr;
  if (!g_user_moved) target = HostWindow();
  if (target == nullptr) target = g_hwnd != nullptr ? g_hwnd : HostWindow();
  HMONITOR monitor = MonitorFromWindow(
      target != nullptr ? target : GetDesktopWindow(), MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO info{};
  info.cbSize = sizeof(info);
  if (!GetMonitorInfoW(monitor, &info)) {
    return RECT{0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN)};
  }
  return info.rcWork;
}

Layout Measure(int work_width, int work_height) {
  Layout layout;
  const int count = static_cast<int>(g_people.size());
  const RowMetrics m = Metrics();
  if (count == 0) {
    if (!g_editing) return layout;
    layout.width = S(220);
    layout.height = S(40);
    return layout;
  }
  layout.columns = 1;
  layout.width = m.pad * 2 + m.rowW;
  if (work_width > 0 && layout.width > work_width) layout.width = work_width;
  const int stride = m.rowH + m.rowGap;
  int maxRows = 12;
  if (stride > 0 && work_height > m.pad * 2) {
    maxRows = (work_height - m.pad * 2 + m.rowGap) / stride;
    if (maxRows < 1) maxRows = 1;
    if (maxRows > 16) maxRows = 16;
  }
  int shown = count;
  if (count > maxRows) {
    shown = maxRows > 1 ? maxRows - 1 : 1;
    layout.extra = count - shown;
  }
  layout.chips = shown;
  const int visuals = shown + (layout.extra > 0 ? 1 : 0);
  layout.height =
      m.pad * 2 + visuals * m.rowH + (visuals > 1 ? (visuals - 1) * m.rowGap : 0);
  return layout;
}

const Gdiplus::FontFamily* Face(Gdiplus::FontFamily& family) {
  return family.GetLastStatus() == Gdiplus::Ok
             ? &family
             : Gdiplus::FontFamily::GenericSansSerif();
}

void DrawInitial(Gdiplus::Graphics& graphics, const Gdiplus::FontFamily* face,
                 const std::wstring& name, int x, int y, int size) {
  Gdiplus::SolidBrush fill(Gdiplus::Color(255, 54, 57, 63));
  graphics.FillEllipse(&fill, x, y, size, size);
  Gdiplus::Font font(face, static_cast<Gdiplus::REAL>(S(18)),
                     Gdiplus::FontStyleBold, Gdiplus::UnitPixel);
  Gdiplus::SolidBrush letter(Gdiplus::Color(255, 255, 255, 255));
  Gdiplus::StringFormat format;
  format.SetAlignment(Gdiplus::StringAlignmentCenter);
  format.SetLineAlignment(Gdiplus::StringAlignmentCenter);
  const std::wstring initial = name.empty() ? L"?" : name.substr(0, 1);
  Gdiplus::RectF box(static_cast<Gdiplus::REAL>(x), static_cast<Gdiplus::REAL>(y),
                     static_cast<Gdiplus::REAL>(size),
                     static_cast<Gdiplus::REAL>(size));
  graphics.DrawString(initial.c_str(), -1, &font, box, &format, &letter);
}

void DrawAvatar(Gdiplus::Graphics& graphics, const Gdiplus::FontFamily* face,
                const Person& person, int x, int y, int size) {
  const auto found = g_avatars.find(person.id);
  if (found == g_avatars.end() || !found->second) {
    DrawInitial(graphics, face, person.name, x, y, size);
    return;
  }
  Gdiplus::GraphicsPath clip;
  clip.AddEllipse(x, y, size, size);
  graphics.SetClip(&clip, Gdiplus::CombineModeReplace);
  graphics.SetInterpolationMode(Gdiplus::InterpolationModeHighQualityBicubic);
  graphics.DrawImage(found->second.get(), x, y, size, size);
  graphics.ResetClip();
}

void DrawRow(Gdiplus::Graphics& graphics, const Gdiplus::FontFamily* face,
             const Gdiplus::Font& name_font, const Gdiplus::Font& speaking_font,
             const Person* person, const std::wstring& label, bool speaking,
             int left, int top, const RowMetrics& m) {
  const int ax = left + m.ring;
  const int ay = top + m.ring;
  if (speaking) {
    const int glow = S(2);
    Gdiplus::SolidBrush glow_brush(
        Gdiplus::Color(120, kSpeakingR, kSpeakingG, kSpeakingB));
    graphics.FillEllipse(&glow_brush, ax - m.ring - glow, ay - m.ring - glow,
                         m.avatar + (m.ring + glow) * 2,
                         m.avatar + (m.ring + glow) * 2);
    Gdiplus::SolidBrush ring(
        Gdiplus::Color(255, kSpeakingR, kSpeakingG, kSpeakingB));
    graphics.FillEllipse(&ring, ax - m.ring, ay - m.ring, m.avatar + m.ring * 2,
                         m.avatar + m.ring * 2);
  }
  if (person != nullptr) {
    DrawAvatar(graphics, face, *person, ax, ay, m.avatar);
  } else {
    DrawInitial(graphics, face, label, ax, ay, m.avatar);
  }
  Gdiplus::StringFormat format;
  format.SetAlignment(Gdiplus::StringAlignmentNear);
  format.SetLineAlignment(Gdiplus::StringAlignmentCenter);
  format.SetTrimming(Gdiplus::StringTrimmingEllipsisCharacter);
  format.SetFormatFlags(Gdiplus::StringFormatFlagsNoWrap);
  Gdiplus::SolidBrush name_brush(
      speaking ? Gdiplus::Color(255, kSpeakingR, kSpeakingG, kSpeakingB)
               : Gdiplus::Color(220, 214, 218, 224));
  const std::wstring& text = person != nullptr ? person->name : label;
  const int text_left = ax + m.avatar + m.gap;
  Gdiplus::RectF box(static_cast<Gdiplus::REAL>(text_left),
                     static_cast<Gdiplus::REAL>(top),
                     static_cast<Gdiplus::REAL>(m.nameW),
                     static_cast<Gdiplus::REAL>(m.rowH));
  graphics.DrawString(text.c_str(), -1, speaking ? &speaking_font : &name_font,
                      box, &format, &name_brush);
}

void Draw(Gdiplus::Graphics& graphics, const Layout& layout) {
  graphics.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);
  graphics.SetTextRenderingHint(Gdiplus::TextRenderingHintAntiAliasGridFit);
  graphics.SetCompositingMode(Gdiplus::CompositingModeSourceOver);
  graphics.Clear(Gdiplus::Color(0, 0, 0, 0));
  Gdiplus::FontFamily family(L"Microsoft YaHei UI");
  const Gdiplus::FontFamily* face = Face(family);
  if (g_people.empty()) {
    Gdiplus::Pen pen(Gdiplus::Color(160, kSpeakingR, kSpeakingG, kSpeakingB), 1.0f);
    graphics.DrawRectangle(&pen, 1, 1, layout.width - 3, layout.height - 3);
    Gdiplus::Font font(face, static_cast<Gdiplus::REAL>(S(12)),
                       Gdiplus::FontStyleRegular, Gdiplus::UnitPixel);
    Gdiplus::SolidBrush brush(Gdiplus::Color(220, 220, 224, 232));
    Gdiplus::StringFormat format;
    format.SetAlignment(Gdiplus::StringAlignmentCenter);
    format.SetLineAlignment(Gdiplus::StringAlignmentCenter);
    const std::wstring& label = g_hint.empty() ? g_empty : g_hint;
    Gdiplus::RectF box(0, 0, static_cast<Gdiplus::REAL>(layout.width),
                       static_cast<Gdiplus::REAL>(layout.height));
    graphics.DrawString(label.c_str(), -1, &font, box, &format, &brush);
    return;
  }
  if (g_editing) {
    Gdiplus::Pen pen(Gdiplus::Color(70, kSpeakingR, kSpeakingG, kSpeakingB), 1.0f);
    graphics.DrawRectangle(&pen, 0, 0, layout.width - 1, layout.height - 1);
  }
  const RowMetrics m = Metrics();
  Gdiplus::Font name_font(face, static_cast<Gdiplus::REAL>(S(14)),
                          Gdiplus::FontStyleRegular, Gdiplus::UnitPixel);
  Gdiplus::Font speaking_font(face, static_cast<Gdiplus::REAL>(S(14)),
                              Gdiplus::FontStyleBold, Gdiplus::UnitPixel);
  const int visuals = layout.chips + (layout.extra > 0 ? 1 : 0);
  for (int i = 0; i < visuals; ++i) {
    const int top = m.pad + i * (m.rowH + m.rowGap);
    if (i < layout.chips) {
      const Person& person = g_people[static_cast<size_t>(i)];
      DrawRow(graphics, face, name_font, speaking_font, &person, person.name,
              person.speaking, m.pad, top, m);
    } else {
      DrawRow(graphics, face, name_font, speaking_font, nullptr,
              L"+" + std::to_wstring(layout.extra), false, m.pad, top, m);
    }
  }
}

void CopyBitmap(void* bits, int width, int height, Gdiplus::Bitmap& canvas) {
  Gdiplus::Rect rect(0, 0, width, height);
  Gdiplus::BitmapData data{};
  if (canvas.LockBits(&rect, Gdiplus::ImageLockModeRead, PixelFormat32bppPARGB,
                      &data) != Gdiplus::Ok) {
    return;
  }
  auto* dest = static_cast<unsigned char*>(bits);
  const auto* src = static_cast<const unsigned char*>(data.Scan0);
  int stride = data.Stride;
  if (stride < 0) {
    src += static_cast<long long>(stride) * (height - 1);
    stride = -stride;
  }
  for (int y = 0; y < height; ++y) {
    memcpy(dest + static_cast<size_t>(y) * width * 4,
           src + static_cast<long long>(y) * stride,
           static_cast<size_t>(width) * 4);
  }
  canvas.UnlockBits(&data);
}

void Present(int x, int y, const Layout& layout) {
  const int width = layout.width;
  const int height = layout.height;
  if (g_hwnd == nullptr || width <= 0 || height <= 0 || !EnsureGdiplus()) return;
  HDC screen = GetDC(nullptr);
  HDC memory = CreateCompatibleDC(screen);
  BITMAPINFO info{};
  info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  info.bmiHeader.biWidth = width;
  info.bmiHeader.biHeight = -height;
  info.bmiHeader.biPlanes = 1;
  info.bmiHeader.biBitCount = 32;
  info.bmiHeader.biCompression = BI_RGB;
  void* bits = nullptr;
  HBITMAP dib = CreateDIBSection(memory, &info, DIB_RGB_COLORS, &bits, nullptr, 0);
  if (dib == nullptr || bits == nullptr) {
    if (dib != nullptr) DeleteObject(dib);
    DeleteDC(memory);
    ReleaseDC(nullptr, screen);
    return;
  }
  HGDIOBJ previous = SelectObject(memory, dib);
  memset(bits, 0, static_cast<size_t>(width) * static_cast<size_t>(height) * 4);

  Gdiplus::Bitmap canvas(width, height, PixelFormat32bppPARGB);
  Gdiplus::Graphics graphics(&canvas);
  Draw(graphics, layout);
  CopyBitmap(bits, width, height, canvas);

  POINT origin{x, y};
  SIZE size{width, height};
  POINT source{0, 0};
  BLENDFUNCTION blend{};
  blend.BlendOp = AC_SRC_OVER;
  blend.SourceConstantAlpha = 255;
  blend.AlphaFormat = AC_SRC_ALPHA;
  UpdateLayeredWindow(g_hwnd, screen, &origin, &size, memory, &source, 0, &blend,
                      ULW_ALPHA);
  SelectObject(memory, previous);
  DeleteObject(dib);
  DeleteDC(memory);
  ReleaseDC(nullptr, screen);
  SetWindowPos(g_hwnd, HWND_TOPMOST, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW);
}

LRESULT CALLBACK OverlayProc(HWND hwnd, UINT message, WPARAM wparam,
                             LPARAM lparam);

void ReportFrame() {
  if (g_channel == nullptr || g_hwnd == nullptr) return;
  RECT rect{};
  if (!GetWindowRect(g_hwnd, &rect)) return;
  flutter::EncodableMap frame;
  frame[flutter::EncodableValue("x")] = flutter::EncodableValue(rect.left);
  frame[flutter::EncodableValue("y")] = flutter::EncodableValue(rect.top);
  frame[flutter::EncodableValue("width")] =
      flutter::EncodableValue(rect.right - rect.left);
  frame[flutter::EncodableValue("height")] =
      flutter::EncodableValue(rect.bottom - rect.top);
  g_channel->InvokeMethod("frame",
                          std::make_unique<flutter::EncodableValue>(frame));
}

void ShowOverlay() {
  if (g_hwnd == nullptr || g_dragging) return;
  const RECT work = WorkRect();
  const Layout layout = Measure(work.right - work.left, work.bottom - work.top);
  if (layout.width <= 0 || layout.height <= 0) {
    ShowWindow(g_hwnd, SW_HIDE);
    return;
  }
  int x = 0;
  int y = 0;
  if (g_user_moved && g_have_origin) {
    x = g_origin_x;
    y = g_origin_y;
  } else if (g_apply_frame) {
    x = g_x;
    y = g_y;
  } else {
    x = work.left + S(12);
    y = work.top +
        AtLeast((work.bottom - work.top - layout.height) / 2, 0);
  }
  Present(x, y, layout);
}

void ApplyStyle() {
  if (g_hwnd == nullptr) return;
  LONG_PTR style =
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_LAYERED | WS_EX_NOACTIVATE;
  if (!g_editing) style |= WS_EX_TRANSPARENT;
  SetWindowLongPtr(g_hwnd, GWL_EXSTYLE, style);
  SetWindowPos(g_hwnd, HWND_TOPMOST, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_FRAMECHANGED);
}

bool EnsureWindow() {
  if (g_hwnd != nullptr) return true;
  if (!g_class_ready) {
    WNDCLASSW window_class{};
    window_class.lpfnWndProc = OverlayProc;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.lpszClassName = kClassName;
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    if (RegisterClassW(&window_class) == 0 &&
        GetLastError() != ERROR_CLASS_ALREADY_EXISTS) {
      return false;
    }
    g_class_ready = true;
  }
  g_hwnd = CreateWindowExW(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_LAYERED | WS_EX_NOACTIVATE |
          WS_EX_TRANSPARENT,
      kClassName, L"", WS_POPUP, 0, 0, 1, 1, nullptr, nullptr,
      GetModuleHandle(nullptr), nullptr);
  return g_hwnd != nullptr;
}

void Apply(const flutter::EncodableMap& map) {
  g_visible = ReadBool(map, "visible");
  g_editing = ReadBool(map, "editing");
  g_apply_frame = ReadBool(map, "applyFrame");
  g_x = ReadInt(map, "x", g_x);
  g_y = ReadInt(map, "y", g_y);
  g_empty = ReadString(map, "empty");
  g_hint = ReadString(map, "hint");
  g_people.clear();
  const auto it = map.find(flutter::EncodableValue("users"));
  if (it != map.end()) {
    if (const auto* list = std::get_if<flutter::EncodableList>(&it->second)) {
      for (const auto& item : *list) {
        const auto* user = std::get_if<flutter::EncodableMap>(&item);
        if (user == nullptr) continue;
        Person person;
        person.id = ReadString(*user, "id");
        person.name = ReadString(*user, "name");
        person.speaking = ReadBool(*user, "speaking");
        if (person.id.empty() && person.name.empty()) continue;
        if (person.id.empty()) person.id = person.name;
        if (person.name.empty()) person.name = L"?";
        if (const auto* bytes = ReadBytes(*user, "avatar")) {
          if (auto image = DecodeAvatar(*bytes)) {
            g_avatars[person.id] = std::move(image);
          }
        }
        g_people.push_back(std::move(person));
      }
    }
  }
  if (!g_visible) {
    if (g_hwnd != nullptr) ShowWindow(g_hwnd, SW_HIDE);
    return;
  }
  if (!EnsureWindow()) return;
  ApplyStyle();
  ShowOverlay();
}

LRESULT CALLBACK OverlayProc(HWND hwnd, UINT message, WPARAM wparam,
                             LPARAM lparam) {
  switch (message) {
    case WM_PAINT:
      ValidateRect(hwnd, nullptr);
      return 0;
    case WM_ERASEBKGND:
      return 1;
    case WM_MOUSEACTIVATE:
      return MA_NOACTIVATE;
    case WM_ENTERSIZEMOVE:
      g_dragging = true;
      return 0;
    case WM_EXITSIZEMOVE: {
      g_dragging = false;
      RECT rect{};
      if (GetWindowRect(hwnd, &rect)) {
        g_origin_x = rect.left;
        g_origin_y = rect.top;
        g_have_origin = true;
        g_user_moved = true;
      }
      ReportFrame();
      ShowOverlay();
      return 0;
    }
    case WM_NCHITTEST:
      return g_editing ? HTCAPTION : HTTRANSPARENT;
    case WM_DESTROY:
      if (g_hwnd == hwnd) g_hwnd = nullptr;
      return 0;
    default:
      return DefWindowProc(hwnd, message, wparam, lparam);
  }
}

}  // namespace

void SpeakerOverlayRegister(flutter::FlutterEngine* engine) {
  if (engine == nullptr || g_channel != nullptr) return;
  g_registrar = new flutter::PluginRegistrarWindows(
      engine->GetRegistrarForPlugin("SpeakerOverlay"));
  g_channel = new flutter::MethodChannel<flutter::EncodableValue>(
      g_registrar->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  g_channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() != "update") {
          result->NotImplemented();
          return;
        }
        if (const auto* args =
                std::get_if<flutter::EncodableMap>(call.arguments())) {
          Apply(*args);
        }
        result->Success();
      });
}

void SpeakerOverlayDestroy() {
  if (g_hwnd != nullptr) {
    DestroyWindow(g_hwnd);
    g_hwnd = nullptr;
  }
  ShutdownGdiplus();
}
