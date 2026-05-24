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
}
