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

/// Which color wheel to compute harmonies on.
enum WheelModel: String, CaseIterable, Identifiable {
    /// Digital / RGB wheel. Complement of yellow is blue.
    case digital
    /// Artist's RYB wheel (Itten). Complement of yellow is violet.
    case artist

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .digital: return "Digital"
        case .artist:  return "Artist"
        }
    }
}

enum HarmonyEngine {
    /// Compute harmonies for `raw`.
    /// If `slices` is non-nil and ≥ 2, the source hue is first snapped to the
    /// nearest slice center on the chosen wheel — emulating a physical printed
    /// color wheel divided into N positions. `Harmonies.source` reflects the
    /// (possibly snapped) value used for computation.
    static func harmonies(
        for raw: HSB,
        model: WheelModel = .digital,
        slices: Int? = nil
    ) -> Harmonies {
        let source = snapped(raw, model: model, slices: slices)
        return Harmonies(
            source: source,
            analogous:     [rotated(source, by: -30,  model: model),
                            rotated(source, by:  30,  model: model)],
            complementary: [rotated(source, by: 180,  model: model)],
            triadic:       [rotated(source, by: -120, model: model),
                            rotated(source, by:  120, model: model)]
        )
    }

    /// Snap `source`'s hue onto the nearest slice center on the chosen wheel.
    /// No-op when `slices` is nil or < 2.
    private static func snapped(_ source: HSB, model: WheelModel, slices: Int?) -> HSB {
        guard let slices, slices >= 2 else { return source }
        let sliceSize = 360.0 / Double(slices)
        switch model {
        case .digital:
            return HSB(hue: snapHue(source.hue, sliceSize: sliceSize),
                       saturation: source.saturation, brightness: source.brightness)
        case .artist:
            let artistHue = HueMapper.rgbToArtist(source.hue)
            let snapped = snapHue(artistHue, sliceSize: sliceSize)
            return HSB(hue: HueMapper.artistToRgb(snapped),
                       saturation: source.saturation, brightness: source.brightness)
        }
    }

    /// Itten color names for the canonical 12-slice artist wheel (slice index 0…11).
    /// Returns nil for any other slicing scheme.
    static func sliceName(for source: HSB, model: WheelModel, slices: Int?) -> String? {
        guard model == .artist, slices == 12 else { return nil }
        let artistHue = HueMapper.rgbToArtist(source.hue)
        let idx = Int(((artistHue / 30).rounded())) % 12
        let names = [
            "Red", "Red-Orange", "Orange", "Yellow-Orange",
            "Yellow", "Yellow-Green", "Green", "Blue-Green",
            "Blue", "Blue-Violet", "Violet", "Red-Violet",
        ]
        return names[(idx + 12) % 12]
    }

    private static func snapHue(_ hue: Double, sliceSize: Double) -> Double {
        let idx = (hue / sliceSize).rounded()
        var snapped = (idx * sliceSize).truncatingRemainder(dividingBy: 360)
        if snapped < 0 { snapped += 360 }
        return snapped
    }

    /// Rotate `source`'s hue by `degrees` on the chosen color wheel,
    /// preserving saturation and brightness.
    private static func rotated(_ source: HSB, by degrees: Double, model: WheelModel) -> HSB {
        switch model {
        case .digital:
            return source.rotated(by: degrees)
        case .artist:
            let artistHue = HueMapper.rgbToArtist(source.hue)
            let rotated = (artistHue + degrees).truncatingRemainder(dividingBy: 360)
            let normalized = rotated < 0 ? rotated + 360 : rotated
            let backHue = HueMapper.artistToRgb(normalized)
            return HSB(hue: backHue, saturation: source.saturation, brightness: source.brightness)
        }
    }
}
