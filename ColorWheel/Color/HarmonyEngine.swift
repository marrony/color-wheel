import Foundation

/// Hue-Saturation-Brightness color value.
/// `hue` is stored in degrees `0..<360`; `saturation` and `brightness` are `0...1`.
struct HSB: Equatable {
    var hue: Double
    var saturation: Double
    var brightness: Double

    func rotated(by degrees: Double) -> HSB {
        var newHue = (hue + degrees).truncatingRemainder(dividingBy: 360)
        if newHue < 0 { newHue += 360 }
        return HSB(hue: newHue, saturation: saturation, brightness: brightness)
    }
}

struct Harmonies: Equatable {
    let source: HSB
    let analogous: [HSB]
    let complementary: [HSB]
    let triadic: [HSB]
}

enum HarmonyEngine {
    static func harmonies(for source: HSB) -> Harmonies {
        Harmonies(
            source: source,
            analogous: [source.rotated(by: -30), source.rotated(by: 30)],
            complementary: [source.rotated(by: 180)],
            triadic: [source.rotated(by: -120), source.rotated(by: 120)]
        )
    }
}
