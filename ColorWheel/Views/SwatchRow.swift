import SwiftUI

struct SwatchRow: View {
    let title: String
    let colors: [HSB]
    /// When `colors` is empty, render this many neutral placeholder swatches
    /// so the empty state still shows where the suggestions will appear.
    var placeholderCount: Int = 0

    /// All rows reserve room for two columns so swatches line up vertically
    /// across rows even when a row has fewer than two colors (e.g.
    /// Complementary).
    private let columns = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(0..<columns, id: \.self) { i in
                    cell(at: i)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    @ViewBuilder
    private func cell(at index: Int) -> some View {
        if index < colors.count {
            Swatch(hsb: colors[index])
        } else if index < placeholderCount {
            PlaceholderSwatch()
        } else {
            Color.clear
        }
    }
}

struct Swatch: View {
    let hsb: HSB

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(hsb.color)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.black.opacity(0.08), lineWidth: 1)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text(HarmonyEngine.approximateName(for: hsb))
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

struct PlaceholderSwatch: View {
    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.gray.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.black.opacity(0.08), lineWidth: 1)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text("—")
                .font(.system(.subheadline, design: .monospaced).weight(.medium))
                .foregroundStyle(.tertiary)
        }
    }
}
