import Foundation

struct SuggestionEngine: Sendable {
    struct Configuration: Sendable {
        var safeMealBonusOnLowEnergy: Double = 30
        var comfortMealBonusOnLowEnergy: Double = 20
        var pantryMatchWeight: Double = 40
        var missingIngredientPenalty: Double = 10
        var intolerancePenalty: Double = 15
        var sensoryAvoidPenalty: Double = 10
        var energyMismatchPenalty: Double = 25
        var softEnergyMismatchPenalty: Double = 10
        var shortRecipeBonusThresholdMinutes: Int = 15
        var shortRecipeBonus: Double = 15
        var mediumRecipeBonusThresholdMinutes: Int = 30
        var mediumRecipeBonus: Double = 8
        var energyMatchBonus: Double = 12
    }

    let configuration: Configuration

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    func topSuggestions(
        from recipes: [RecipeSnapshot],
        pantry: PantrySnapshot,
        profile: SafetyProfileSnapshot,
        energyLevel: EnergyLevel,
        limit: Int = 3
    ) -> [SuggestionScore] {
        recipes
            .compactMap { score(recipe: $0, pantry: pantry, profile: profile, energyLevel: energyLevel) }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                if lhs.missingIngredientCount != rhs.missingIngredientCount {
                    return lhs.missingIngredientCount < rhs.missingIngredientCount
                }
                if lhs.prepTimeMinutes != rhs.prepTimeMinutes {
                    return lhs.prepTimeMinutes < rhs.prepTimeMinutes
                }
                return lhs.recipeTitle.localizedCaseInsensitiveCompare(rhs.recipeTitle) == .orderedAscending
            }
            .prefix(limit)
            .map { $0 }
    }

    func safeMeals(
        from recipes: [RecipeSnapshot],
        pantry: PantrySnapshot,
        profile: SafetyProfileSnapshot,
        energyLevel: EnergyLevel
    ) -> [SuggestionScore] {
        let candidates = recipes.filter { $0.isSafeMeal || $0.isComfortMeal }
        return topSuggestions(
            from: candidates,
            pantry: pantry,
            profile: profile,
            energyLevel: energyLevel,
            limit: candidates.count
        )
    }

    func score(
        recipe: RecipeSnapshot,
        pantry: PantrySnapshot,
        profile: SafetyProfileSnapshot,
        energyLevel: EnergyLevel
    ) -> SuggestionScore? {
        let classified = classifyIngredients(
            recipe: recipe,
            pantry: pantry,
            profile: profile
        )

        let unsafe = classified.filter { $0.availability == .unsafe }.map(\.name)
        if !unsafe.isEmpty {
            return nil
        }

        let caution = classified.filter { $0.availability == .caution }.map(\.name)
        let missing = classified.filter { $0.availability == .missing }.map(\.name)
        let availableCount = classified.filter { $0.availability == .available }.count

        var totalScore = 100.0

        let ingredientCount = max(recipe.ingredients.count, 1)
        let matchRatio = Double(availableCount) / Double(ingredientCount)
        totalScore += matchRatio * configuration.pantryMatchWeight
        totalScore -= Double(missing.count) * configuration.missingIngredientPenalty
        totalScore -= Double(caution.filter { ingredient in
            profile.intolerances.contains { IngredientMatcher.matchesAnyProfileTerm(ingredient: ingredient, terms: [$0]) }
        }.count) * configuration.intolerancePenalty

        let sensoryCautionCount = caution.filter { ingredient in
            profile.sensoryAvoids.contains { IngredientMatcher.matchesAnyProfileTerm(ingredient: ingredient, terms: [$0]) }
        }.count
        totalScore -= Double(sensoryCautionCount) * configuration.sensoryAvoidPenalty

        if energyLevel.canMake(recipeEnergy: recipe.requiredEnergy) {
            totalScore += configuration.energyMatchBonus
        } else if energyLevel == .low && recipe.requiredEnergy == .good {
            totalScore -= configuration.energyMismatchPenalty
        } else {
            totalScore -= configuration.softEnergyMismatchPenalty
        }

        if energyLevel == .low {
            if recipe.isSafeMeal {
                totalScore += configuration.safeMealBonusOnLowEnergy
            }
            if recipe.isComfortMeal {
                totalScore += configuration.comfortMealBonusOnLowEnergy
            }
            if recipe.prepTimeMinutes <= configuration.shortRecipeBonusThresholdMinutes {
                totalScore += configuration.shortRecipeBonus
            } else if recipe.prepTimeMinutes <= configuration.mediumRecipeBonusThresholdMinutes {
                totalScore += configuration.mediumRecipeBonus
            }
        }

        let safetyStatus: SafetyStatus = caution.isEmpty ? .safe : .caution

        return SuggestionScore(
            id: UUID(),
            recipeID: recipe.id,
            recipeTitle: recipe.title,
            score: totalScore,
            safetyStatus: safetyStatus,
            energyFit: energyLevel,
            requiredEnergy: recipe.requiredEnergy,
            prepTimeMinutes: recipe.prepTimeMinutes,
            isSafeMeal: recipe.isSafeMeal,
            isComfortMeal: recipe.isComfortMeal,
            availableIngredientCount: availableCount,
            missingIngredientCount: missing.count,
            cautionIngredientCount: caution.count,
            unsafeIngredientCount: unsafe.count,
            classifiedIngredients: classified,
            missingIngredients: missing,
            cautionIngredients: caution,
            unsafeIngredients: unsafe
        )
    }

    func classifyIngredients(
        recipe: RecipeSnapshot,
        pantry: PantrySnapshot,
        profile: SafetyProfileSnapshot
    ) -> [ClassifiedIngredient] {
        recipe.ingredients.map { ingredient in
            let availability = availability(for: ingredient.name, pantry: pantry, profile: profile)
            return ClassifiedIngredient(
                name: ingredient.name,
                quantity: ingredient.quantity,
                availability: availability
            )
        }
    }

    private func availability(
        for ingredientName: String,
        pantry: PantrySnapshot,
        profile: SafetyProfileSnapshot
    ) -> IngredientAvailability {
        if profile.allergies.contains(where: { IngredientMatcher.matchesAnyProfileTerm(ingredient: ingredientName, terms: [$0]) }) {
            return .unsafe
        }

        if DietPreferenceMatcher.violates(ingredient: ingredientName, preferences: profile.dietPreferences) {
            return .unsafe
        }

        if profile.intolerances.contains(where: { IngredientMatcher.matchesAnyProfileTerm(ingredient: ingredientName, terms: [$0]) }) {
            return .caution
        }

        if profile.sensoryAvoids.contains(where: { IngredientMatcher.matchesAnyProfileTerm(ingredient: ingredientName, terms: [$0]) }) {
            return .caution
        }

        if IngredientMatcher.isAvailable(ingredient: ingredientName, pantry: pantry) {
            return .available
        }

        return .missing
    }
}
