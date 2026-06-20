import SwiftUI

struct IngredientGroupView: View {
    let title: String
    let ingredients: [ClassifiedIngredient]
    let availability: IngredientAvailability

    var body: some View {
        if !ingredients.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: iconName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SustenanceTheme.color(for: availability))

                ForEach(ingredients, id: \.name) { ingredient in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Circle()
                            .fill(SustenanceTheme.color(for: availability))
                            .frame(width: 6, height: 6)
                            .accessibilityHidden(true)

                        Text(ingredientLine(for: ingredient))
                            .font(.body)
                    }
                    .accessibilityLabel(ingredientLine(for: ingredient))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(SustenanceTheme.color(for: availability).opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(title) ingredients, \(ingredients.count) items")
        }
    }

    private var iconName: String {
        switch availability {
        case .available: "checkmark.circle"
        case .missing: "cart"
        case .caution: "exclamationmark.triangle"
        case .unsafe: "xmark.octagon"
        }
    }

    private func ingredientLine(for ingredient: ClassifiedIngredient) -> String {
        if let quantity = ingredient.quantity, !quantity.isEmpty {
            return "\(ingredient.name) — \(quantity)"
        }
        return ingredient.name
    }
}
