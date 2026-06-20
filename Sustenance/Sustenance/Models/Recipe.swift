import Foundation
import SwiftData

@Model
final class Recipe {
    var id: UUID = UUID()
    var title: String = ""
    var ingredients: [RecipeIngredient] = []
    var steps: [String] = []
    var notes: String = ""
    var prepTimeMinutes: Int = 0
    var requiredEnergyRaw: String = EnergyLevel.okay.rawValue
    var isSafeMeal: Bool = false
    var isComfortMeal: Bool = false
    var createdAt: Date = Date()
    var photoData: Data?

    var requiredEnergy: EnergyLevel {
        get { EnergyLevel(rawValue: requiredEnergyRaw) ?? .okay }
        set { requiredEnergyRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        ingredients: [RecipeIngredient],
        steps: [String],
        notes: String = "",
        prepTimeMinutes: Int,
        requiredEnergy: EnergyLevel,
        isSafeMeal: Bool = false,
        isComfortMeal: Bool = false,
        createdAt: Date = .now,
        photoData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.ingredients = ingredients
        self.steps = steps
        self.notes = notes
        self.prepTimeMinutes = prepTimeMinutes
        self.requiredEnergyRaw = requiredEnergy.rawValue
        self.isSafeMeal = isSafeMeal
        self.isComfortMeal = isComfortMeal
        self.createdAt = createdAt
        self.photoData = photoData
    }
}

struct RecipeSnapshot: Equatable, Identifiable, Sendable {
    let id: UUID
    let title: String
    let ingredients: [RecipeIngredient]
    let steps: [String]
    let notes: String
    let prepTimeMinutes: Int
    let requiredEnergy: EnergyLevel
    let isSafeMeal: Bool
    let isComfortMeal: Bool

    init(from recipe: Recipe) {
        id = recipe.id
        title = recipe.title
        ingredients = recipe.ingredients
        steps = recipe.steps
        notes = recipe.notes
        prepTimeMinutes = recipe.prepTimeMinutes
        requiredEnergy = recipe.requiredEnergy
        isSafeMeal = recipe.isSafeMeal
        isComfortMeal = recipe.isComfortMeal
    }

    init(
        id: UUID = UUID(),
        title: String,
        ingredients: [RecipeIngredient],
        steps: [String],
        notes: String = "",
        prepTimeMinutes: Int,
        requiredEnergy: EnergyLevel,
        isSafeMeal: Bool = false,
        isComfortMeal: Bool = false
    ) {
        self.id = id
        self.title = title
        self.ingredients = ingredients
        self.steps = steps
        self.notes = notes
        self.prepTimeMinutes = prepTimeMinutes
        self.requiredEnergy = requiredEnergy
        self.isSafeMeal = isSafeMeal
        self.isComfortMeal = isComfortMeal
    }
}
