import SwiftUI

enum SustenanceIllustrationStyle {
    static func opacity(for placement: MonoPlaceholderPlacement, colorScheme: ColorScheme) -> Double {
        switch colorScheme {
        case .dark:
            switch placement {
            case .screenBackdrop: return 0.38
            case .emptyState: return 0.44
            case .recipePhoto: return 0.68
            }
        default:
            switch placement {
            case .screenBackdrop: return 0.24
            case .emptyState: return 0.30
            case .recipePhoto: return 0.55
            }
        }
    }

    @ViewBuilder
    static func styled(_ content: some View, placement: MonoPlaceholderPlacement) -> some View {
        StyledIllustration(content: content, placement: placement)
    }
}

private struct StyledIllustration<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let content: Content
    let placement: MonoPlaceholderPlacement

    var body: some View {
        content
            .opacity(SustenanceIllustrationStyle.opacity(for: placement, colorScheme: colorScheme))
    }
}
