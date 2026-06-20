import UIKit

enum RecipePhotoProcessor {
    static let maxDimension: CGFloat = 1600
    static let compressionQuality: CGFloat = 0.82

    static func process(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return process(image)
    }

    static func process(_ image: UIImage) -> Data? {
        resize(image, maxDimension: maxDimension)
            .jpegData(compressionQuality: compressionQuality)
    }

    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let maxSide = max(pixelWidth, pixelHeight)
        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: pixelWidth * scale, height: pixelHeight * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
