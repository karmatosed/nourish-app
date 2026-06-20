import SwiftUI

struct SuggestionCardView: View {
    let suggestion: SuggestionScore
    var framed: Bool = true

    private var ingredientCount: Int {
        suggestion.classifiedIngredients.count
    }

    var body: some View {
        Group {
            if framed {
                cardContent
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SustenanceTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
            } else {
                cardContent
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(suggestion.recipeTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                SafetyStatusBadge(status: suggestion.safetyStatus)
            }

            HStack(spacing: 16) {
                Label("\(suggestion.prepTimeMinutes) min", systemImage: "clock")
                Label(suggestion.requiredEnergy.displayName, systemImage: "bolt")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Label(
                    "\(suggestion.availableIngredientCount)/\(ingredientCount) in pantry",
                    systemImage: "basket"
                )

                if suggestion.missingIngredientCount > 0 {
                    Label(
                        "\(suggestion.missingIngredientCount) missing",
                        systemImage: "cart"
                    )
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if suggestion.isSafeMeal || suggestion.isComfortMeal {
                HStack(spacing: 8) {
                    if suggestion.isSafeMeal {
                        mealTag("Safe meal", systemImage: "checkmark.circle")
                    }
                    if suggestion.isComfortMeal {
                        mealTag("Comfort meal", systemImage: "heart")
                    }
                }
            }
        }
    }

    private func mealTag(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(SustenanceTheme.accent.opacity(0.08))
            .foregroundStyle(SustenanceTheme.accent)
            .clipShape(Capsule())
    }

    private var accessibilitySummary: String {
        var parts = [
            suggestion.recipeTitle,
            "\(suggestion.prepTimeMinutes) minutes",
            "Energy needed: \(suggestion.requiredEnergy.displayName)",
            suggestion.safetyStatus.displayName,
            "\(suggestion.availableIngredientCount) of \(ingredientCount) ingredients in pantry",
        ]

        if suggestion.missingIngredientCount > 0 {
            parts.append("\(suggestion.missingIngredientCount) missing ingredients")
        }

        return parts.joined(separator: ". ")
    }
}
