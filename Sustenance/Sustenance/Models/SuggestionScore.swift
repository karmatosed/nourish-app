import Foundation

struct SuggestionScore: Equatable, Identifiable, Sendable {
    let id: UUID
    let recipeID: UUID
    let recipeTitle: String
    let score: Double
    let safetyStatus: SafetyStatus
    let energyFit: EnergyLevel
    let requiredEnergy: EnergyLevel
    let prepTimeMinutes: Int
    let isSafeMeal: Bool
    let isComfortMeal: Bool
    let availableIngredientCount: Int
    let missingIngredientCount: Int
    let cautionIngredientCount: Int
    let unsafeIngredientCount: Int
    let classifiedIngredients: [ClassifiedIngredient]
    let missingIngredients: [String]
    let cautionIngredients: [String]
    let unsafeIngredients: [String]
}
