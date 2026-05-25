import SwiftUI

/// A 2D hue × saturation color picker.
///
/// Angle around the wheel encodes hue (red at the top, going clockwise) and
/// distance from the center encodes saturation. The wheel's visible colors
/// are rendered at the current `saturation` and `brightness` so adjusting
/// those sliders is reflected across the whole wheel. Dragging anywhere on
/// the wheel updates hue (from angle) and saturation (from distance).
struct ColorWheelView: View {
    @Binding var hue: Double         // 0..<360
    @Binding var saturation: Double  // 0...1
    var brightness: Double           // 0...1

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            wheel(side: side)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func wheel(side: CGFloat) -> some View {
        let radius = side / 2
        return ZStack {
            background
            marker(radius: radius)
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

    /// Angular gradient of hues at the *current* saturation and brightness.
    private var background: some View {
        let stops = stride(from: 0.0, through: 360.0, by: 15.0).map { h in
            Color(hue: h / 360, saturation: saturation, brightness: brightness)
        }
        return AngularGradient(
            gradient: Gradient(colors: stops),
            center: .center,
            angle: .degrees(-90)
        )
        .mask(Circle())
    }

    /// Marker at angle = hue and distance from center = saturation × radius.
    private func marker(radius: CGFloat) -> some View {
        let angle = (hue - 90) * .pi / 180
        let r = saturation * radius
        let x = radius + CGFloat(cos(angle)) * r
        let y = radius + CGFloat(sin(angle)) * r
        return Circle()
            .strokeBorder(.white, lineWidth: 3)
            .frame(width: 22, height: 22)
            .shadow(color: .black.opacity(0.5), radius: 2)
            .position(x: x, y: y)
            .allowsHitTesting(false)
    }

    private func update(from point: CGPoint, radius: CGFloat) {
        let dx = point.x - radius
        let dy = point.y - radius
        let dist = hypot(dx, dy)
        saturation = min(1, max(0, Double(dist / radius)))

        let angleDeg = atan2(Double(dy), Double(dx)) * 180 / .pi + 90
        var newHue = angleDeg.truncatingRemainder(dividingBy: 360)
        if newHue < 0 { newHue += 360 }
        hue = newHue
    }
}
