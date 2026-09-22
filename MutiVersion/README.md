# MutiVersion

Parked platform trees. **Do not build or maintain these from the main line.**

Windows is the product. Android, Linux, macOS, and iOS are frozen here until they are taken on as separate work.

| Path | Platform |
|------|----------|
| `android/` | Android Flutter runner |
| `ios/` | iOS Flutter runner |
| `linux/` | Linux Flutter runner |
| `macos/` | macOS Flutter runner |
| `fastlane/` | iOS / Android store lanes |
| `store-media/` | Store screenshots |
| `workflows/` | Old non-Windows CI |

To revive a platform later: copy its folder back next to `Client/windows/`, then wire a dedicated pipeline. Until then, leave this directory alone.
