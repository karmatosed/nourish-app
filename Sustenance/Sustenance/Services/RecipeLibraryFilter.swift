import Foundation

enum RecipeLibraryFilter {
    struct Options: Equatable {
        var searchText = ""
        var profileCompatibleOnly = true
        var safeMealsOnly = false
        var comfortMealsOnly = false
        var energyLevel: EnergyLevel?
        var maxPrepMinutes: Int?
        var availableIngredientsOnly = false
    }

    static func filtered(
        recipes: [Recipe],
        pantry: [PantryItem],
        profile: SafetyProfile?,
        options: Options,
        energyLevelForScoring: EnergyLevel = .okay
    ) -> [Recipe] {
        recipes.filter { recipe in
            matches(recipe: recipe, pantry: pantry, profile: profile, options: options, energyLevel: energyLevelForScoring)
        }
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private static func matches(
        recipe: Recipe,
        pantry: [PantryItem],
        profile: SafetyProfile?,
        options: Options,
        energyLevel: EnergyLevel
    ) -> Bool {
        if options.safeMealsOnly && !recipe.isSafeMeal { return false }
        if options.comfortMealsOnly && !recipe.isComfortMeal { return false }
        if let filterEnergy = options.energyLevel, recipe.requiredEnergy != filterEnergy { return false }
        if let maxMinutes = options.maxPrepMinutes, recipe.prepTimeMinutes > maxMinutes { return false }

        if options.profileCompatibleOnly {
            guard MealSuggestions.score(
                recipe: recipe,
                pantry: pantry,
                profile: profile,
                energyLevel: energyLevel
            ) != nil else {
                return false
            }
        }

        let query = options.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            let haystack = [
                recipe.title,
                recipe.notes,
                recipe.ingredients.map(\.name).joined(separator: " "),
            ].joined(separator: " ").lowercased()
            if !haystack.contains(query.lowercased()) { return false }
        }

        if options.availableIngredientsOnly {
            guard let score = MealSuggestions.score(
                recipe: recipe,
                pantry: pantry,
                profile: profile,
                energyLevel: energyLevel
            ) else {
                return false
            }
            if score.missingIngredientCount > 0 { return false }
        }

        return true
    }
}
