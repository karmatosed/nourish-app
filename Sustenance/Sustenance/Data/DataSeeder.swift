import Foundation
import SwiftData

enum DataSeeder {
    static func maintain(modelContext: ModelContext) {
        applyDefaultDietPreferencesIfNeeded(modelContext: modelContext)
        upgradeSampleContentIfNeeded(modelContext: modelContext)
        seedIfNeeded(modelContext: modelContext)
    }

    static func seedIfNeeded(modelContext: ModelContext) {
        guard !AppPreferences.hasSeededSampleData else { return }

        let existingRecipes = (try? modelContext.fetch(FetchDescriptor<Recipe>())) ?? []
        let existingProfiles = (try? modelContext.fetch(FetchDescriptor<SafetyProfile>())) ?? []
        if !existingRecipes.isEmpty || !existingProfiles.isEmpty {
            AppPreferences.hasSeededSampleData = true
            return
        }

        let profile = SafetyProfile.makeDefault()
        modelContext.insert(profile)

        for item in SeedData.pantryItems {
            modelContext.insert(
                PantryItem(
                    name: item.name,
                    location: item.location,
                    category: item.category
                )
            )
        }

        for recipe in SeedData.recipes {
            modelContext.insert(
                Recipe(
                    id: recipe.id,
                    title: recipe.title,
                    ingredients: recipe.ingredients,
                    steps: recipe.steps,
                    notes: recipe.notes,
                    prepTimeMinutes: recipe.prepTimeMinutes,
                    requiredEnergy: recipe.requiredEnergy,
                    isSafeMeal: recipe.isSafeMeal,
                    isComfortMeal: recipe.isComfortMeal
                )
            )
        }

        try? modelContext.save()
        AppPreferences.hasSeededSampleData = true
    }

    static func applyDefaultDietPreferencesIfNeeded(modelContext: ModelContext) {
        let profiles = (try? modelContext.fetch(FetchDescriptor<SafetyProfile>())) ?? []
        guard let profile = profiles.first else { return }

        profile.applyDefaultDietPreferencesIfNeeded()
        try? modelContext.save()
    }

    static func upgradeSampleContentIfNeeded(modelContext: ModelContext) {
        guard AppPreferences.sampleContentVersion < AppPreferences.currentSampleContentVersion else {
            pruneRecipesIncompatibleWithProfile(modelContext: modelContext)
            return
        }

        applyDefaultDietPreferencesIfNeeded(modelContext: modelContext)
        pruneRecipesIncompatibleWithProfile(modelContext: modelContext)
        pruneLegacyNonVeganPantryItems(modelContext: modelContext)

        AppPreferences.sampleContentVersion = AppPreferences.currentSampleContentVersion
        try? modelContext.save()
    }

    private static func pruneRecipesIncompatibleWithProfile(modelContext: ModelContext) {
        let profiles = (try? modelContext.fetch(FetchDescriptor<SafetyProfile>())) ?? []
        guard let profile = profiles.first else { return }

        let preferences = profile.selectedDietPreferences
        guard !preferences.isEmpty else { return }

        let recipes = (try? modelContext.fetch(FetchDescriptor<Recipe>())) ?? []
        for recipe in recipes {
            let violatesProfile = recipe.ingredients.contains { ingredient in
                DietPreferenceMatcher.violates(ingredient: ingredient.name, preferences: preferences)
            }

            if violatesProfile {
                modelContext.delete(recipe)
            }
        }
    }

    private static func pruneLegacyNonVeganPantryItems(modelContext: ModelContext) {
        let legacyNames = Set(SeedData.legacyNonVeganPantryItemNames.map { IngredientMatcher.normalize($0) })
        let items = (try? modelContext.fetch(FetchDescriptor<PantryItem>())) ?? []

        for item in items where legacyNames.contains(IngredientMatcher.normalize(item.name)) {
            modelContext.delete(item)
        }
    }
}
