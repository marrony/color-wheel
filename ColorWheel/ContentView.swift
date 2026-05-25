import SwiftUI

struct ContentView: View {
    @State private var sampled: HSB?
    @State private var wheel: WheelModel = .artist
    @State private var slices: SliceCount = .twelve
    @State private var isCameraPresented = false

    var body: some View {
        VStack(spacing: 0) {
            SuggestionsPanel(sampled: sampled, wheel: $wheel, slices: $slices)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            captureButton
                .padding()
        }
        .background(Color(.systemBackground))
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraCaptureView { color in
                sampled = color
            }
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
