#!/usr/bin/swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()

let iconDir = root
    .appendingPathComponent("Sustenance/Sustenance/Assets.xcassets/AppIcon.appiconset")

let paper = NSColor(red: 0.988, green: 0.980, blue: 0.949, alpha: 1)
let ink = NSColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 1)

struct IconEntry {
    let filename: String
    let pixelSize: Int
    let idiom: String
    let size: String
    let scale: String
}

let entries: [IconEntry] = [
    .init(filename: "Icon-Notification-40.png", pixelSize: 40, idiom: "iphone", size: "20x20", scale: "2x"),
    .init(filename: "Icon-Notification-60.png", pixelSize: 60, idiom: "iphone", size: "20x20", scale: "3x"),
    .init(filename: "Icon-Settings-58.png", pixelSize: 58, idiom: "iphone", size: "29x29", scale: "2x"),
    .init(filename: "Icon-Settings-87.png", pixelSize: 87, idiom: "iphone", size: "29x29", scale: "3x"),
    .init(filename: "Icon-Spotlight-80.png", pixelSize: 80, idiom: "iphone", size: "40x40", scale: "2x"),
    .init(filename: "Icon-Spotlight-120.png", pixelSize: 120, idiom: "iphone", size: "40x40", scale: "3x"),
    .init(filename: "Icon-App-120.png", pixelSize: 120, idiom: "iphone", size: "60x60", scale: "2x"),
    .init(filename: "Icon-App-180.png", pixelSize: 180, idiom: "iphone", size: "60x60", scale: "3x"),
    .init(filename: "Icon-Marketing-1024.png", pixelSize: 1024, idiom: "ios-marketing", size: "1024x1024", scale: "1x"),
]

func bowlPath(in rect: CGRect) -> CGPath {
    let path = CGMutablePath()
    let left = rect.minX
    let right = rect.maxX
    let rim = rect.maxY
    let bottom = rect.minY
    let depth = rect.height * 0.12

    path.move(to: CGPoint(x: left, y: rim))
    path.addLine(to: CGPoint(x: right, y: rim))
    path.addQuadCurve(
        to: CGPoint(x: rect.midX, y: bottom),
        control: CGPoint(x: right, y: bottom + depth)
    )
    path.addQuadCurve(
        to: CGPoint(x: left, y: rim),
        control: CGPoint(x: left, y: bottom + depth)
    )
    path.closeSubpath()
    return path
}

/// Dark round mark with a cream bowl cutout. Reads clearly at every icon size.
func drawIcon(in context: CGContext, size: CGFloat) {
    context.setFillColor(paper.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))

    let inset = size * 0.10
    let circle = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    context.setFillColor(ink.cgColor)
    context.fillEllipse(in: circle)

    context.setFillColor(paper.cgColor)
    let bowlRect = CGRect(
        x: size * 0.27,
        y: size * 0.34,
        width: size * 0.46,
        height: size * 0.30
    )
    context.addPath(bowlPath(in: bowlRect))
    context.fillPath()
}

func renderIcon(pixelSize: Int) -> NSBitmapImageRep? {
    let size = pixelSize
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return nil
    }

    context.translateBy(x: 0, y: CGFloat(size))
    context.scaleBy(x: 1, y: -1)
    drawIcon(in: context, size: CGFloat(size))

    guard let cgImage = context.makeImage() else { return nil }
    return NSBitmapImageRep(cgImage: cgImage)
}

func savePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "AppIcon", code: 1)
    }
    try png.write(to: url)
}

try FileManager.default.createDirectory(at: iconDir, withIntermediateDirectories: true)

var imagesJSON: [[String: String]] = []

for entry in entries {
    guard let bitmap = renderIcon(pixelSize: entry.pixelSize) else {
        fputs("Failed to render \(entry.filename)\n", stderr)
        exit(1)
    }

    let outputURL = iconDir.appendingPathComponent(entry.filename)
    try savePNG(bitmap, to: outputURL)
    print("Wrote \(outputURL.path) (\(entry.pixelSize)x\(entry.pixelSize))")

    imagesJSON.append([
        "filename": entry.filename,
        "idiom": entry.idiom,
        "scale": entry.scale,
        "size": entry.size,
    ])
}

let contents: [String: Any] = [
    "images": imagesJSON,
    "info": ["author": "xcode", "version": 1],
]

let jsonData = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try jsonData.write(to: iconDir.appendingPathComponent("Contents.json"))
print("Wrote \(iconDir.appendingPathComponent("Contents.json").path)")
