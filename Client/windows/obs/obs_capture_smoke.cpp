// SPDX-License-Identifier: GPL-3.0-or-later
// Native capture check; no server/account required.
#include "obs_capture.h"
#include "libwebrtc.h"
#include <windows.h>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <iostream>
#include <mutex>
#include <thread>

using namespace libwebrtc;
using namespace std::chrono_literals;
extern "C" __declspec(dllexport) void VokuszStopObsCapture();

class Frames : public RTCVideoRenderer<scoped_refptr<RTCVideoFrame>> {
 public:
  void OnFrame(scoped_refptr<RTCVideoFrame> frame) override {
    std::lock_guard<std::mutex> lock(mutex);
    valid = valid && frame && frame->width() == 640 && frame->height() == 360 &&
        frame->DataY() && frame->DataU() && frame->DataV();
    ++frame_count;
    changed.notify_all();
  }
  bool Wait() {
    std::unique_lock<std::mutex> lock(mutex);
    return changed.wait_for(lock, 10s, [&] { return frame_count >= 10; }) && valid;
  }
  std::mutex mutex;
  std::condition_variable changed;
  std::atomic<int> frame_count{0};
  bool valid = true;
};

int main(int argc, char** argv) {
  const auto com = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  if (FAILED(com)) return 1;
  if (!LibWebRTC::Initialize()) return 1;
  const std::string id = argc > 1 ? argv[1] : "0";
  const bool window = argc > 2 && std::string(argv[2]) == "window";
  std::string error;
  auto factory = LibWebRTC::CreateRTCPeerConnectionFactory();
  if (!factory || !factory->Initialize()) return 1;
  auto source = factory->CreateCustomVideoSource("obs smoke", RTCMediaConstraints::Create());
  if (CreateObsCapture("bad-id", false, 640, 360, 15, source, {}, error) || error.empty()) return 2;
  if (CreateObsCapture(id, window, 0, 360, 15, source, {}, error)) return 3;
  for (int run = 0; run < 2; ++run) {
    Frames sink;
    auto track = factory->CreateVideoTrack(source, "obs smoke track");
    track->AddRenderer(&sink);
    int stops = 0;
    auto capture = CreateObsCapture(id, window, 640, 360, 15, source, [&] { ++stops; }, error);
    if (!capture) { std::cerr << error << '\n'; return 4; }
    if (!capture->CaptureStarted() || !sink.Wait()) {
      std::cerr << "No valid 640x360 I420 frames; frame_count=" << sink.frame_count << '\n';
      return 5;
    }
    if (CreateObsCapture(id, window, 640, 360, 15, source, {}, error)) return 6;
    if (run == 0) capture->StopCapture();
    else VokuszStopObsCapture();
    const int stopped_frame_count = sink.frame_count;
    std::this_thread::sleep_for(200ms);
    capture->StopCapture();
    if (capture->CaptureStarted() || stops != 1 || sink.frame_count != stopped_frame_count) return 7;
    track->RemoveRenderer(&sink);
    std::cout << "Capture " << run + 1 << ": " << stopped_frame_count
              << " frames, stopped cleanly\n";
  }
  source = nullptr;
  factory->Terminate();
  factory = nullptr;
  LibWebRTC::Terminate();
  CoUninitialize();
  std::cout << "OBS capture smoke check passed\n";
  return 0;
}
