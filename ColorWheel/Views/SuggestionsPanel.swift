import SwiftUI

/// Slice-count choices exposed in the UI. `.off` means continuous (no snapping).
enum SliceCount: Int, Hashable, Identifiable, CaseIterable {
    case off = 0
    case six = 6
    case twelve = 12
    case twentyFour = 24

    var id: Int { rawValue }
    var displayName: String {
        self == .off ? "Off" : "\(rawValue)"
    }
    /// Value to pass to `HarmonyEngine`; nil for continuous.
    var value: Int? { self == .off ? nil : rawValue }
}

struct SuggestionsPanel: View {
    let sampled: HSB?
    @Binding var wheel: WheelModel
    @Binding var slices: SliceCount

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sourceRow

            VStack(alignment: .leading, spacing: 8) {
                Picker("Color wheel", selection: $wheel) {
                    ForEach(WheelModel.allCases) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("Slices")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker("Slices", selection: $slices) {
                        ForEach(SliceCount.allCases) { count in
                            Text(count.displayName).tag(count)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            if let sampled {
                let harmonies = HarmonyEngine.harmonies(
                    for: sampled, model: wheel, slices: slices.value
                )
                SwatchRow(title: "Analogous", colors: harmonies.analogous)
                SwatchRow(title: "Complementary", colors: harmonies.complementary)
                SwatchRow(title: "Triadic", colors: harmonies.triadic)
            } else {
                Text("Tap the preview to sample a color.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var sourceRow: some View {
        HStack(spacing: 12) {
            if let sampled {
                let displayed = HarmonyEngine.harmonies(
                    for: sampled, model: wheel, slices: slices.value
                ).source
                let name = HarmonyEngine.sliceName(for: sampled, model: wheel, slices: slices.value)

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(displayed.color)
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.black.opacity(0.08), lineWidth: 1)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Detected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Text(displayed.hexString)
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                        if let name {
                            Text(name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if slices != .off && displayed.hexString != sampled.hexString {
                        Text("raw \(sampled.hexString)")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.tertiary)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 52, height: 52)
                Text("No sample yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
