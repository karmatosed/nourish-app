import Foundation
import SwiftData

enum ShoppingListService {
    static func addMissingIngredients(
        from suggestion: SuggestionScore,
        recipeID: UUID,
        recipeTitle: String,
        existingItems: [ShoppingListItem],
        modelContext: ModelContext
    ) {
        let missing = suggestion.classifiedIngredients.filter { $0.availability == .missing }

        for ingredient in missing {
            let normalizedName = ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !normalizedName.isEmpty else { continue }

            let alreadyListed = existingItems.contains { item in
                !item.isChecked && item.name.lowercased() == normalizedName
            }
            guard !alreadyListed else { continue }

            modelContext.insert(
                ShoppingListItem(
                    name: ingredient.name,
                    quantity: ingredient.quantity ?? "",
                    recipeID: recipeID,
                    recipeTitle: recipeTitle
                )
            )
        }

        try? modelContext.save()
    }

    static func addItem(
        name: String,
        quantity: String = "",
        modelContext: ModelContext
    ) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        modelContext.insert(
            ShoppingListItem(name: trimmed, quantity: quantity.trimmingCharacters(in: .whitespacesAndNewlines))
        )
        try? modelContext.save()
    }
}
