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
    @Binding var sampled: HSB?
    @Binding var wheel: WheelModel
    @Binding var slices: SliceCount

    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sourceRow
                .frame(maxHeight: .infinity)

            let harmonies = sampled.map {
                HarmonyEngine.harmonies(for: $0, model: wheel, slices: slices.value)
            }

            SwatchRow(
                title: "Analogous",
                colors: harmonies?.analogous ?? [],
                placeholderCount: 2
            )
            .frame(maxHeight: .infinity)

            SwatchRow(
                title: "Complementary",
                colors: harmonies?.complementary ?? [],
                placeholderCount: 1
            )
            .frame(maxHeight: .infinity)

            SwatchRow(
                title: "Triadic",
                colors: harmonies?.triadic ?? [],
                placeholderCount: 2
            )
            .frame(maxHeight: .infinity)
        }
        .sheet(isPresented: $isEditing) {
            ColorEditorView(
                initial: sampled ?? .white,
                wheel: wheel,
                slices: slices
            ) { edited in
                sampled = edited
            }
        }
    }

    @ViewBuilder
    private var sourceRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("Detected")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Image(systemName: "slider.horizontal.3")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Button {
                isEditing = true
            } label: {
                sourceContent
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var sourceContent: some View {
        if let sampled {
            let displayed = HarmonyEngine.harmonies(
                for: sampled, model: wheel, slices: slices.value
            ).source

            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(displayed.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.black.opacity(0.08), lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack(spacing: 8) {
                    Text(HarmonyEngine.approximateName(for: displayed))
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
            }
        } else {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack(spacing: 8) {
                    Text("No sample yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("· tap to pick manually")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            }
        }
    }
}
