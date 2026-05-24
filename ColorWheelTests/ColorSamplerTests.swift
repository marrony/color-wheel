import XCTest
import CoreVideo
@testable import ColorWheel

final class ColorSamplerTests: XCTestCase {

    func testConstantBufferReturnsThatColor() throws {
        let buffer = try makeBuffer(width: 32, height: 32, fill: (r: 200, g: 100, b: 50))
        let region = CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2)

        let color = try XCTUnwrap(ColorSampler.averageColor(in: buffer, region: region))

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(Int((r * 255).rounded()), 200)
        XCTAssertEqual(Int((g * 255).rounded()), 100)
        XCTAssertEqual(Int((b * 255).rounded()), 50)
    }

    func testFullBufferRegionAverages() throws {
        // Left half red, right half blue. Sampling whole frame averages to purple.
        let buffer = try makeSplitBuffer(width: 40, height: 20,
                                         left: (r: 255, g: 0, b: 0),
                                         right: (r: 0, g: 0, b: 255))
        let region = CGRect(x: 0, y: 0, width: 1, height: 1)
        let color = try XCTUnwrap(ColorSampler.averageColor(in: buffer, region: region))

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(Int((r * 255).rounded()), 128, accuracy: 1)
        XCTAssertEqual(Int((b * 255).rounded()), 128, accuracy: 1)
        XCTAssertEqual(Int((g * 255).rounded()), 0)
    }

    func testRegionSelectsOnlyThatHalf() throws {
        let buffer = try makeSplitBuffer(width: 40, height: 20,
                                         left: (r: 255, g: 0, b: 0),
                                         right: (r: 0, g: 0, b: 255))
        // Sample purely from the right half
        let region = CGRect(x: 0.6, y: 0, width: 0.3, height: 1)
        let color = try XCTUnwrap(ColorSampler.averageColor(in: buffer, region: region))

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(Int((r * 255).rounded()), 0)
        XCTAssertEqual(Int((b * 255).rounded()), 255)
    }

    // MARK: - Helpers

    private func makeBuffer(width: Int, height: Int, fill: (r: UInt8, g: UInt8, b: UInt8)) throws -> CVPixelBuffer {
        var pb: CVPixelBuffer?
        let attrs: CFDictionary = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        ] as CFDictionary
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, width, height,
            kCVPixelFormatType_32BGRA, attrs, &pb
        )
        XCTAssertEqual(status, kCVReturnSuccess)
        let buffer = try XCTUnwrap(pb)

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        let base = try XCTUnwrap(CVPixelBufferGetBaseAddress(buffer))
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let ptr = base.assumingMemoryBound(to: UInt8.self)

        for y in 0..<height {
            for x in 0..<width {
                let off = y * bytesPerRow + x * 4
                ptr[off + 0] = fill.b
                ptr[off + 1] = fill.g
                ptr[off + 2] = fill.r
                ptr[off + 3] = 255
            }
        }
        return buffer
    }

    private func makeSplitBuffer(
        width: Int, height: Int,
        left: (r: UInt8, g: UInt8, b: UInt8),
        right: (r: UInt8, g: UInt8, b: UInt8)
    ) throws -> CVPixelBuffer {
        var pb: CVPixelBuffer?
        let attrs: CFDictionary = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        ] as CFDictionary
        CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                            kCVPixelFormatType_32BGRA, attrs, &pb)
        let buffer = try XCTUnwrap(pb)

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        let base = try XCTUnwrap(CVPixelBufferGetBaseAddress(buffer))
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let ptr = base.assumingMemoryBound(to: UInt8.self)

        for y in 0..<height {
            for x in 0..<width {
                let off = y * bytesPerRow + x * 4
                let color = x < width / 2 ? left : right
                ptr[off + 0] = color.b
                ptr[off + 1] = color.g
                ptr[off + 2] = color.r
                ptr[off + 3] = 255
            }
        }
        return buffer
    }
}
