import SwiftUI

/// Optional harmony swatches drawn as markers on top of the wheel.
struct HarmonyOverlay: Equatable {
    let analogous: [HSB]
    let complementary: [HSB]
    let triadic: [HSB]
}

/// A 2D hue × saturation color picker rendered in the **selected wheel's**
/// coordinate space.
///
/// On the digital RGB wheel the angle around the circle equals RGB hue.
/// On the artist's RYB wheel the angle equals artist hue, so harmony
/// relationships (analogous, complementary, triadic) appear as the expected
/// geometric relationships on the visible wheel.
///
/// `hue` and `saturation` are bound to the model in RGB-hue space (the
/// canonical HSV representation); this view handles the transform to the
/// chosen wheel internally.
///
/// When `harmonies` is non-nil, harmony swatches are drawn as small filled
/// markers connected to the source by lines (solid = analogous,
/// dashed = complementary, dotted = triadic).
struct ColorWheelView: View {
    @Binding var hue: Double         // 0..<360 in RGB-hue space
    @Binding var saturation: Double  // 0...1
    var brightness: Double           // 0...1
    var wheel: WheelModel = .digital
    /// When non-nil and ≥ 2, the wheel is drawn as `slices` solid pie wedges
    /// instead of a smooth gradient — mimicking a printed sliced color wheel.
    var slices: Int? = nil
    var harmonies: HarmonyOverlay? = nil

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            wheelView(side: side)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func wheelView(side: CGFloat) -> some View {
        let radius = side / 2
        let sourcePoint = point(forRgbHue: hue, saturation: saturation, radius: radius)

        return ZStack {
            background

            if let harmonies {
                harmonyLines(harmonies, source: sourcePoint, radius: radius)
                harmonyMarkers(harmonies, radius: radius)
            }

            sourceMarker(at: sourcePoint)
        }
        .frame(width: side, height: side)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    update(from: value.location, radius: radius)
                }
        )
    }

    @ViewBuilder
    private var background: some View {
        if let n = slices, n >= 2 {
            slicedBackground(slices: n)
        } else {
            gradientBackground
        }
    }

    /// Smooth angular gradient covering one full wheel-degree turn.
    /// At wheel-angle θ the visible color is the RGB color whose hue maps
    /// to θ on the chosen wheel, rendered at the current sat × brightness.
    private var gradientBackground: some View {
        let stops = stride(from: 0.0, through: 360.0, by: 15.0).map { theta in
            Color(hue: rgbHue(forWheelAngle: theta) / 360,
                  saturation: saturation,
                  brightness: brightness)
        }
        return AngularGradient(
            gradient: Gradient(colors: stops),
            center: .center,
            angle: .degrees(-90)
        )
        .mask(Circle())
    }

    /// Render the wheel as `n` equal pie wedges with sharp boundaries.
    /// Each wedge is filled with the color at its center hue, so slice 0 is
    /// centered at the top (wheel-angle 0) and matches the slices that
    /// `HarmonyEngine` snaps onto.
    private func slicedBackground(slices n: Int) -> some View {
        // Local copies so the Canvas closure doesn't capture self.
        let s = saturation
        let b = brightness
        let m = wheel
        return Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            let sliceSize = 360.0 / Double(n)

            for i in 0..<n {
                // Slice i is centered on wheel-angle i*sliceSize and spans
                // half a slice on each side.
                let startWheel = Double(i) * sliceSize - sliceSize / 2
                let endWheel = startWheel + sliceSize

                var path = Path()
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startWheel - 90),  // wheel 0° → screen up
                    endAngle: .degrees(endWheel - 90),
                    clockwise: false
                )
                path.closeSubpath()

                let centerWheel = Double(i) * sliceSize
                let rgb: Double
                switch m {
                case .digital: rgb = centerWheel
                case .artist:  rgb = HueMapper.artistToRgb(centerWheel)
                }
                let color = Color(hue: rgb / 360, saturation: s, brightness: b)
                context.fill(path, with: .color(color))
            }
        }
        .mask(Circle())
    }

    private func sourceMarker(at point: CGPoint) -> some View {
        Circle()
            .strokeBorder(.white, lineWidth: 3)
            .frame(width: 22, height: 22)
            .shadow(color: .black.opacity(0.5), radius: 2)
            .position(point)
            .allowsHitTesting(false)
    }

    private func harmonyMarkers(_ harmonies: HarmonyOverlay, radius: CGFloat) -> some View {
        let all = harmonies.analogous + harmonies.complementary + harmonies.triadic
        return ZStack {
            ForEach(all.indices, id: \.self) { i in
                let hsb = all[i]
                Circle()
                    .fill(hsb.color)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                    .shadow(color: .black.opacity(0.4), radius: 1)
                    .position(point(forRgbHue: hsb.hue, saturation: hsb.saturation, radius: radius))
                    .allowsHitTesting(false)
            }
        }
    }

    private func harmonyLines(
        _ harmonies: HarmonyOverlay,
        source: CGPoint,
        radius: CGFloat
    ) -> some View {
        Canvas { context, _ in
            let lineColor = GraphicsContext.Shading.color(.white.opacity(0.75))

            for hsb in harmonies.analogous {
                var path = Path()
                path.move(to: source)
                path.addLine(to: point(forRgbHue: hsb.hue, saturation: hsb.saturation, radius: radius))
                context.stroke(path, with: lineColor, lineWidth: 1.5)
            }

            for hsb in harmonies.complementary {
                var path = Path()
                path.move(to: source)
                path.addLine(to: point(forRgbHue: hsb.hue, saturation: hsb.saturation, radius: radius))
                context.stroke(
                    path, with: lineColor,
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 4])
                )
            }

            if !harmonies.triadic.isEmpty {
                var path = Path()
                path.move(to: source)
                for hsb in harmonies.triadic {
                    path.addLine(to: point(forRgbHue: hsb.hue, saturation: hsb.saturation, radius: radius))
                }
                path.addLine(to: source)
                context.stroke(
                    path, with: lineColor,
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [1, 4])
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Coordinate transforms

    /// RGB hue → angular position on the chosen wheel.
    private func wheelAngle(forRgbHue rgbHue: Double) -> Double {
        switch wheel {
        case .digital: return rgbHue
        case .artist:  return HueMapper.rgbToArtist(rgbHue)
        }
    }

    /// Angular position on the chosen wheel → RGB hue.
    private func rgbHue(forWheelAngle angle: Double) -> Double {
        switch wheel {
        case .digital: return angle
        case .artist:  return HueMapper.artistToRgb(angle)
        }
    }

    private func point(forRgbHue rgbHue: Double, saturation: Double, radius: CGFloat) -> CGPoint {
        let theta = wheelAngle(forRgbHue: rgbHue)
        let angle = (theta - 90) * .pi / 180  // 0° at top, clockwise
        let r = CGFloat(saturation) * radius
        return CGPoint(x: radius + CGFloat(cos(angle)) * r,
                       y: radius + CGFloat(sin(angle)) * r)
    }

    private func update(from point: CGPoint, radius: CGFloat) {
        let dx = point.x - radius
        let dy = point.y - radius
        let dist = hypot(dx, dy)
        saturation = min(1, max(0, Double(dist / radius)))

        let angleDeg = atan2(Double(dy), Double(dx)) * 180 / .pi + 90
        var wheelAngle = angleDeg.truncatingRemainder(dividingBy: 360)
        if wheelAngle < 0 { wheelAngle += 360 }
        if let n = slices, n >= 2 {
            wheelAngle = snap(wheelAngle, slices: n)
        }
        hue = rgbHue(forWheelAngle: wheelAngle)
    }

    /// Snap an angle (in wheel-degrees, 0..<360) to the nearest slice center.
    private func snap(_ angle: Double, slices n: Int) -> Double {
        let sliceSize = 360.0 / Double(n)
        var snapped = (angle / sliceSize).rounded() * sliceSize
        snapped = snapped.truncatingRemainder(dividingBy: 360)
        if snapped < 0 { snapped += 360 }
        return snapped
    }
}
