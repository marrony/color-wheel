import AVFoundation
import CoreVideo
import Foundation

// AVFoundation hasn't been audited for Swift 6 Sendable yet, but
// `AVCaptureSession` is reference-counted and documented as safe for the
// operations we use (`startRunning` / `stopRunning` from a background queue,
// configuration from a single owner). The `@unchecked` form lets us send the
// session into detached tasks without crossing an actor boundary.
extension AVCaptureSession: @retroactive @unchecked Sendable {}

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
    nonisolated private let sampleQueue = DispatchQueue(label: "color-wheel.sample-buffer")

    /// Most recent frame. Touched by both the background sample-buffer
    /// delegate and the main thread; the lock serialises access. We use
    /// `nonisolated(unsafe)` plus an explicit `NSLock` instead of crossing an
    /// actor boundary because `CVPixelBuffer` isn't `Sendable`.
    nonisolated private let bufferLock = NSLock()
    nonisolated(unsafe) private var _latestBuffer: CVPixelBuffer?

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

    /// Snapshot the latest pixel buffer for sampling. Safe to call from any
    /// context; the lock serialises against the capture-output delegate.
    nonisolated func snapshotLatestBuffer() -> CVPixelBuffer? {
        bufferLock.withLock { _latestBuffer }
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
           connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }

        return true
    }
}

extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        bufferLock.withLock { _latestBuffer = buffer }
    }
}
