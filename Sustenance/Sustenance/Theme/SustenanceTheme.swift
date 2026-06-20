import SwiftUI

struct AdaptiveThemeColor: ShapeStyle {
    let light: (CGFloat, CGFloat, CGFloat)
    let dark: (CGFloat, CGFloat, CGFloat)
    var opacity: Double = 1

    func opacity(_ value: Double) -> AdaptiveThemeColor {
        AdaptiveThemeColor(light: light, dark: dark, opacity: value)
    }

    func resolve(in environment: EnvironmentValues) -> Color {
        let rgb = environment.colorScheme == .dark ? dark : light
        return Color(red: rgb.0, green: rgb.1, blue: rgb.2, opacity: opacity)
    }
}

enum SustenanceTheme {
    static let background = adaptiveColor(
        light: (0.988, 0.980, 0.949),
        dark: (0.11, 0.11, 0.12)
    )
    static let cardBackground = adaptiveColor(
        light: (1.0, 1.0, 1.0),
        dark: (0.17, 0.17, 0.18)
    )
    static let accent = adaptiveColor(
        light: (0.15, 0.15, 0.16),
        dark: (0.90, 0.88, 0.84)
    )
    static let selectedLabelOnAccent = adaptiveColor(
        light: (1.0, 1.0, 1.0),
        dark: (0.11, 0.11, 0.12)
    )
    static let safe = adaptiveColor(
        light: (0.24, 0.24, 0.26),
        dark: (0.78, 0.78, 0.80)
    )
    static let caution = adaptiveColor(
        light: (0.46, 0.46, 0.48),
        dark: (0.58, 0.58, 0.62)
    )
    static let unsafe = adaptiveColor(
        light: (0.09, 0.09, 0.10),
        dark: (0.92, 0.92, 0.94)
    )
    static let border = adaptiveColor(
        light: (0.84, 0.84, 0.85),
        dark: (0.32, 0.32, 0.34)
    )

    static func color(for status: SafetyStatus) -> AdaptiveThemeColor {
        switch status {
        case .safe: safe
        case .caution: caution
        case .unsafe: unsafe
        }
    }

    static func color(for availability: IngredientAvailability) -> AdaptiveThemeColor {
        switch availability {
        case .available: safe
        case .missing: border
        case .caution: caution
        case .unsafe: unsafe
        }
    }

    private static func adaptiveColor(
        light: (CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat)
    ) -> AdaptiveThemeColor {
        AdaptiveThemeColor(light: light, dark: dark)
    }
}

struct AdaptiveThemeBackground: View {
    let color: AdaptiveThemeColor

    var body: some View {
        Rectangle().fill(color)
    }
}
