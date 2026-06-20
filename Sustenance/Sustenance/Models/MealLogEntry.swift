import Foundation
import SwiftData

@Model
final class MealLogEntry {
    var id: UUID = UUID()
    var recipeID: UUID = UUID()
    var recipeTitle: String = ""
    var madeAt: Date = Date()
    var energyLevelRaw: String = EnergyLevel.okay.rawValue

    var energyLevel: EnergyLevel {
        get { EnergyLevel(rawValue: energyLevelRaw) ?? .okay }
        set { energyLevelRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        recipeID: UUID,
        recipeTitle: String,
        madeAt: Date = .now,
        energyLevel: EnergyLevel
    ) {
        self.id = id
        self.recipeID = recipeID
        self.recipeTitle = recipeTitle
        self.madeAt = madeAt
        self.energyLevelRaw = energyLevel.rawValue
    }
}

struct MealLogSnapshot: Equatable, Sendable, Identifiable {
    let id: UUID
    let recipeID: UUID
    let recipeTitle: String
    let madeAt: Date
    let energyLevel: EnergyLevel

    init(from entry: MealLogEntry) {
        id = entry.id
        recipeID = entry.recipeID
        recipeTitle = entry.recipeTitle
        madeAt = entry.madeAt
        energyLevel = entry.energyLevel
    }

    init(
        id: UUID = UUID(),
        recipeID: UUID,
        recipeTitle: String,
        madeAt: Date = .now,
        energyLevel: EnergyLevel
    ) {
        self.id = id
        self.recipeID = recipeID
        self.recipeTitle = recipeTitle
        self.madeAt = madeAt
        self.energyLevel = energyLevel
    }
}
