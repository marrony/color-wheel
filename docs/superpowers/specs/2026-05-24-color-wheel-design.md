# ColorWheel — Design

An iOS app that samples a color from the camera view of a piece of cloth and suggests matching colors based on color-wheel harmony rules.

## Goals (MVP)

- Single screen.
- Live camera preview with a centered reticle showing the sampling region.
- Tap-to-sample: average the colors of pixels inside the reticle from the most recent frame.
- Display three swatch rows: Analogous, Complementary, Triadic — derived from the sampled color via HSB hue rotation.
- Hex codes shown under each swatch. Display only (no copy interaction).

## Non-goals

- Saved palettes, history, sharing/export.
- Naming colors, color-blindness filters.
- iPad-specific layouts.

## Architecture

Five small units, each with a clear responsibility:

| Unit | Responsibility |
|------|----------------|
| `CameraSession` | Owns `AVCaptureSession` + video output. Publishes auth state. Retains latest `CVPixelBuffer`. |
| `CameraPreviewView` | `UIViewRepresentable` hosting `AVCaptureVideoPreviewLayer`. Pure rendering. |
| `ColorSampler` | Pure function: `(CVPixelBuffer, normalized CGRect) -> UIColor?`. Averages BGRA pixels in the rect. |
| `HarmonyEngine` | Pure function: `Color -> HarmonyResult` with analogous/complementary/triadic colors. |
| `ContentView` | Composition: preview + reticle + tap handling + swatch panel. |

## Color harmony rules

All in HSB. Keep S and B from the source; rotate H, wrapping at 360°.

- **Analogous**: H ± 30°  → 2 colors
- **Complementary**: H + 180°  → 1 color
- **Triadic**: H ± 120°  → 2 colors

## Sampling

- Output configured for `kCVPixelFormatType_32BGRA`, late-frame discard on.
- Sample region: centered 10% × 10% rect (matches reticle).
- Average computed in sRGB (simple mean, not gamma-corrected — acceptable for solid fabric).

## Permissions

- `NSCameraUsageDescription` in Info.plist.
- On launch, request `.video` authorization.
- Denied/restricted → static "open Settings" view.
- No back camera (simulator) → static placeholder, Sample disabled.

## Testing

Unit tests for the two pure units:

- `HarmonyEngine`: known hues produce expected rotations; hue wraps below 0° and above 360°; S and B preserved.
- `ColorSampler`: synthetic constant-color `CVPixelBuffer` returns that color.

Camera and UI verified manually on device.

## Project shape

```
ColorWheel/
├── ColorWheelApp.swift
├── ContentView.swift
├── Info.plist
├── Camera/
│   ├── CameraSession.swift
│   └── CameraPreviewView.swift
├── Color/
│   ├── ColorSampler.swift
│   ├── HarmonyEngine.swift
│   └── Color+Hex.swift
└── Views/
    ├── ReticleView.swift
    ├── SwatchRow.swift
    └── SuggestionsPanel.swift
ColorWheelTests/
├── HarmonyEngineTests.swift
└── ColorSamplerTests.swift
project.yml          # XcodeGen
```

Built with `xcodegen generate` → opens in Xcode 15+.
