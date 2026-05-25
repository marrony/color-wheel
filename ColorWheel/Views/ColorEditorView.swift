import SwiftUI

/// Modal for tweaking a sampled color. Edits a working copy; commits to the
/// caller via `onCommit` only when the user taps Done.
struct ColorEditorView: View {
    let initial: HSB
    let onCommit: (HSB) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var working: HSB

    init(initial: HSB, onCommit: @escaping (HSB) -> Void) {
        self.initial = initial
        self.onCommit = onCommit
        self._working = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ColorWheelView(
                    hue: $working.hue,
                    saturation: $working.saturation,
                    brightness: working.brightness
                )
                .frame(width: 260, height: 260)

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

    private var sliders: some View {
        VStack(spacing: 14) {
            sliderRow(title: "Hue",
                      value: $working.hue,
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
