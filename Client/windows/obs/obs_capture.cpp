// SPDX-License-Identifier: GPL-3.0-or-later
#include "obs_capture.h"

#include <windows.h>
#include <algorithm>
#include <atomic>
#include <charconv>
#include <chrono>
#include <condition_variable>
#include <filesystem>
#include <mutex>
#include <utility>
#include <obs.h>
#include <winrt-capture.h>

using namespace libwebrtc;
namespace {
// ponytail: libobs has one global video output; reject a second capture rather
// than reconfiguring a running share. Use separate workers for concurrent shares.
std::atomic<bool> active{false};
class ObsCapture;
ObsCapture* current = nullptr;  // Start/stop are on Flutter's platform thread.

#define OBS_FUNCTIONS(X) \
  X(obs_startup) X(obs_shutdown) X(obs_add_data_path) X(obs_remove_data_path) X(obs_reset_video) \
  X(obs_register_source_s) X(obs_enter_graphics) X(obs_leave_graphics) \
  X(obs_source_create_private) \
  X(obs_source_release) X(obs_queue_task) \
  X(obs_scene_create_private) X(obs_scene_release) X(obs_scene_get_source) \
  X(obs_scene_add) X(obs_sceneitem_set_bounds_type) X(obs_sceneitem_set_bounds) \
  X(obs_set_output_source) X(obs_add_raw_video_callback) X(obs_remove_raw_video_callback)

struct ObsApi {
  HMODULE module = nullptr;
  HMODULE winrt = nullptr;
#define DECLARE(name) decltype(&::name) name = nullptr;
  OBS_FUNCTIONS(DECLARE)
  DECLARE(winrt_capture_init_window)
  DECLARE(winrt_capture_init_monitor)
  DECLARE(winrt_capture_free)
  DECLARE(winrt_capture_active)
  DECLARE(winrt_capture_render)
  DECLARE(winrt_capture_width)
  DECLARE(winrt_capture_height)
#undef DECLARE
  bool Load(const std::filesystem::path& bin, std::string& error) {
    const auto flags = LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR | LOAD_LIBRARY_SEARCH_DEFAULT_DIRS;
    module = LoadLibraryExW((bin / L"obs.dll").c_str(), nullptr, flags);
    if (!module) {
      error = "Cannot load bundled OBS core (Windows error " + std::to_string(GetLastError()) + ")";
      return false;
    }
#define LOAD(name) \
    name = reinterpret_cast<decltype(name)>(GetProcAddress(module, #name)); \
    if (!name) { error = "Missing OBS API: " #name; return false; }
    OBS_FUNCTIONS(LOAD)
#undef LOAD
    // Load the exact bundled WGC implementation, without a global DLL search path.
    winrt = LoadLibraryExW((bin / L"libobs-winrt.dll").c_str(), nullptr, flags);
    if (!winrt) {
      error = "Cannot load bundled OBS Windows Graphics Capture module";
      return false;
    }
#define LOAD_WGC(name) \
    name = reinterpret_cast<decltype(name)>(GetProcAddress(winrt, #name)); \
    if (!name) { error = "Missing OBS WGC API: " #name; return false; }
    LOAD_WGC(winrt_capture_init_window)
    LOAD_WGC(winrt_capture_init_monitor)
    LOAD_WGC(winrt_capture_free)
    LOAD_WGC(winrt_capture_active)
    LOAD_WGC(winrt_capture_render)
    LOAD_WGC(winrt_capture_width)
    LOAD_WGC(winrt_capture_height)
#undef LOAD_WGC
    return true;
  }
  ~ObsApi() {
    if (winrt) FreeLibrary(winrt);
    if (module) FreeLibrary(module);
  }
};

class ObsCapture : public RTCVideoCapturer {
 public:
  ObsCapture(scoped_refptr<RTCVideoSource> destination, std::function<void()> on_stop)
      : destination_(destination), on_stop_(std::move(on_stop)) {}
  ~ObsCapture() override { StopCapture(); }

  bool Initialize(const std::string& id, bool window, int width, int height,
                  int fps, std::string& error) {
    if (!destination_ || width < 160 || width > 7680 || height < 90 ||
        height > 4320 || fps < 1 || fps > 60) {
      error = "Invalid OBS capture dimensions or frame rate";
      return false;
    }
    uint64_t numeric_id = 0;
    const auto parsed = std::from_chars(id.data(), id.data() + id.size(), numeric_id);
    if (parsed.ec != std::errc{} || parsed.ptr != id.data() + id.size()) {
      error = "Invalid desktop source ID";
      return false;
    }
    if (window) {
      window_ = reinterpret_cast<HWND>(static_cast<uintptr_t>(numeric_id));
      if (!IsWindow(window_) || !GetWindowThreadProcessId(window_, &process_id_)) {
        error = "Selected window is no longer available";
        return false;
      }
    } else {
      // WebRTC's Windows screen IDs are EnumDisplayDevices device indices.
      DISPLAY_DEVICEW display{};
      display.cb = sizeof(display);
      DEVMODEW mode{};
      mode.dmSize = sizeof(mode);
      if (numeric_id > MAXDWORD ||
          !EnumDisplayDevicesW(nullptr, static_cast<DWORD>(numeric_id), &display, 0) ||
          !(display.StateFlags & DISPLAY_DEVICE_ACTIVE) ||
          !EnumDisplaySettingsW(display.DeviceName, ENUM_CURRENT_SETTINGS, &mode)) {
        error = "Selected monitor is no longer available";
        return false;
      }
      const POINT point{mode.dmPosition.x, mode.dmPosition.y};
      monitor_ = MonitorFromPoint(point, MONITOR_DEFAULTTONULL);
      if (!monitor_) { error = "Selected monitor was disconnected"; return false; }
    }
    if (active.exchange(true)) {
      error = "An OBS screen capture is already running";
      return false;
    }
    owns_core_ = true;
    wchar_t executable[32768]{};
    if (!GetModuleFileNameW(nullptr, executable, static_cast<DWORD>(std::size(executable)))) {
      error = "Cannot locate bundled OBS runtime";
      return false;
    }
    const auto root = std::filesystem::path(executable).parent_path() / L"obs";
    const auto bin = root / L"bin" / L"64bit";
    if (!api_.Load(bin, error)) return false;
    initialized_ = api_.obs_startup("en-US", nullptr, nullptr);
    if (!initialized_) { error = "OBS core initialization failed"; return false; }
    data_path_ = (root / L"data" / L"libobs").u8string() + "/";
    api_.obs_add_data_path(data_path_.c_str());
    width_ = width & ~1;
    height_ = height & ~1;
    const auto graphics = (bin / L"libobs-d3d11.dll").u8string();
    obs_video_info video{};
    video.graphics_module = graphics.c_str();
    video.fps_num = static_cast<uint32_t>(fps);
    video.fps_den = 1;
    video.base_width = video.output_width = static_cast<uint32_t>(width_);
    video.base_height = video.output_height = static_cast<uint32_t>(height_);
    video.output_format = VIDEO_FORMAT_I420;
    video.gpu_conversion = true;
    video.colorspace = VIDEO_CS_709;
    video.range = VIDEO_RANGE_PARTIAL;
    video.scale_type = OBS_SCALE_BILINEAR;
    if (api_.obs_reset_video(&video) != OBS_VIDEO_SUCCESS) {
      error = "OBS D3D11 video initialization failed";
      return false;
    }
    // Bind directly to the selected HWND/HMONITOR. OBS's standard window
    // plugin re-finds by title/class and can pick a different same-title window.
    obs_source_info source{};
    source.id = "vokusz_wgc";
    source.type = OBS_SOURCE_TYPE_INPUT;
    source.output_flags = OBS_SOURCE_VIDEO | OBS_SOURCE_CUSTOM_DRAW | OBS_SOURCE_SRGB;
    source.get_name = [](void*) { return "Vokusz OBS capture"; };
    source.create = [](obs_data_t*, obs_source_t*) -> void* { return creating_; };
    source.destroy = [](void* data) {
      auto& self = *static_cast<ObsCapture*>(data);
      self.api_.obs_queue_task(OBS_TASK_GRAPHICS, [](void* opaque) {
        auto& capture = *static_cast<ObsCapture*>(opaque);
        capture.api_.winrt_capture_free(capture.wgc_);
        capture.wgc_ = nullptr;
      }, data, false);
    };
    source.get_width = [](void* data) {
      auto& self = *static_cast<ObsCapture*>(data);
      return self.wgc_ ? self.api_.winrt_capture_width(self.wgc_) : 0U;
    };
    source.get_height = [](void* data) {
      auto& self = *static_cast<ObsCapture*>(data);
      return self.wgc_ ? self.api_.winrt_capture_height(self.wgc_) : 0U;
    };
    source.video_tick = [](void* data, float) {
      auto& self = *static_cast<ObsCapture*>(data);
      std::lock_guard<std::mutex> lock(self.start_mutex_);
      if (self.attempted_) return;
      // WGC's frame pool is thread-affine: create and consume it on OBS's
      // graphics thread, never on Flutter's platform/STA thread.
      self.api_.obs_enter_graphics();
      self.wgc_ = self.window_
          ? self.api_.winrt_capture_init_window(TRUE, self.window_, FALSE, TRUE)
          : self.api_.winrt_capture_init_monitor(TRUE, self.monitor_, TRUE);
      self.api_.obs_leave_graphics();
      self.attempted_ = true;
      self.start_changed_.notify_one();
    };
    source.video_render = [](void* data, gs_effect_t*) {
      auto& self = *static_cast<ObsCapture*>(data);
      if (self.wgc_ && self.api_.winrt_capture_active(self.wgc_)) {
        self.api_.winrt_capture_render(self.wgc_);
        self.ready_ = self.api_.winrt_capture_width(self.wgc_) > 0 &&
            self.api_.winrt_capture_height(self.wgc_) > 0;
      }
    };
    api_.obs_register_source_s(&source, sizeof(source));
    creating_ = this;
    capture_ = api_.obs_source_create_private("vokusz_wgc", "Vokusz screen share", nullptr);
    creating_ = nullptr;
    if (!capture_) { error = "OBS could not create the selected capture source"; return false; }
    scene_ = api_.obs_scene_create_private("Vokusz screen share scene");
    if (!scene_) { error = "OBS could not create the capture scene"; return false; }
    auto* item = api_.obs_scene_add(scene_, capture_);
    if (!item) { error = "OBS could not attach the capture source"; return false; }
    vec2 bounds{};
    bounds.x = static_cast<float>(width_);
    bounds.y = static_cast<float>(height_);
    api_.obs_sceneitem_set_bounds_type(item, OBS_BOUNDS_SCALE_INNER);
    api_.obs_sceneitem_set_bounds(item, &bounds);
    api_.obs_set_output_source(0, api_.obs_scene_get_source(scene_));
    running_ = true;
    api_.obs_add_raw_video_callback(nullptr, Frame, this);
    std::unique_lock<std::mutex> lock(start_mutex_);
    if (!start_changed_.wait_for(lock, std::chrono::seconds(5), [&] { return attempted_; }) || !wgc_) {
      error = "OBS Windows Graphics Capture could not start";
      return false;
    }
    return true;
  }

  bool StartCapture() override { return running_; }
  bool CaptureStarted() override { return running_; }
  void StopCapture() override {
    if (current == this) current = nullptr;
    const bool was_running = running_;
    if (running_) {
      // Disconnect joins any callback before releasing its destination or OBS.
      api_.obs_remove_raw_video_callback(Frame, this);
      running_ = false;
    }
    if (initialized_) {
      api_.obs_set_output_source(0, nullptr);
      if (scene_) api_.obs_scene_release(scene_);
      if (capture_) api_.obs_source_release(capture_);
      else if (wgc_) {
        api_.obs_enter_graphics();
        api_.winrt_capture_free(wgc_);
        wgc_ = nullptr;
        api_.obs_leave_graphics();
      }
      scene_ = nullptr;
      capture_ = nullptr;
      api_.obs_remove_data_path(data_path_.c_str());
      api_.obs_shutdown();
      initialized_ = false;
    }
    destination_ = nullptr;
    if (owns_core_) { active = false; owns_core_ = false; }
    if (was_running && on_stop_) { auto stop = std::move(on_stop_); stop(); }
  }

 private:
  static void Frame(void* opaque, video_data* frame) {
    auto& self = *static_cast<ObsCapture*>(opaque);
    if (self.window_) {
      DWORD pid = 0;
      GetWindowThreadProcessId(self.window_, &pid);
      if (!IsWindow(self.window_) || pid != self.process_id_) return;
    }
    if (!self.ready_) return;
    // libobs scales and converts on the GPU. One I420 copy into WebRTC's owned
    // frame is still required by its public API; no RGBA round-trip through Dart.
    auto video = RTCVideoFrame::Create(self.width_, self.height_,
        frame->data[0], static_cast<int>(frame->linesize[0]),
        frame->data[1], static_cast<int>(frame->linesize[1]),
        frame->data[2], static_cast<int>(frame->linesize[2]));
    if (video) self.destination_->OnCapturedFrame(video);
  }
  ObsApi api_;
  std::string data_path_;
  scoped_refptr<RTCVideoSource> destination_;
  std::function<void()> on_stop_;
  bool owns_core_ = false, initialized_ = false, running_ = false;
  std::mutex start_mutex_;
  std::condition_variable start_changed_;
  bool attempted_ = false;
  std::atomic<bool> ready_{false};
  int width_ = 0, height_ = 0;
  inline static thread_local ObsCapture* creating_ = nullptr;
  HWND window_ = nullptr;
  HMONITOR monitor_ = nullptr;
  winrt_capture* wgc_ = nullptr;
  DWORD process_id_ = 0;
  obs_source_t* capture_ = nullptr;
  obs_scene_t* scene_ = nullptr;
};
}  // namespace

scoped_refptr<RTCVideoCapturer> CreateObsCapture(
    const std::string& source_id, bool window, int width, int height, int fps,
    scoped_refptr<RTCVideoSource> destination, std::function<void()> on_stop,
    std::string& error) {
  scoped_refptr<ObsCapture> capture = new RefCountedObject<ObsCapture>(destination, std::move(on_stop));
  if (!capture->Initialize(source_id, window, width, height, fps, error)) return nullptr;
  current = capture.get();
  return capture;
}

// The runner calls this before Flutter destroys WebRTC's worker threads.
extern "C" __declspec(dllexport) void VokuszStopObsCapture() {
  if (current) current->StopCapture();
}
