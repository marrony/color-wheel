import SwiftUI

struct SwatchRow: View {
    let title: String
    let colors: [HSB]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                ForEach(Array(colors.enumerated()), id: \.offset) { _, hsb in
                    Swatch(hsb: hsb)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct Swatch: View {
    let hsb: HSB

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(hsb.color)
                .frame(width: 80, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.black.opacity(0.08), lineWidth: 1)
                )
            Text(hsb.hexString)
                .font(.system(.footnote, design: .monospaced).weight(.medium))
                .foregroundStyle(.primary)
        }
    }
}
