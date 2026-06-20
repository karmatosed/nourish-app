import Foundation

enum MealSuggestions {
    private static let engine = SuggestionEngine()

    static func topSuggestions(
        recipes: [Recipe],
        pantry: [PantryItem],
        profile: SafetyProfile?,
        energyLevel: EnergyLevel,
        limit: Int = 3
    ) -> [SuggestionScore] {
        engine.topSuggestions(
            from: recipes.map(RecipeSnapshot.init),
            pantry: PantrySnapshot(items: pantry),
            profile: profileSnapshot(from: profile),
            energyLevel: energyLevel,
            limit: limit
        )
    }

    static func safeMeals(
        recipes: [Recipe],
        pantry: [PantryItem],
        profile: SafetyProfile?,
        energyLevel: EnergyLevel
    ) -> [SuggestionScore] {
        engine.safeMeals(
            from: recipes.map(RecipeSnapshot.init),
            pantry: PantrySnapshot(items: pantry),
            profile: profileSnapshot(from: profile),
            energyLevel: energyLevel
        )
    }

    static func score(
        recipe: Recipe,
        pantry: [PantryItem],
        profile: SafetyProfile?,
        energyLevel: EnergyLevel
    ) -> SuggestionScore? {
        engine.score(
            recipe: RecipeSnapshot(from: recipe),
            pantry: PantrySnapshot(items: pantry),
            profile: profileSnapshot(from: profile),
            energyLevel: energyLevel
        )
    }

    private static func profileSnapshot(from profile: SafetyProfile?) -> SafetyProfileSnapshot {
        guard let profile else { return SeedData.defaultSafetyProfile }
        return SafetyProfileSnapshot(from: profile)
    }
}
