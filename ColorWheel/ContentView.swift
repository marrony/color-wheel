import SwiftUI

struct ContentView: View {
    @State private var saved: SavedState = .load()
    @State private var isCameraPresented = false
    @StateObject private var settings = SettingsStore()

    var body: some View {
        VStack(spacing: 0) {
            SuggestionsPanel(
                sampled: $saved.sample,
                wheel: .constant(settings.wheel),
                slices: .constant(settings.slices)
            )
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            captureButton
                .padding()
        }
        .background(Color(.systemBackground))
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraCaptureView { color in
                // Snap the captured color onto the current wheel + slice
                // settings before storing it. With Slices = Off this is a
                // no-op (returns the raw color).
                saved.sample = HarmonyEngine.snapped(
                    color,
                    model: settings.wheel,
                    slices: settings.slices.value
                )
            }
        }
        .onChange(of: saved) { _, newValue in
            newValue.save()
        }
    }

    private var captureButton: some View {
        Button {
            isCameraPresented = true
        } label: {
            Label("Capture color", systemImage: "camera.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}
