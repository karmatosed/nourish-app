import SwiftUI

enum SustenancePlaceholderAsset: String {
    case today = "PlaceholderToday"
    case safeMeals = "PlaceholderSafeMeals"
    case pantry = "PlaceholderPantry"
    case recipes = "PlaceholderRecipes"
    case settings = "PlaceholderSettings"
}

enum MonoPlaceholderPlacement {
    case screenBackdrop
    case emptyState
    case recipePhoto

    var maxWidth: CGFloat {
        switch self {
        case .screenBackdrop: 360
        case .emptyState: 340
        case .recipePhoto: 340
        }
    }

    var maxHeight: CGFloat {
        switch self {
        case .screenBackdrop: 360
        case .emptyState: 320
        case .recipePhoto: 320
        }
    }

    var opacity: Double {
        switch self {
        case .screenBackdrop: 0.22
        case .emptyState: 0.30
        case .recipePhoto: 0.55
        }
    }
}

enum SustenanceScreenBackgroundStyle {
    case centeredBackdrop
    case inlineHero
}

struct MonoPlaceholderImage: View {
    let asset: SustenancePlaceholderAsset
    let placement: MonoPlaceholderPlacement
    var maxWidth: CGFloat?
    var maxHeight: CGFloat?

    private var resolvedMaxWidth: CGFloat { maxWidth ?? placement.maxWidth }
    private var resolvedMaxHeight: CGFloat { maxHeight ?? placement.maxHeight }

    var body: some View {
        SustenanceIllustrationStyle.styled(
            Image(asset.rawValue)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: resolvedMaxWidth, maxHeight: resolvedMaxHeight),
            placement: placement
        )
        .accessibilityHidden(true)
    }
}

struct SustenanceScreenBackground<Content: View>: View {
    let asset: SustenancePlaceholderAsset
    var style: SustenanceScreenBackgroundStyle = .centeredBackdrop
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            if style == .centeredBackdrop {
                MonoPlaceholderImage(asset: asset, placement: .screenBackdrop)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.horizontal, 12)
                    .allowsHitTesting(false)
            }

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(SustenanceTheme.background)
    }
}

struct SustenanceInlineHero: View {
    let asset: SustenancePlaceholderAsset
    var maxWidth: CGFloat = 360
    var maxHeight: CGFloat = 360

    var body: some View {
        MonoPlaceholderImage(
            asset: asset,
            placement: .screenBackdrop,
            maxWidth: maxWidth,
            maxHeight: maxHeight
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

struct SustenanceEmptyStateView: View {
    let asset: SustenancePlaceholderAsset
    let title: String
    let message: String
    let addAccessibilityLabel: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            MonoPlaceholderImage(asset: asset, placement: .emptyState)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            SustenanceAddButton(accessibilityLabel: addAccessibilityLabel, style: .prominent, action: action)

            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SustenanceTheme.background)
    }
}
