import CoreVideo
import UIKit

enum ColorSampler {
    /// Average sRGB color of the pixels inside `region`.
    /// `region` is in normalized image coordinates (`0...1` x and y).
    /// Returns `nil` if the pixel buffer isn't BGRA or the region is empty.
    static func averageColor(in pixelBuffer: CVPixelBuffer, region: CGRect) -> UIColor? {
        guard CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32BGRA else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }

        let xStart = max(0, Int((region.minX * CGFloat(width)).rounded(.down)))
        let yStart = max(0, Int((region.minY * CGFloat(height)).rounded(.down)))
        let xEnd = min(width, Int((region.maxX * CGFloat(width)).rounded(.up)))
        let yEnd = min(height, Int((region.maxY * CGFloat(height)).rounded(.up)))
        guard xEnd > xStart, yEnd > yStart else { return nil }

        let ptr = base.assumingMemoryBound(to: UInt8.self)
        var rSum: UInt64 = 0
        var gSum: UInt64 = 0
        var bSum: UInt64 = 0
        var count: UInt64 = 0

        for y in yStart..<yEnd {
            let rowOffset = y * bytesPerRow
            for x in xStart..<xEnd {
                let off = rowOffset + x * 4
                bSum &+= UInt64(ptr[off + 0])
                gSum &+= UInt64(ptr[off + 1])
                rSum &+= UInt64(ptr[off + 2])
                count &+= 1
            }
        }

        guard count > 0 else { return nil }

        return UIColor(
            red: CGFloat(rSum) / CGFloat(count) / 255,
            green: CGFloat(gSum) / CGFloat(count) / 255,
            blue: CGFloat(bSum) / CGFloat(count) / 255,
            alpha: 1
        )
    }
}
