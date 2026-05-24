import SwiftUI

struct SuggestionsPanel: View {
    let sampled: HSB?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sourceRow
            if let sampled {
                let harmonies = HarmonyEngine.harmonies(for: sampled)
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
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(sampled.color)
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.black.opacity(0.08), lineWidth: 1)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Detected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(sampled.hexString)
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                }
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 36, height: 36)
                Text("No sample yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
