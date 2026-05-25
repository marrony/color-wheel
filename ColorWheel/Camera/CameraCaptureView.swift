import SwiftUI
import UIKit

/// Fullscreen camera UI. Owns its own `CameraSession`, so the camera only
/// runs while this view is presented. Tapping the preview samples the color
/// inside the reticle and reports it back via `onCapture`, then dismisses.
struct CameraCaptureView: View {
    @StateObject private var camera = CameraSession()
    @Environment(\.dismiss) private var dismiss

    let onCapture: (HSB) -> Void

    private let sampleRegion = CGRect(x: 0.45, y: 0.45, width: 0.10, height: 0.10)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            content

            closeButton
        }
        .task { await camera.start() }
        .onDisappear { camera.stop() }
    }

    @ViewBuilder
    private var content: some View {
        switch camera.state {
        case .running:
            ZStack {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
                ReticleView()
                    .allowsHitTesting(false)
                VStack {
                    Spacer()
                    Text("Tap to sample")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.4), in: Capsule())
                        .padding(.bottom, 40)
                }
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

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.5))
                }
                .padding()
            }
            Spacer()
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
        onCapture(HSB(uiColor))
        dismiss()
    }
}
