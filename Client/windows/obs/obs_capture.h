// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <functional>
#include <string>
#include "rtc_video_device.h"
#include "rtc_video_source.h"

// The existing WebRTC track/stream disposal owns and stops this capturer.
libwebrtc::scoped_refptr<libwebrtc::RTCVideoCapturer> CreateObsCapture(
    const std::string& source_id, bool window, int width, int height, int fps,
    libwebrtc::scoped_refptr<libwebrtc::RTCVideoSource> destination,
    std::function<void()> on_stop, std::string& error);
