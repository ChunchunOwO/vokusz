# Keep the Dart API and the pinned flutter_webrtc dependency. Only replace its
# Windows desktop capture translation unit; cameras and other platforms are intact.
include(FetchContent)
if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8 OR CMAKE_GENERATOR_PLATFORM STREQUAL "ARM64")
  message(FATAL_ERROR "The bundled OBS capture runtime requires Windows x64")
endif()
FetchContent_Declare(obs_headers
  URL https://github.com/obsproject/obs-studio/releases/download/31.1.2/OBS-Studio-31.1.2-Sources.tar.gz
  URL_HASH SHA256=5d66d4fb0d3ea91bb16aed58843bf652cf5b0aa692480b3d37eb878333b74f97
  SOURCE_SUBDIR unused)
FetchContent_Declare(obs_runtime
  URL https://github.com/obsproject/obs-studio/releases/download/31.1.2/OBS-Studio-31.1.2-Windows-x64.zip
  URL_HASH SHA256=9513cd402936593a6a5500da5d2bd49e6cd04dce05509c7b7f48dd25c391d2d8
  SOURCE_SUBDIR unused)
# These archives are data dependencies, not projects to build.
FetchContent_MakeAvailable(obs_headers obs_runtime)
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/obsconfig.h"
  "#pragma once\n#define OBS_RELEASE_CANDIDATE 0\n#define OBS_BETA 0\n")

get_target_property(webrtc_sources flutter_webrtc_plugin SOURCES)
get_target_property(webrtc_dir flutter_webrtc_plugin SOURCE_DIR)
file(READ "${webrtc_dir}/../common/cpp/src/flutter_screen_capture.cc" webrtc_capture_source)
string(REPLACE "\r\n" "\n" webrtc_capture_source "${webrtc_capture_source}")
string(SHA256 webrtc_capture_hash "${webrtc_capture_source}")
if(NOT webrtc_capture_hash STREQUAL "249f378db55ee40cec259b507ee6c5c5184dea80b137309815ef5794dc7c30cf")
  message(FATAL_ERROR "flutter_webrtc capture changed; rebase windows/obs/flutter_screen_capture.cc before upgrading")
endif()
list(FILTER webrtc_sources EXCLUDE REGEX "flutter_screen_capture\\.cc$")
set_property(TARGET flutter_webrtc_plugin PROPERTY SOURCES "${webrtc_sources}")
target_sources(flutter_webrtc_plugin PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/flutter_screen_capture.cc"
  "${CMAKE_CURRENT_SOURCE_DIR}/obs_capture.cpp")
target_include_directories(flutter_webrtc_plugin PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}")
target_include_directories(flutter_webrtc_plugin SYSTEM PRIVATE
  "${obs_headers_SOURCE_DIR}/libobs" "${obs_headers_SOURCE_DIR}/libobs-winrt")
target_compile_definitions(flutter_webrtc_plugin PRIVATE NOMINMAX)
target_compile_options(flutter_webrtc_plugin PRIVATE /utf-8)

# libobs is loaded lazily from this private directory. Do not ship the OBS UI,
# unrelated plugins. FFmpeg dependencies remain in the private directory.
install(DIRECTORY "${obs_runtime_SOURCE_DIR}/bin/64bit/"
  DESTINATION "${CMAKE_INSTALL_PREFIX}/obs/bin/64bit"
  FILES_MATCHING PATTERN "obs.dll" PATTERN "libobs-d3d11.dll"
  PATTERN "libobs-winrt.dll" PATTERN "w32-pthreads.dll"
  PATTERN "avcodec-*.dll" PATTERN "avformat-*.dll" PATTERN "avutil-*.dll"
  PATTERN "swscale-*.dll" PATTERN "swresample-*.dll" PATTERN "zlib.dll"
  PATTERN "libx264-*.dll" PATTERN "librist.dll" PATTERN "srt.dll")
install(DIRECTORY "${obs_runtime_SOURCE_DIR}/data/libobs"
  DESTINATION "${CMAKE_INSTALL_PREFIX}/obs/data")
install(FILES "${obs_headers_SOURCE_DIR}/COPYING"
  DESTINATION "${CMAKE_INSTALL_PREFIX}/obs" RENAME LICENSE)

# Explicit target, not included in release bundles or the normal build.
add_executable(obs_capture_smoke EXCLUDE_FROM_ALL obs_capture_smoke.cpp obs_capture.cpp)
apply_standard_settings(obs_capture_smoke)
target_compile_definitions(obs_capture_smoke PRIVATE NOMINMAX LIB_WEBRTC_API_DLL RTC_DESKTOP_DEVICE)
target_compile_options(obs_capture_smoke PRIVATE /utf-8)
target_include_directories(obs_capture_smoke PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
target_include_directories(obs_capture_smoke SYSTEM PRIVATE
  "${obs_headers_SOURCE_DIR}/libobs" "${obs_headers_SOURCE_DIR}/libobs-winrt")
target_link_libraries(obs_capture_smoke PRIVATE flutter_webrtc_plugin ole32
  "${CMAKE_SOURCE_DIR}/flutter/ephemeral/.plugin_symlinks/flutter_webrtc/third_party/libwebrtc/lib/libwebrtc.dll.lib")
set_target_properties(obs_capture_smoke PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/obs-test")
add_custom_command(TARGET obs_capture_smoke POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${webrtc_dir}/../third_party/libwebrtc/lib/libwebrtc.dll" "$<TARGET_FILE_DIR:obs_capture_smoke>"
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    "$<TARGET_FILE_DIR:${BINARY_NAME}>/obs" "$<TARGET_FILE_DIR:obs_capture_smoke>/obs")
