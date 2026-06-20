import SwiftUI
import UIKit

private struct RecipePhotoPlaceholder: View {
    var body: some View {
        SustenanceIllustrationStyle.styled(
            Image(SustenancePlaceholderAsset.recipes.rawValue)
                .resizable()
                .scaledToFill(),
            placement: .recipePhoto
        )
        .accessibilityLabel("Recipe illustration")
    }
}

struct RecipePhotoView: View {
    let photoData: Data?
    var height: CGFloat = 220
    var cornerRadius: CGFloat = 16

    var body: some View {
        Group {
            if let photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .accessibilityLabel("Recipe photo")
            } else {
                RecipePhotoPlaceholder()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(SustenanceTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct RecipePhotoThumbnail: View {
    let photoData: Data?
    var size: CGFloat = 52

    var body: some View {
        Group {
            if let photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .accessibilityLabel("Recipe photo")
            } else {
                RecipePhotoPlaceholder()
            }
        }
        .frame(width: size, height: size)
        .background(SustenanceTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(SustenanceTheme.border, lineWidth: 1)
        }
    }
}
