// Adapted from flutter_webrtc 978849b90adfaa6d52381c82cf1fbd74ccf5731b.
// Upstream MIT license: see flutter_webrtc_LICENSE. Windows OBS capture only.
#include "flutter_screen_capture.h"
#include "obs_capture.h"
#include <cmath>
#include <memory>
#include <string>

namespace flutter_webrtc_plugin {
namespace {
struct AppAudioSession {
  std::unique_ptr<LoopbackCapturer> capturer;
  scoped_refptr<RTCAudioSource> source;
  std::string track_id;
  std::string stream_id;
};

AppAudioSession& AppAudio() {
  static AppAudioSession session;
  return session;
}

void StopAppAudioCapture() {
  auto& audio = AppAudio();
  if (audio.capturer) {
    audio.capturer->Stop();
    audio.capturer.reset();
  }
  audio.source = nullptr;
}

bool BoolIs(const EncodableMap& map, const char* key, bool expected) {
  const auto it = map.find(EncodableValue(key));
  if (it == map.end() || !TypeIs<bool>(it->second)) return false;
  return GetValue<bool>(it->second) == expected;
}

std::string AudioSourceId(const EncodableMap& constraints) {
  const auto it = constraints.find(EncodableValue("audio"));
  if (it == constraints.end() || !TypeIs<EncodableMap>(it->second)) return {};
  const auto device = findMap(GetValue<EncodableMap>(it->second), "deviceId");
  if (device.empty()) return {};
  return findString(device, "exact");
}
}  // namespace

FlutterScreenCapture::FlutterScreenCapture(FlutterWebRTCBase* base)
    : base_(base) {}

bool FlutterScreenCapture::BuildDesktopSourcesList(const EncodableList& types,
                                                   bool force_reload) {
  size_t size = types.size();
  sources_.clear();
  for (size_t i = 0; i < size; i++) {
    std::string type_str = GetValue<std::string>(types[i]);
    DesktopType desktop_type = DesktopType::kScreen;
    if (type_str == "screen") {
      desktop_type = DesktopType::kScreen;
    } else if (type_str == "window") {
      desktop_type = DesktopType::kWindow;
    } else {
      // std::cout << "Unknown type " << type_str << std::endl;
      return false;
    }
    scoped_refptr<RTCDesktopMediaList> source_list;
    auto it = medialist_.find(desktop_type);
    if (it != medialist_.end()) {
      source_list = (*it).second;
    } else {
      source_list = base_->desktop_device_->GetDesktopMediaList(desktop_type);
      source_list->RegisterMediaListObserver(this);
      medialist_[desktop_type] = source_list;
    }
    source_list->UpdateSourceList(force_reload);
    int count = source_list->GetSourceCount();
    for (int j = 0; j < count; j++) {
      sources_.push_back(source_list->GetSource(j));
    }
  }
  return true;
}

void FlutterScreenCapture::GetDesktopSources(
    const EncodableList& types,
    std::unique_ptr<MethodResultProxy> result) {
  if (!BuildDesktopSourcesList(types, true)) {
    result->Error("Bad Arguments", "Failed to get desktop sources");
    return;
  }

  EncodableList sources;
  for (auto source : sources_) {
    EncodableMap info;
    info[EncodableValue("id")] = EncodableValue(source->id().std_string());
    info[EncodableValue("name")] = EncodableValue(source->name().std_string());
    info[EncodableValue("type")] =
        EncodableValue(source->type() == kWindow ? "window" : "screen");
    // TODO "thumbnailSize"
    info[EncodableValue("thumbnailSize")] = EncodableMap{
        {EncodableValue("width"), EncodableValue(0)},
        {EncodableValue("height"), EncodableValue(0)},
    };
    sources.push_back(EncodableValue(info));
  }

  //std::cout << " sources: " << sources.size() << std::endl;
  auto map = EncodableMap();
  map[EncodableValue("sources")] = sources;
  result->Success(EncodableValue(map));
}

void FlutterScreenCapture::UpdateDesktopSources(
    const EncodableList& types,
    std::unique_ptr<MethodResultProxy> result) {
  if (!BuildDesktopSourcesList(types, false)) {
    result->Error("Bad Arguments", "Failed to update desktop sources");
    return;
  }
  auto map = EncodableMap();
  map[EncodableValue("result")] = true;
  result->Success(EncodableValue(map));
}

void FlutterScreenCapture::OnMediaSourceAdded(
    scoped_refptr<MediaSource> source) {
  std::cout << " OnMediaSourceAdded: " << source->id().std_string()
            << std::endl;

  EncodableMap info;
  info[EncodableValue("event")] = "desktopSourceAdded";
  info[EncodableValue("id")] = EncodableValue(source->id().std_string());
  info[EncodableValue("name")] = EncodableValue(source->name().std_string());
  info[EncodableValue("type")] =
      EncodableValue(source->type() == kWindow ? "window" : "screen");
  // TODO "thumbnailSize"
  info[EncodableValue("thumbnailSize")] = EncodableMap{
      {EncodableValue("width"), EncodableValue(0)},
      {EncodableValue("height"), EncodableValue(0)},
  };
  base_->event_channel()->Success(EncodableValue(info));
}

void FlutterScreenCapture::OnMediaSourceRemoved(
    scoped_refptr<MediaSource> source) {
  std::cout << " OnMediaSourceRemoved: " << source->id().std_string()
            << std::endl;

  EncodableMap info;
  info[EncodableValue("event")] = "desktopSourceRemoved";
  info[EncodableValue("id")] = EncodableValue(source->id().std_string());
  base_->event_channel()->Success(EncodableValue(info));
}

void FlutterScreenCapture::OnMediaSourceNameChanged(
    scoped_refptr<MediaSource> source) {
  std::cout << " OnMediaSourceNameChanged: " << source->id().std_string()
            << std::endl;

  EncodableMap info;
  info[EncodableValue("event")] = "desktopSourceNameChanged";
  info[EncodableValue("id")] = EncodableValue(source->id().std_string());
  info[EncodableValue("name")] = EncodableValue(source->name().std_string());
  base_->event_channel()->Success(EncodableValue(info));
}

void FlutterScreenCapture::OnMediaSourceThumbnailChanged(
    scoped_refptr<MediaSource> source) {
  std::cout << " OnMediaSourceThumbnailChanged: " << source->id().std_string()
            << std::endl;

  EncodableMap info;
  info[EncodableValue("event")] = "desktopSourceThumbnailChanged";
  info[EncodableValue("id")] = EncodableValue(source->id().std_string());
  info[EncodableValue("thumbnail")] =
      EncodableValue(source->thumbnail().std_vector());
  base_->event_channel()->Success(EncodableValue(info));
}

void FlutterScreenCapture::OnStart(scoped_refptr<RTCDesktopCapturer> capturer) {
  // std::cout << " OnStart: " << capturer->source()->id().std_string()
  //          << std::endl;
}

void FlutterScreenCapture::OnPaused(
    scoped_refptr<RTCDesktopCapturer> capturer) {
  // std::cout << " OnPaused: " << capturer->source()->id().std_string()
  //          << std::endl;
}

void FlutterScreenCapture::OnStop(scoped_refptr<RTCDesktopCapturer> capturer) {
  // std::cout << " OnStop: " << capturer->source()->id().std_string()
  //          << std::endl;
  if (loopback_capturer_) {
    loopback_capturer_->Stop();
    loopback_capturer_.reset();
    loopback_audio_source_ = nullptr;
  }
}

void FlutterScreenCapture::OnError(scoped_refptr<RTCDesktopCapturer> capturer) {
  // std::cout << " OnError: " << capturer->source()->id().std_string()
  //          << std::endl;
}

void FlutterScreenCapture::GetDesktopSourceThumbnail(
    std::string source_id,
    int width,
    int height,
    std::unique_ptr<MethodResultProxy> result) {
  (void)width;
  (void)height;
  scoped_refptr<MediaSource> source;
  for (auto src : sources_) {
    if (src->id().std_string() == source_id) {
      source = src;
    }
  }
  if (source.get() == nullptr) {
    result->Error("Bad Arguments", "Failed to get desktop source thumbnail");
    return;
  }
  std::cout << " GetDesktopSourceThumbnail: " << source->id().std_string()
            << std::endl;
  source->UpdateThumbnail();
  result->Success(EncodableValue(source->thumbnail().std_vector()));
}

void FlutterScreenCapture::GetDisplayMedia(
    const EncodableMap& constraints,
    std::unique_ptr<MethodResultProxy> result) {
  // Accompaniment is audio-only. `video: false` never starts OBS screen
  // capture, so it can run beside a share. `audio: false` stops it.
  if (BoolIs(constraints, "video", false)) {
    const auto source_id = AudioSourceId(constraints);
    const bool want_audio =
        !source_id.empty() && !BoolIs(constraints, "audio", false);
    auto& audio = AppAudio();
    if (!audio.track_id.empty()) base_->local_tracks_.erase(audio.track_id);
    if (!audio.stream_id.empty()) base_->local_streams_.erase(audio.stream_id);
    audio.track_id.clear();
    audio.stream_id.clear();
    StopAppAudioCapture();
    if (!want_audio) {
      const auto uuid = base_->GenerateUUID();
      auto stream = base_->factory_->CreateStream(uuid.c_str());
      base_->local_streams_[uuid] = stream;
      EncodableMap params;
      params[EncodableValue("streamId")] = EncodableValue(uuid);
      params[EncodableValue("audioTracks")] = EncodableValue(EncodableList());
      params[EncodableValue("videoTracks")] = EncodableValue(EncodableList());
      result->Success(EncodableValue(params));
      return;
    }
    audio.capturer = CreateLoopbackCapturer(source_id);
    RTCAudioOptions options;
    options.echo_cancellation = false;
    options.auto_gain_control = false;
    options.noise_suppression = false;
    const auto label = "app_audio_" + base_->GenerateUUID();
    audio.source = base_->factory_->CreateAudioSource(
        label.c_str(), RTCAudioSource::SourceType::kCustom, options);
    const auto track_id = base_->GenerateUUID();
    scoped_refptr<RTCAudioTrack> track =
        base_->factory_->CreateAudioTrack(audio.source, track_id.c_str());
    if (!audio.capturer || !audio.capturer->Start(audio.source)) {
      StopAppAudioCapture();
      result->Error(
          "AppAudioFailed",
          "Could not capture audio from the selected application");
      return;
    }
    audio.track_id = track->id().std_string();
    audio.stream_id = base_->GenerateUUID();
    auto stream = base_->factory_->CreateStream(audio.stream_id.c_str());
    stream->AddTrack(track);
    base_->local_tracks_[audio.track_id] = track;
    base_->local_streams_[audio.stream_id] = stream;
    EncodableMap info;
    info[EncodableValue("id")] = EncodableValue(audio.track_id);
    info[EncodableValue("label")] = EncodableValue(audio.track_id);
    info[EncodableValue("kind")] = EncodableValue(track->kind().std_string());
    info[EncodableValue("enabled")] = EncodableValue(track->enabled());
    EncodableList audio_tracks;
    audio_tracks.push_back(EncodableValue(info));
    EncodableMap params;
    params[EncodableValue("streamId")] = EncodableValue(audio.stream_id);
    params[EncodableValue("audioTracks")] = EncodableValue(audio_tracks);
    params[EncodableValue("videoTracks")] = EncodableValue(EncodableList());
    result->Success(EncodableValue(params));
    return;
  }
  const auto video = findMap(constraints, "video");
  const auto device = findMap(video, "deviceId");
  const std::string source_id = device.empty() ? "0" : findString(device, "exact");
  scoped_refptr<MediaSource> source;
  for (auto candidate : sources_) {
    if (candidate->id().std_string() == source_id) source = candidate;
  }
  if (!source) {
    result->Error("ObsCaptureFailed", "Selected desktop source is no longer available");
    return;
  }
  const auto mandatory = findMap(video, "mandatory");
  const auto number = [&](const char* key, int fallback) {
    const auto value = mandatory.find(EncodableValue(key));
    if (value == mandatory.end()) return fallback;
    if (TypeIs<int>(value->second)) return GetValue<int>(value->second);
    if (TypeIs<double>(value->second)) {
      const double v = GetValue<double>(value->second);
      if (std::isfinite(v) && v >= 0 && v <= 7680) return static_cast<int>(v);
    }
    return -1;
  };
  const auto uuid = base_->GenerateUUID();
  auto video_source = base_->factory_->CreateCustomVideoSource(
      "obs_screen_capture", base_->ParseMediaConstraints(video));
  bool capture_audio = false;
  {
    auto audio_it = constraints.find(EncodableValue("audio"));
    if (audio_it != constraints.end()) {
      if (TypeIs<bool>(audio_it->second)) {
        capture_audio = GetValue<bool>(audio_it->second);
      } else if (TypeIs<EncodableMap>(audio_it->second)) {
        capture_audio = true;
      }
    }
  }

  std::shared_ptr<LoopbackCapturer> loopback;
  // The share checkbox asks for system output, not the selected window's
  // own process. "0" is the all-system loopback.
  if (capture_audio) loopback = CreateLoopbackCapturer("0");
  std::string error;
  auto capture = CreateObsCapture(source_id, source->type() == kWindow,
      number("maxWidth", 1280), number("maxHeight", 720), number("frameRate", 30),
      video_source, [loopback] { if (loopback) loopback->Stop(); }, error);
  if (!capture) {
    result->Error("ObsCaptureFailed", error);
    return;
  }
  auto stream = base_->factory_->CreateStream(uuid.c_str());
  EncodableMap params;
  params[EncodableValue("streamId")] = EncodableValue(uuid);

  // AUDIO

  if (capture_audio) {
    // Disable all audio processing for loopback capture.  Echo cancellation,
    // AGC, and noise suppression are designed for microphone input; applied to
    // system audio they treat the captured content as echo/noise and destroy it.
    RTCAudioOptions loopback_opts;
    loopback_opts.echo_cancellation = false;
    loopback_opts.auto_gain_control = false;
    loopback_opts.noise_suppression = false;
    const std::string loopback_source_label =
      "screen_loopback_input_" + base_->GenerateUUID();
    auto loopback_audio_source = base_->factory_->CreateAudioSource(
      loopback_source_label.c_str(), RTCAudioSource::SourceType::kCustom,
        loopback_opts);

    std::string audio_uuid = base_->GenerateUUID();
    scoped_refptr<RTCAudioTrack> audio_track =
        base_->factory_->CreateAudioTrack(loopback_audio_source,
                                          audio_uuid.c_str());


    if (loopback && loopback->Start(loopback_audio_source)) {
      EncodableMap audio_info;
      audio_info[EncodableValue("id")] =
          EncodableValue(audio_track->id().std_string());
      audio_info[EncodableValue("label")] =
          EncodableValue(audio_track->id().std_string());
      audio_info[EncodableValue("kind")] =
          EncodableValue(audio_track->kind().std_string());
      audio_info[EncodableValue("enabled")] =
          EncodableValue(audio_track->enabled());

      EncodableList audioTracks;
      audioTracks.push_back(EncodableValue(audio_info));
      params[EncodableValue("audioTracks")] = EncodableValue(audioTracks);

      stream->AddTrack(audio_track);
      base_->local_tracks_[audio_track->id().std_string()] = audio_track;
    } else {
      // Loopback init failed or not supported — continue without audio.
      loopback.reset();
      loopback_audio_source = nullptr;
      params[EncodableValue("audioTracks")] = EncodableValue(EncodableList());
    }
  } else {
    params[EncodableValue("audioTracks")] = EncodableValue(EncodableList());
  }

  scoped_refptr<RTCVideoTrack> track =
      base_->factory_->CreateVideoTrack(video_source, uuid.c_str());

  EncodableList videoTracks;
  EncodableMap info;
  info[EncodableValue("id")] = EncodableValue(track->id().std_string());
  info[EncodableValue("label")] = EncodableValue(track->id().std_string());
  info[EncodableValue("kind")] = EncodableValue(track->kind().std_string());
  info[EncodableValue("enabled")] = EncodableValue(track->enabled());
  videoTracks.push_back(EncodableValue(info));
  params[EncodableValue("videoTracks")] = EncodableValue(videoTracks);

  stream->AddTrack(track);

  base_->local_tracks_[track->id().std_string()] = track;

  base_->local_streams_[uuid] = stream;

  base_->video_capturers_[track->id().std_string()] = capture;

  result->Success(EncodableValue(params));
}

}  // namespace flutter_webrtc_plugin
