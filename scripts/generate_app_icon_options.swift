#!/usr/bin/swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()

let outputDir = root.appendingPathComponent("docs/icon-options")

let paper = NSColor(red: 0.988, green: 0.980, blue: 0.949, alpha: 1)
let ink = NSColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 1)

struct OptionSpec {
    let id: String
    let title: String
    let subtitle: String
    let draw: (CGContext, CGFloat) -> Void
}

func simpleBowlPath(in rect: CGRect) -> CGPath {
    let path = CGMutablePath()
    let left = rect.minX
    let right = rect.maxX
    let rim = rect.maxY
    let bottom = rect.minY

    path.move(to: CGPoint(x: left, y: rim))
    path.addLine(to: CGPoint(x: right, y: rim))
    path.addCurve(
        to: CGPoint(x: left, y: rim),
        control1: CGPoint(x: right, y: bottom),
        control2: CGPoint(x: left, y: bottom)
    )
    path.closeSubpath()
    return path
}

let options: [OptionSpec] = [
    OptionSpec(
        id: "A-solid-bowl",
        title: "Solid bowl",
        subtitle: "Default app icon. One filled shape on cream paper."
    ) { context, size in
        context.setFillColor(ink.cgColor)
        let bowl = simpleBowlPath(in: CGRect(x: size * 0.20, y: size * 0.30, width: size * 0.60, height: size * 0.42))
        context.addPath(bowl)
        context.fillPath()
    },
    OptionSpec(
        id: "B-round-mark",
        title: "Round mark",
        subtitle: "Dark circle with cream bowl cutout."
    ) { context, size in
        let inset = size * 0.12
        let circle = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
        context.setFillColor(ink.cgColor)
        context.fillEllipse(in: circle)

        context.setFillColor(paper.cgColor)
        let bowl = simpleBowlPath(in: CGRect(x: size * 0.26, y: size * 0.34, width: size * 0.48, height: size * 0.32))
        context.addPath(bowl)
        context.fillPath()
    },
    OptionSpec(
        id: "C-stroke-bowl",
        title: "Stroke bowl",
        subtitle: "Single thick outline, no fill."
    ) { context, size in
        context.setStrokeColor(ink.cgColor)
        context.setLineWidth(size * 0.09)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        let bowl = simpleBowlPath(in: CGRect(x: size * 0.22, y: size * 0.32, width: size * 0.56, height: size * 0.38))
        context.addPath(bowl)
        context.strokePath()
    },
]

func renderIcon(option: OptionSpec, size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    context.setFillColor(paper.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))

    context.translateBy(x: 0, y: CGFloat(size))
    context.scaleBy(x: 1, y: -1)

    option.draw(context, CGFloat(size))

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "IconOptions", code: 1)
    }
    try png.write(to: url)
}

try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

var markdown = "# Sustenance app icon options\n\nThe app currently uses **Solid bowl**.\n\n"

for option in options {
    let previewURL = outputDir.appendingPathComponent("\(option.id)-1024.png")
    let image = renderIcon(option: option, size: 1024)
    try savePNG(image, to: previewURL)

    for small in [180, 60] {
        let smallURL = outputDir.appendingPathComponent("\(option.id)-\(small).png")
        try savePNG(renderIcon(option: option, size: small), to: smallURL)
    }

    print("Wrote \(previewURL.path)")
    markdown += "## \(option.title)\n\n"
    markdown += "**\(option.subtitle)**\n\n"
    markdown += "![\(option.title)](\(option.id)-1024.png)\n\n"
    markdown += "Small preview (60pt):\n\n"
    markdown += "![\(option.title) small](\(option.id)-60.png)\n\n"
}

try markdown.write(to: outputDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
print("Wrote \(outputDir.appendingPathComponent("README.md").path)")
