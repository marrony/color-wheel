import SwiftUI

struct ContentView: View {
    @StateObject private var camera = CameraSession()
    @State private var sampled: HSB?

    /// Centered 10% × 10% region — matches the on-screen reticle.
    private let sampleRegion = CGRect(x: 0.45, y: 0.45, width: 0.10, height: 0.10)

    var body: some View {
        VStack(spacing: 0) {
            previewSection
                .frame(maxWidth: .infinity)
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .background(Color.black)

            SuggestionsPanel(sampled: sampled)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color(.systemBackground))
        }
        .ignoresSafeArea(edges: .top)
        .task {
            await camera.start()
        }
        .onDisappear {
            camera.stop()
        }
    }

    @ViewBuilder
    private var previewSection: some View {
        switch camera.state {
        case .running:
            ZStack {
                CameraPreviewView(session: camera.session)
                ReticleView()
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onTapGesture { sample() }
        case .denied:
            permissionDeniedView
        case .unavailable:
            unavailableView
        case .idle, .authorizing:
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.largeTitle)
                .foregroundStyle(.white)
            Text("Camera access is required.")
                .foregroundStyle(.white)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var unavailableView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.white)
            Text("No back camera available.")
                .foregroundStyle(.white)
        }
    }

    private func sample() {
        guard let buffer = camera.snapshotLatestBuffer(),
              let uiColor = ColorSampler.averageColor(in: buffer, region: sampleRegion)
        else { return }
        sampled = HSB(uiColor)
    }
}
