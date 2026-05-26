import SwiftUI

/// Line styles used in the wheel-overlay legend.
fileprivate enum LegendLineStyle { case solid, dashed, dotted }

/// Modal for tweaking a sampled color. Edits a working copy; commits to the
/// caller via `onCommit` only when the user taps Done.
struct ColorEditorView: View {
    let initial: HSB
    let wheel: WheelModel
    let slices: SliceCount
    let onCommit: (HSB) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var working: HSB

    init(
        initial: HSB,
        wheel: WheelModel,
        slices: SliceCount,
        onCommit: @escaping (HSB) -> Void
    ) {
        self.initial = initial
        self.wheel = wheel
        self.slices = slices
        self.onCommit = onCommit
        self._working = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ColorWheelView(
                    hue: $working.hue,
                    saturation: $working.saturation,
                    brightness: working.brightness,
                    wheel: wheel,
                    slices: slices.value,
                    harmonies: harmonyOverlay
                )
                .frame(width: 260, height: 260)

                legend

                preview

                sliders

                Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .navigationTitle("Edit color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onCommit(working)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var harmonyOverlay: HarmonyOverlay {
        let h = HarmonyEngine.harmonies(for: working, model: wheel, slices: slices.value)
        return HarmonyOverlay(
            analogous: h.analogous,
            complementary: h.complementary,
            triadic: h.triadic
        )
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(label: "Analogous", style: .solid)
            legendItem(label: "Complementary", style: .dashed)
            legendItem(label: "Triadic", style: .dotted)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private func legendItem(label: String, style: LegendLineStyle) -> some View {
        HStack(spacing: 6) {
            LegendSwatch(style: style)
                .frame(width: 22, height: 8)
            Text(label)
        }
    }

    private var preview: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(working.color)
                .frame(width: 96, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.black.opacity(0.08), lineWidth: 1)
                )
            Text(working.hexString)
                .font(.subheadline.monospaced())
        }
    }

    /// Hue slider binding in the *visible wheel's* coordinate space, so the
    /// slider value matches the marker's angular position. When the user has
    /// enabled quantization, the slider also snaps to the nearest slice
    /// center so the marker moves in steps instead of smoothly.
    private var hueBinding: Binding<Double> {
        Binding(
            get: {
                switch wheel {
                case .digital: return working.hue
                case .artist:  return HueMapper.rgbToArtist(working.hue)
                }
            },
            set: { newDisplay in
                var snapped = newDisplay
                if let n = slices.value, n >= 2 {
                    let sliceSize = 360.0 / Double(n)
                    snapped = (snapped / sliceSize).rounded() * sliceSize
                    snapped = snapped.truncatingRemainder(dividingBy: 360)
                    if snapped < 0 { snapped += 360 }
                }
                switch wheel {
                case .digital: working.hue = snapped
                case .artist:  working.hue = HueMapper.artistToRgb(snapped)
                }
            }
        )
    }

    private var sliders: some View {
        VStack(spacing: 14) {
            sliderRow(title: "Hue",
                      value: hueBinding,
                      range: 0...360,
                      format: { String(format: "%.0f°", $0) })
            sliderRow(title: "Saturation",
                      value: $working.saturation,
                      range: 0...1,
                      format: { String(format: "%.2f", $0) })
            sliderRow(title: "Brightness",
                      value: $working.brightness,
                      range: 0...1,
                      format: { String(format: "%.2f", $0) })
        }
    }

    private func sliderRow(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        format: @escaping (Double) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(format(value.wrappedValue))
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }
}

/// Tiny line preview used in the legend so users can match a line style to
/// its harmony type.
private struct LegendSwatch: View {
    let style: LegendLineStyle

    var body: some View {
        Canvas { context, size in
            let y = size.height / 2
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            let stroke: StrokeStyle
            switch style {
            case .solid:  stroke = StrokeStyle(lineWidth: 1.5, lineCap: .round)
            case .dashed: stroke = StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 4])
            case .dotted: stroke = StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [1, 4])
            }
            context.stroke(path, with: .color(.secondary), style: stroke)
        }
    }
}
