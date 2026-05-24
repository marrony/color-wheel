import XCTest
@testable import ColorWheel

final class HarmonyEngineTests: XCTestCase {

    func testAnalogousIsHuePlusAndMinusThirty() {
        let source = HSB(hue: 100, saturation: 0.5, brightness: 0.6)
        let result = HarmonyEngine.harmonies(for: source)
        XCTAssertEqual(result.analogous.map(\.hue), [70, 130])
    }

    func testComplementaryIsHuePlusOneEighty() {
        let source = HSB(hue: 40, saturation: 0.4, brightness: 0.8)
        let result = HarmonyEngine.harmonies(for: source)
        XCTAssertEqual(result.complementary.map(\.hue), [220])
    }

    func testTriadicIsHuePlusAndMinusOneTwenty() {
        let source = HSB(hue: 200, saturation: 0.3, brightness: 0.9)
        let result = HarmonyEngine.harmonies(for: source)
        XCTAssertEqual(result.triadic.map(\.hue), [80, 320])
    }

    func testHueWrapsBelowZero() {
        let source = HSB(hue: 10, saturation: 0.5, brightness: 0.5)
        let result = HarmonyEngine.harmonies(for: source)
        // -30 from 10 should wrap to 340
        XCTAssertEqual(result.analogous[0].hue, 340)
    }

    func testHueWrapsAboveThreeSixty() {
        let source = HSB(hue: 350, saturation: 0.5, brightness: 0.5)
        let result = HarmonyEngine.harmonies(for: source)
        // +30 from 350 should wrap to 20
        XCTAssertEqual(result.analogous[1].hue, 20)
    }

    func testSaturationAndBrightnessArePreserved() {
        let source = HSB(hue: 123, saturation: 0.42, brightness: 0.77)
        let result = HarmonyEngine.harmonies(for: source)
        let all = result.analogous + result.complementary + result.triadic
        for color in all {
            XCTAssertEqual(color.saturation, 0.42, accuracy: 1e-9)
            XCTAssertEqual(color.brightness, 0.77, accuracy: 1e-9)
        }
    }

    func testRedSourceProducesCanonicalRotations() {
        // Red = hue 0
        let red = HSB(hue: 0, saturation: 1, brightness: 1)
        let result = HarmonyEngine.harmonies(for: red)
        XCTAssertEqual(result.analogous.map(\.hue), [330, 30])
        XCTAssertEqual(result.complementary.map(\.hue), [180])    // cyan
        XCTAssertEqual(result.triadic.map(\.hue), [240, 120])     // blue, green
    }

    // MARK: - Artist (RYB) wheel

    func testArtistComplementOfYellowIsViolet() {
        let yellow = HSB(hue: 60, saturation: 1, brightness: 1)
        let result = HarmonyEngine.harmonies(for: yellow, model: .artist)
        // Yellow ↔ Violet on Itten's wheel; violet ≈ RGB 300°.
        XCTAssertEqual(result.complementary[0].hue, 300, accuracy: 1e-6)
    }

    func testArtistComplementOfRedIsGreen() {
        let red = HSB(hue: 0, saturation: 1, brightness: 1)
        let result = HarmonyEngine.harmonies(for: red, model: .artist)
        // Red ↔ Green on the artist's wheel; green ≈ RGB 120°.
        XCTAssertEqual(result.complementary[0].hue, 120, accuracy: 1e-6)
    }

    func testArtistComplementOfBlueIsOrange() {
        let blue = HSB(hue: 240, saturation: 1, brightness: 1)
        let result = HarmonyEngine.harmonies(for: blue, model: .artist)
        // Blue ↔ Orange; orange ≈ RGB 30°.
        XCTAssertEqual(result.complementary[0].hue, 30, accuracy: 1e-6)
    }

    func testArtistComplementOfSampledMagentaIsYellow() {
        // #B610EC ≈ RGB hue 285° (magenta-violet).
        // Expected artist-wheel complement: a yellow around RGB 52.5°.
        let magenta = HSB(hue: 285, saturation: 0.93, brightness: 0.93)
        let result = HarmonyEngine.harmonies(for: magenta, model: .artist)
        XCTAssertEqual(result.complementary[0].hue, 52.5, accuracy: 1e-6)
    }

    func testArtistTriadicOfYellowIsRedAndBlue() {
        let yellow = HSB(hue: 60, saturation: 1, brightness: 1)
        let result = HarmonyEngine.harmonies(for: yellow, model: .artist)
        // Y/R/B form the classic triadic on the artist's wheel.
        XCTAssertEqual(result.triadic[0].hue, 0,   accuracy: 1e-6)   // red
        XCTAssertEqual(result.triadic[1].hue, 240, accuracy: 1e-6)   // blue
    }

    // MARK: - Slice snapping

    func testNilSlicesIsNoOp() {
        let source = HSB(hue: 285, saturation: 0.93, brightness: 0.93)
        let result = HarmonyEngine.harmonies(for: source, model: .artist, slices: nil)
        XCTAssertEqual(result.source.hue, 285, accuracy: 1e-9)
    }

    func testTwelveSlicesArtistSnapsMagentaVioletToViolet() {
        // RGB hue 285° → artist hue 285° → snap to 300° → RGB 300° (violet).
        let source = HSB(hue: 285, saturation: 0.93, brightness: 0.93)
        let result = HarmonyEngine.harmonies(for: source, model: .artist, slices: 12)
        XCTAssertEqual(result.source.hue, 300, accuracy: 1e-6)
        // Complement of violet (artist 300°) is yellow (artist 120° → RGB 60°).
        XCTAssertEqual(result.complementary[0].hue, 60, accuracy: 1e-6)
    }

    func testTwelveSlicesArtistSnapsNearYellowToYellow() {
        // RGB 55° (close to pure yellow) → artist ~110° → snap to 120° (yellow).
        let source = HSB(hue: 55, saturation: 1, brightness: 1)
        let result = HarmonyEngine.harmonies(for: source, model: .artist, slices: 12)
        XCTAssertEqual(result.source.hue, 60, accuracy: 1e-6)
    }

    func testSixSlicesArtistSnapsToPrimaryOrSecondary() {
        // RGB 25° → artist 50° → 6-slice (60° each) snaps to 60° → RGB 30° (orange).
        let source = HSB(hue: 25, saturation: 1, brightness: 1)
        let result = HarmonyEngine.harmonies(for: source, model: .artist, slices: 6)
        XCTAssertEqual(result.source.hue, 30, accuracy: 1e-6)
    }

    func testDigitalSliceSnapping() {
        // 12-slice digital wheel snaps directly in RGB degrees.
        let source = HSB(hue: 95, saturation: 1, brightness: 1)
        let result = HarmonyEngine.harmonies(for: source, model: .digital, slices: 12)
        XCTAssertEqual(result.source.hue, 90, accuracy: 1e-9)
    }

    func testSliceNameForTwelveSliceArtistWheel() {
        let violet = HSB(hue: 300, saturation: 1, brightness: 1)
        XCTAssertEqual(HarmonyEngine.sliceName(for: violet, model: .artist, slices: 12), "Violet")

        let yellow = HSB(hue: 60, saturation: 1, brightness: 1)
        XCTAssertEqual(HarmonyEngine.sliceName(for: yellow, model: .artist, slices: 12), "Yellow")

        let red = HSB(hue: 0, saturation: 1, brightness: 1)
        XCTAssertEqual(HarmonyEngine.sliceName(for: red, model: .artist, slices: 12), "Red")
    }

    func testSliceNameIsNilForNonStandardConfigs() {
        let any = HSB(hue: 100, saturation: 1, brightness: 1)
        XCTAssertNil(HarmonyEngine.sliceName(for: any, model: .artist, slices: 6))
        XCTAssertNil(HarmonyEngine.sliceName(for: any, model: .artist, slices: nil))
        XCTAssertNil(HarmonyEngine.sliceName(for: any, model: .digital, slices: 12))
    }

    func testArtistModePreservesSaturationAndBrightness() {
        let source = HSB(hue: 200, saturation: 0.7, brightness: 0.4)
        let result = HarmonyEngine.harmonies(for: source, model: .artist)
        let all = result.analogous + result.complementary + result.triadic
        for color in all {
            XCTAssertEqual(color.saturation, 0.7, accuracy: 1e-9)
            XCTAssertEqual(color.brightness, 0.4, accuracy: 1e-9)
        }
    }
}
