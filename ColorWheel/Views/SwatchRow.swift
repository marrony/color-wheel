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
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(hsb.color)
                .frame(width: 56, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(.black.opacity(0.08), lineWidth: 1)
                )
            Text(hsb.hexString)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.primary)
        }
    }
}
