import XCTest
@testable import ColorWheel

final class HueMapperTests: XCTestCase {

    // MARK: - RGB → Artist anchor points

    func testRgbAnchorsMapToArtistAnchors() {
        // (RGB hue, expected RYB/artist hue) per Itten's 12-color wheel.
        let cases: [(Double, Double)] = [
            (0,   0),    // red
            (60,  120),  // yellow → far around the artist wheel
            (120, 180),  // green
            (180, 210),  // cyan ≈ blue-green
            (240, 240),  // blue
            (300, 300),  // magenta → violet
            (360, 360),
        ]
        for (rgb, expected) in cases {
            XCTAssertEqual(HueMapper.rgbToArtist(rgb), expected, accuracy: 1e-9,
                           "rgb=\(rgb)")
        }
    }

    func testArtistAnchorsMapBackToRgbAnchors() {
        let cases: [(Double, Double)] = [
            (0,   0),
            (120, 60),
            (180, 120),
            (210, 180),
            (240, 240),
            (300, 300),
            (360, 360),
        ]
        for (artist, expected) in cases {
            XCTAssertEqual(HueMapper.artistToRgb(artist), expected, accuracy: 1e-9,
                           "artist=\(artist)")
        }
    }

    func testRoundTripAtSampledHues() {
        for hue in stride(from: 0.0, through: 360.0, by: 15.0) {
            let round = HueMapper.artistToRgb(HueMapper.rgbToArtist(hue))
            XCTAssertEqual(round, hue, accuracy: 1e-9, "hue=\(hue)")
        }
    }

    func testWrapsBelowZero() {
        XCTAssertEqual(HueMapper.rgbToArtist(-30), HueMapper.rgbToArtist(330), accuracy: 1e-9)
    }

    func testWrapsAboveThreeSixty() {
        XCTAssertEqual(HueMapper.rgbToArtist(390), HueMapper.rgbToArtist(30), accuracy: 1e-9)
    }
}
