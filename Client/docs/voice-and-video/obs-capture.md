# Windows OBS capture

Windows x64 screen sharing uses bundled OBS Studio 31.1.2 libraries (`libobs`,
`libobs-d3d11`, `libobs-winrt`). Users do not need to install or launch OBS.
Windows Graphics Capture requires Windows 10 1903 or later and a working D3D11
driver. Minimized or protected windows may not produce frames; restore the
selected window before sharing. Web and other platforms retain their existing capture backends.

The existing source picker selects a window or display. The native bridge binds
the exact HWND/HMONITOR, uses OBS to composite, scale and convert to I420 on the
GPU, then feeds the existing WebRTC video source. Frames do not cross Dart.
Resolution and FPS settings apply before frames enter WebRTC; aspect ratio is
preserved with letterboxing. LiveKit still handles encoding, transport and
subscriptions, with one video layer. This is not OBS NVENC encoding or a
zero-copy GPU texture path: WebRTC's public frame API still requires an I420 copy.
Actual CPU/GPU/memory savings depend on the workload and negotiated encoder.

Capture is initialized only when sharing starts. Track/stream disposal stops
frame delivery, releases OBS and stops optional loopback audio. The runner also
stops capture before destroying Flutter/WebRTC during application exit. A
capture initialization failure is shown in the picker flow and does not mark the
user as sharing. There is no silent switch to another source or backend.

## Build and check

`flutter build windows --release` downloads the official source headers and
Windows runtime archives into CMake's build cache, checks pinned SHA-256 hashes,
and installs the required runtime files under `obs/` beside `vokusz.exe`. Ship
this directory with the application. The first build needs network access and
downloads approximately 200 MB. The normal build does not compile OBS itself.

The Windows-only override in `windows/obs/flutter_screen_capture.cc` is derived
from the pinned flutter_webrtc commit named at the top of that file. CMake
replaces only that translation unit, without modifying the pub cache. A source
hash check requires rebasing this override when updating flutter_webrtc. The
upstream MIT license is retained alongside it; the OBS GPL license is included
in the runtime bundle. OBS sources: <https://github.com/obsproject/obs-studio/tree/31.1.2>.

Run these from `Client/` after building the application:

```powershell
flutter test test/features/voice/screen_share_quality_test.dart test/l10n
# Use the same CMake binary Flutter selected (not a different PATH version).
$buildCmake = ((Select-String '^CMAKE_COMMAND:INTERNAL=' build/windows/x64/CMakeCache.txt).Line -split '=', 2)[1]
& $buildCmake --build build/windows/x64 --config Release --target obs_capture_smoke
./build/windows/x64/obs-test/Release/obs_capture_smoke.exe
# Optional: pass the decimal HWND selected by the source picker.
./build/windows/x64/obs-test/Release/obs_capture_smoke.exe <HWND> window
```

The native check verifies actual OBS → WebRTC track → renderer delivery at
640×360, rejects invalid arguments and concurrent captures, runs two start/stop
cycles, and checks that no frames arrive after stopping. It needs an unlocked
interactive desktop. It saves no captured images and requires no server/account.
The test executable is separate from the application bundle. Remote playback,
encoder selection and resource use during a live call still need an end-to-end
check with another participant at the same resolution/FPS/content as the baseline.
