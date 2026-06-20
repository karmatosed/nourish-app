#!/usr/bin/swift
import AppKit
import CoreImage
import Foundation

let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()

let assetsRoot = root.appendingPathComponent("Sustenance/Sustenance/Assets.xcassets")
let sourcesRoot = root.appendingPathComponent("scripts/illustration-sources")

struct IllustrationAsset {
    let folder: String
    let lightFilename: String
    let darkFilename: String
}

let assets: [IllustrationAsset] = [
    IllustrationAsset(
        folder: "WelcomeBackground.imageset",
        lightFilename: "welcome-background.png",
        darkFilename: "welcome-background-dark.png"
    ),
    IllustrationAsset(
        folder: "PlaceholderToday.imageset",
        lightFilename: "placeholder-today.png",
        darkFilename: "placeholder-today-dark.png"
    ),
    IllustrationAsset(
        folder: "PlaceholderSafeMeals.imageset",
        lightFilename: "placeholder-safe-meals.png",
        darkFilename: "placeholder-safe-meals-dark.png"
    ),
    IllustrationAsset(
        folder: "PlaceholderPantry.imageset",
        lightFilename: "placeholder-pantry.png",
        darkFilename: "placeholder-pantry-dark.png"
    ),
    IllustrationAsset(
        folder: "PlaceholderRecipes.imageset",
        lightFilename: "placeholder-recipes.png",
        darkFilename: "placeholder-recipes-dark.png"
    ),
    IllustrationAsset(
        folder: "PlaceholderSettings.imageset",
        lightFilename: "placeholder-settings.png",
        darkFilename: "placeholder-settings-dark.png"
    ),
]

let context = CIContext(options: nil)

func lineArtVariant(
    from source: CIImage,
    strokeRed: CGFloat,
    strokeGreen: CGFloat,
    strokeBlue: CGFloat
) -> CIImage? {
    let grayscale = source.applyingFilter("CIColorControls", parameters: [
        kCIInputSaturationKey: 0,
        kCIInputContrastKey: 1.08,
        kCIInputBrightnessKey: -0.02,
    ])

    let inverted = grayscale.applyingFilter("CIColorInvert")
    let mask = inverted.applyingFilter("CIMaskToAlpha")

    let strokeColor = CIImage(color: CIColor(red: strokeRed, green: strokeGreen, blue: strokeBlue, alpha: 1))
        .cropped(to: source.extent)

    return strokeColor.applyingFilter("CIBlendWithAlphaMask", parameters: [
        kCIInputMaskImageKey: mask,
    ])
}

func writePNG(_ image: CIImage, to url: URL) throws {
    guard let cgImage = context.createCGImage(image, from: image.extent) else {
        throw NSError(domain: "generate_illustration_assets", code: 1)
    }

    let rep = NSBitmapImageRep(cgImage: cgImage)
    guard let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "generate_illustration_assets", code: 2)
    }

    try png.write(to: url)
}

func contentsJSON(lightFilename: String, darkFilename: String) -> Data {
    let payload: [String: Any] = [
        "images": [
            [
                "filename": lightFilename,
                "idiom": "universal",
                "scale": "1x",
            ],
            [
                "appearances": [
                    [
                        "appearance": "luminosity",
                        "value": "dark",
                    ],
                ],
                "filename": darkFilename,
                "idiom": "universal",
                "scale": "1x",
            ],
            [
                "idiom": "universal",
                "scale": "2x",
            ],
            [
                "idiom": "universal",
                "scale": "3x",
            ],
        ],
        "info": [
            "author": "xcode",
            "version": 1,
        ],
    ]

    return try! JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
}

for asset in assets {
    let folderURL = assetsRoot.appendingPathComponent(asset.folder)
    let masterURL = sourcesRoot.appendingPathComponent(asset.lightFilename)
    let currentLightURL = folderURL.appendingPathComponent(asset.lightFilename)

    try FileManager.default.createDirectory(at: sourcesRoot, withIntermediateDirectories: true)

    if !FileManager.default.fileExists(atPath: masterURL.path) {
        try FileManager.default.copyItem(at: currentLightURL, to: masterURL)
    }

    guard let sourceImage = CIImage(contentsOf: masterURL) else {
        fputs("Could not load \(masterURL.path)\n", stderr)
        exit(1)
    }

    guard let lightOutput = lineArtVariant(
        from: sourceImage,
        strokeRed: 0.24,
        strokeGreen: 0.24,
        strokeBlue: 0.26
    ) else {
        fputs("Could not process light variant for \(masterURL.path)\n", stderr)
        exit(1)
    }

    guard let darkOutput = lineArtVariant(
        from: sourceImage,
        strokeRed: 0.78,
        strokeGreen: 0.76,
        strokeBlue: 0.72
    ) else {
        fputs("Could not process dark variant for \(masterURL.path)\n", stderr)
        exit(1)
    }

    let lightURL = folderURL.appendingPathComponent(asset.lightFilename)
    let darkURL = folderURL.appendingPathComponent(asset.darkFilename)

    try writePNG(lightOutput, to: lightURL)
    try writePNG(darkOutput, to: darkURL)
    try contentsJSON(lightFilename: asset.lightFilename, darkFilename: asset.darkFilename)
        .write(to: folderURL.appendingPathComponent("Contents.json"))

    print("Wrote \(lightURL.path)")
    print("Wrote \(darkURL.path)")
}
