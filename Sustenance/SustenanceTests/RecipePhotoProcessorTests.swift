import UIKit
import XCTest
@testable import Sustenance

final class RecipePhotoProcessorTests: XCTestCase {
    func testProcessReturnsJPEGData() {
        let image = makeSolidImage(size: CGSize(width: 2400, height: 1800), color: .systemOrange)
        let data = RecipePhotoProcessor.process(image)

        XCTAssertNotNil(data)
        XCTAssertTrue(data?.starts(with: Data([0xFF, 0xD8, 0xFF])) ?? false)
    }

    func testProcessDownscalesLargeImages() {
        let image = makeSolidImage(size: CGSize(width: 3200, height: 2400), color: .systemTeal)
        guard
            let data = RecipePhotoProcessor.process(image),
            let processed = UIImage(data: data)
        else {
            return XCTFail("Expected processed image data")
        }

        XCTAssertLessThanOrEqual(
            max(processed.size.width * processed.scale, processed.size.height * processed.scale),
            RecipePhotoProcessor.maxDimension
        )
    }

    private func makeSolidImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
