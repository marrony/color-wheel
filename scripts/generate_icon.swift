#!/usr/bin/env swift
//
// Generates the ColorWheel app icon as a 1024×1024 PNG.
//
// Run from the project root:
//     swift scripts/generate_icon.swift
// Writes to:
//     ColorWheel/Assets.xcassets/AppIcon.appiconset/icon-1024.png

import Foundation
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// MARK: - Configuration

let size: CGFloat = 1024
let outputPath = "ColorWheel/Assets.xcassets/AppIcon.appiconset/icon-1024.png"

// Diameter of the white "donut hole" in the center, as a fraction of `size`.
// Set to 0 to disable the hole.
let centerHoleFraction: CGFloat = 0

// Number of slices to render. Set to `nil` for a smooth gradient (the
// generator falls back to 720 thin wedges, which is visually continuous).
// Set to 6, 12, 24, etc. to mimic a printed sliced color wheel — each slice
// becomes a single solid hue at the slice's center angle.
let slices: Int? = nil

// MARK: - Render

let context = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

let center = CGPoint(x: size / 2, y: size / 2)

let wedgeCount = max(2, slices ?? 720)
let wedgeDeg = 360.0 / Double(wedgeCount)
let halfWedgeRad = (wedgeDeg / 2.0) * .pi / 180.0

for i in 0..<wedgeCount {
    let visualDeg = Double(i) * wedgeDeg
    // Hue 0 (red) should sit at the top of the icon. In a y-up CG bitmap
    // context, "top" is math angle 90°; visually clockwise corresponds to
    // decreasing math angle, so each visual degree subtracts from 90°.
    let mathCenterRad = (90.0 - visualDeg) * .pi / 180.0

    let startAngle = mathCenterRad - halfWedgeRad
    let endAngle   = mathCenterRad + halfWedgeRad

    // For sliced wheels, each wedge is uniformly filled with the hue at its
    // centerline — same convention as `HarmonyEngine.snapped` and
    // `ColorWheelView.slicedBackground`.
    let hue = visualDeg / 360.0
    let color = NSColor(hue: CGFloat(hue), saturation: 1, brightness: 1, alpha: 1)
    context.setFillColor(color.cgColor)

    context.beginPath()
    context.move(to: center)
    context.addArc(
        center: center,
        radius: size,  // overshoot to corners
        startAngle: startAngle,
        endAngle: endAngle,
        clockwise: false
    )
    context.closePath()
    context.fillPath()
}

// White center hole.
let holeRadius = size * centerHoleFraction / 2
context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
context.fillEllipse(in: CGRect(
    x: center.x - holeRadius,
    y: center.y - holeRadius,
    width: holeRadius * 2,
    height: holeRadius * 2
))

// MARK: - Save

guard let image = context.makeImage() else {
    fputs("Failed to render image\n", stderr)
    exit(1)
}

let url = URL(fileURLWithPath: outputPath)
try? FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

guard
    let dest = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    )
else {
    fputs("Failed to create image destination at \(outputPath)\n", stderr)
    exit(1)
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else {
    fputs("Failed to finalize PNG at \(outputPath)\n", stderr)
    exit(1)
}
print("Wrote \(outputPath)")
