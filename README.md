# ColorWheel

Point your iPhone's camera at a piece of cloth, tap to sample the color, and
get matching colors suggested via color-wheel harmony rules (analogous,
complementary, triadic).

## Requirements

- Xcode 15 or newer
- iOS 17+ device (a real device is required — the simulator has no camera)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Generate the Xcode project

```sh
xcodegen generate
open ColorWheel.xcodeproj
```

Then pick your development team in the **Signing & Capabilities** tab and run
on a physical iPhone.

## Tests

The `ColorWheelTests` target unit-tests the two pure modules:

- `HarmonyEngineTests` — hue-rotation math, hue wrap-around.
- `ColorSamplerTests` — pixel averaging from synthetic `CVPixelBuffer`s.

Run with ⌘U or:

```sh
xcodebuild test -project ColorWheel.xcodeproj -scheme ColorWheel \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Project layout

```
ColorWheel/
├── ColorWheelApp.swift           # @main
├── ContentView.swift             # screen composition
├── Info.plist                    # NSCameraUsageDescription, etc.
├── Camera/
│   ├── CameraSession.swift       # AVCaptureSession + delegate
│   └── CameraPreviewView.swift   # UIViewRepresentable preview
├── Color/
│   ├── ColorSampler.swift        # pure: BGRA region averaging
│   ├── HarmonyEngine.swift       # pure: hue rotation math
│   └── Color+Hex.swift           # HSB ↔ UIColor / SwiftUI Color, hex
└── Views/
    ├── ReticleView.swift
    ├── SwatchRow.swift
    └── SuggestionsPanel.swift
ColorWheelTests/
├── HarmonyEngineTests.swift
└── ColorSamplerTests.swift
```

## Design

See [`docs/superpowers/specs/2026-05-24-color-wheel-design.md`](docs/superpowers/specs/2026-05-24-color-wheel-design.md).
