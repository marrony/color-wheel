import Foundation

/// Maps hues between the digital **RGB** color wheel (red 0°, yellow 60°,
/// green 120°, cyan 180°, blue 240°, magenta 300°) and the artist's **RYB**
/// color wheel (red 0°, yellow 120°, green 180°, blue 240°, violet 300°).
///
/// Mapping is piecewise-linear between the anchor points below — based on the
/// classical 12-color Itten wheel. Good enough for harmony rotation; not a
/// perceptually-accurate color appearance model.
enum HueMapper {
    private static let rgbToArtistAnchors: [(rgb: Double, artist: Double)] = [
        (0,   0),    // red
        (60,  120),  // yellow
        (120, 180),  // green
        (180, 210),  // cyan ≈ blue-green
        (240, 240),  // blue
        (300, 300),  // magenta ≈ violet
        (360, 360),
    ]

    static func rgbToArtist(_ hue: Double) -> Double {
        interpolate(normalize(hue), table: rgbToArtistAnchors.map { ($0.rgb, $0.artist) })
    }

    static func artistToRgb(_ hue: Double) -> Double {
        interpolate(normalize(hue), table: rgbToArtistAnchors.map { ($0.artist, $0.rgb) })
    }

    // MARK: - Private

    private static func normalize(_ hue: Double) -> Double {
        var h = hue.truncatingRemainder(dividingBy: 360)
        if h < 0 { h += 360 }
        return h
    }

    private static func interpolate(_ x: Double, table: [(Double, Double)]) -> Double {
        for i in 0..<(table.count - 1) {
            let (x0, y0) = table[i]
            let (x1, y1) = table[i + 1]
            if x >= x0 && x <= x1 {
                if x1 == x0 { return y0 }
                let t = (x - x0) / (x1 - x0)
                return y0 + t * (y1 - y0)
            }
        }
        return x
    }
}
