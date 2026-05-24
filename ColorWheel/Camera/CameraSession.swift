import AVFoundation
import CoreVideo
import Foundation

@MainActor
final class CameraSession: NSObject, ObservableObject {
    enum State {
        case idle
        case authorizing
        case running
        case denied
        case unavailable
    }

    let session = AVCaptureSession()
    @Published private(set) var state: State = .idle

    private let videoOutput = AVCaptureVideoDataOutput()
    private let sampleQueue = DispatchQueue(label: "color-wheel.sample-buffer")

    /// Most recent frame. Replaced as new frames arrive.
    private var latestBuffer: CVPixelBuffer?

    func start() async {
        guard state == .idle else { return }
        state = .authorizing

        let authorized = await requestAuthorization()
        guard authorized else {
            state = .denied
            return
        }

        guard configure() else {
            state = .unavailable
            return
        }

        // startRunning is blocking; run off the main thread.
        let session = self.session
        await Task.detached { session.startRunning() }.value
        state = .running
    }

    func stop() {
        let session = self.session
        Task.detached { session.stopRunning() }
    }

    /// Snapshot the latest pixel buffer for sampling.
    func snapshotLatestBuffer() -> CVPixelBuffer? {
        latestBuffer
    }

    // MARK: - Private

    private func requestAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    private func configure() -> Bool {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video,
                                                 position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return false }

        session.addInput(input)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        ]
        videoOutput.setSampleBufferDelegate(self, queue: sampleQueue)

        guard session.canAddOutput(videoOutput) else { return false }
        session.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video),
           connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }

        return true
    }
}

extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        Task { @MainActor in
            self.latestBuffer = buffer
        }
    }
}
