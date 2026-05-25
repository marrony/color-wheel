# ColorWheel

Point your iPhone's camera at a piece of cloth, sample the color, and get
matching colors suggested via color-wheel harmony rules (analogous,
complementary, triadic).

## How it works

1. Open the app — you see a "Detected" cell and three placeholder rows
   (Complementary, Analogous, Triadic) plus a **Capture color** button at
   the bottom.
2. Tap **Capture color** — the camera opens fullscreen with a centered
   reticle. Aim at the fabric and tap anywhere on the preview. The 10% × 10%
   region inside the reticle is averaged and returned as your color; the
   camera dismisses.
3. The harmony rows fill in with the matching colors, labeled by name (Red,
   Red-Orange, …, Red-Violet).
4. Tap the Detected swatch to open an editor — adjust hue, saturation, and
   brightness on a color wheel that also shows the harmony markers. Tap
   Done to commit and the suggestions recompute.

## Requirements

- Xcode 15 or newer (full Xcode, not just Command Line Tools)
- iOS 17+ device (the iOS simulator has no camera, so for actual sampling
  you need a real iPhone — but the editor flow still works in the simulator
  if you tap the empty "Detected" cell to start with white)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Generate the Xcode project

The `.xcodeproj` is not committed — XcodeGen recreates it from
[`project.yml`](project.yml):

```sh
xcodegen generate
open ColorWheel.xcodeproj
```

Re-run `xcodegen generate` after editing `project.yml`, adding files, or
cloning the repo.

## Running on a personal iPhone (no paid Apple Developer account)

Apple lets you sign apps with any regular Apple ID. Limitations: the app
expires after 7 days and you can only have ~3 free-signed apps per device.

1. Xcode → Settings → Accounts → add your Apple ID (creates a "Personal Team").
2. iPhone → Settings → Privacy & Security → **Developer Mode** → On
   (restart phone).
3. In Xcode, select the `ColorWheel` target → Signing & Capabilities → pick
   your Personal Team. The bundle id is `neris.marrony.ColorWheel`.
4. Pick your iPhone in the device dropdown, ⌘R.
5. First launch is blocked by iOS; trust the developer cert at iPhone →
   Settings → General → VPN & Device Management → your Apple ID → Trust.
   Re-run.

## Tests

```sh
xcodebuild test -project ColorWheel.xcodeproj -scheme ColorWheel \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

The test target unit-tests the pure logic modules — `HarmonyEngineTests`,
`HueMapperTests`, `ColorSamplerTests`. Camera and UI are verified manually.

## Project layout

```
ColorWheel/
├── ColorWheelApp.swift             # @main
├── ContentView.swift               # screen composition
├── Info.plist                      # NSCameraUsageDescription, etc.
├── Camera/
│   ├── CameraSession.swift         # AVCaptureSession + delegate
│   ├── CameraPreviewView.swift     # UIViewRepresentable preview
│   └── CameraCaptureView.swift     # fullscreen capture modal
├── Color/
│   ├── ColorSampler.swift          # pure: BGRA region averaging
│   ├── HarmonyEngine.swift         # pure: hue rotation + naming
│   ├── HueMapper.swift             # pure: RGB ↔ RYB hue mapping
│   └── Color+Hex.swift             # HSB ↔ UIColor / SwiftUI Color, hex
└── Views/
    ├── ReticleView.swift
    ├── SwatchRow.swift             # SwatchRow + Swatch + PlaceholderSwatch
    ├── SuggestionsPanel.swift      # Detected row + three harmony rows
    ├── ColorWheelView.swift        # circular hue/sat picker + overlays
    └── ColorEditorView.swift       # modal: wheel + preview + H/S/B sliders
ColorWheelTests/
├── HarmonyEngineTests.swift
├── HueMapperTests.swift
└── ColorSamplerTests.swift
```

## Design decisions

### Camera is gated behind a button, not always on

Earlier iterations kept a live preview on screen. We moved the camera into
a fullscreen modal that's only presented when the user taps **Capture
color**. `CameraCaptureView` owns its own `CameraSession`, started on
appear and stopped on disappear, so the camera doesn't run in the
background and battery is preserved between samples.

### Sampling: average over a region, not a single pixel

`ColorSampler.averageColor(in:region:)` averages BGRA pixels inside a
normalized rectangle of the `CVPixelBuffer`. The UI reticle and the sample
region are both 10% × 10% of the frame. Averaging smooths out fabric weave
and sensor noise far better than picking a single pixel.

### Two color wheels: digital (RGB) vs artist (RYB)

There are two color-wheel models, and they disagree on most complementary
pairs:

| Source         | Digital (RGB) complement | Artist (RYB) complement |
|----------------|--------------------------|-------------------------|
| Red            | Cyan                     | Green                   |
| Yellow         | Blue                     | **Violet**              |
| Magenta-violet | Yellow-green             | **Yellow**              |
| Blue           | Yellow                   | Orange                  |

The digital wheel is correct for additive light (screens, LEDs). The
artist's wheel is correct for **pigment/dye mixing**, which is how fabric
color behaves perceptually. For clothing/fabric matching, the artist's
wheel is what every fashion and interior-design guide uses, and what
people intuitively expect ("yellow goes with purple").

The default is `WheelModel.artist`. The toggle for switching between the
two is currently hidden in the UI — the state still exists, so it can be
re-exposed without engine changes.

#### The mapping: `HueMapper`

`HueMapper` is a piecewise-linear interpolation between the RGB and
artist hue spaces, anchored on Itten's 12-color wheel:

| RGB hue | Artist hue | Itten name      |
|---------|------------|-----------------|
| 0       | 0          | Red             |
| 60      | 120        | Yellow          |
| 120     | 180        | Green           |
| 180     | 210        | Blue-Green      |
| 240     | 240        | Blue            |
| 300     | 300        | Violet          |

`rgbToArtist` and `artistToRgb` are exact inverses on the anchors and
exact piecewise-linear inverses between them.

#### Harmony computation in artist mode

`HarmonyEngine` rotates hue in the chosen wheel's coordinate space, then
maps back to RGB for storage and display:

```
sourceArtistHue = rgbToArtist(sourceRgbHue)
complementArtistHue = (sourceArtistHue + 180) mod 360
complementRgbHue = artistToRgb(complementArtistHue)
```

Analogous (±30°) and triadic (±120°) work the same way. Saturation and
brightness are always preserved from the source.

This is the mapping fashion guides assume; the color values that come out
of the engine are the colors you'd actually use to pick coordinating
clothes.

### Wheel rendered in the chosen wheel's coordinate space

The on-screen wheel is painted so that **angle around the circle = hue
on the active wheel**, not RGB hue. In artist mode the wheel's rainbow
order is Itten's (red at top, yellow at 120°, blue at 240°), so harmony
markers land where intuition says they should — the complement is
exactly 180° opposite, the triadic forms an equilateral triangle, etc.

Crucially, this only changes *where* the wheel is drawn — the harmony
color values are computed identically to before. Same hex, same fabric
color; just a different on-screen layout. The view handles the transform
internally so `HarmonyEngine`, `Color`, and everything else stays in
standard RGB-hue space.

### Slice snapping ("12 positions on a printed wheel")

A printed art-class color wheel has 12 fixed positions (Red, Red-Orange,
Orange, … Red-Violet). `HarmonyEngine.harmonies(for:model:slices:)`
optionally snaps the source hue onto the nearest slice center on the
active wheel before rotating, so the suggestions feel like reading off a
physical wheel. Choices: Off / 6 / 12 / 24.

Currently the default is **Off** and the slice picker is hidden, because
the source-color snapping was confusing in early testing (the displayed
swatch was sometimes noticeably different from the captured one). The
plumbing is in place — `SliceCount` state lives in `ContentView` — so
the picker can be brought back without engine changes.

### Itten names instead of hex codes in the main panel

The main panel labels each swatch with its closest Itten name (Red,
Red-Orange, Orange, Yellow-Orange, Yellow, Yellow-Green, Green,
Blue-Green, Blue, Blue-Violet, Violet, Red-Violet). Hex codes are still
visible in the editor modal for precise tweaking, but for "what should I
wear" the name is more useful than `#A4324F`.

`HarmonyEngine.approximateName(for:)` maps any HSB to one of the 12
names regardless of the user's current wheel/slice settings — it's
purely for display.

### Layout: even vertical split

The main panel has four sections — Detected, Complementary, Analogous,
Triadic — each taking 1/4 of the available vertical space. All four use
the same two-column swatch layout, so the swatches line up across rows
even when a row contains only one suggestion (Complementary). Empty
rows show neutral placeholder swatches so the layout stays consistent
before a color has been sampled.

### Editor with overlay markers

Tapping the Detected swatch opens `ColorEditorView`. The wheel inside is
the same `ColorWheelView` shown elsewhere; on top of the wheel are
markers for the harmony swatches, connected to the source by lines:

- **Solid** — Analogous
- **Dashed** — Complementary
- **Dotted** — Triadic

Dragging the source marker, moving the H/S/B sliders, or changing the
wheel mode all update the overlay in real time. A legend below the wheel
matches each line style to its harmony type. The Hue slider's value is
in **wheel-degree space** so it matches the marker's visible angle.

When no color has been sampled, the empty "Detected" cell is still
tappable and seeds the editor with `HSB.white` — useful for designing a
palette without a camera or for testing in the simulator.

## Spec

A fuller design doc lives at
[`docs/superpowers/specs/2026-05-24-color-wheel-design.md`](docs/superpowers/specs/2026-05-24-color-wheel-design.md).
