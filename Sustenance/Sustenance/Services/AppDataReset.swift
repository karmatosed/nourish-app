import Foundation
import SwiftData

enum AppDataReset {
    static func clearAllTestData(modelContext: ModelContext) throws {
        try deleteAll(Recipe.self, in: modelContext)
        try deleteAll(PantryItem.self, in: modelContext)
        try deleteAll(SafetyProfile.self, in: modelContext)
        try deleteAll(MealLogEntry.self, in: modelContext)
        try deleteAll(ShoppingListItem.self, in: modelContext)

        AppPreferences.clearUserDefaults()

        let profile = SafetyProfile(dietPreferences: SafetyProfile.defaultDietPreferenceRawValues)
        modelContext.insert(profile)
        try modelContext.save()
    }

    private static func deleteAll<T: PersistentModel>(
        _ type: T.Type,
        in modelContext: ModelContext
    ) throws {
        let descriptor = FetchDescriptor<T>()
        let items = try modelContext.fetch(descriptor)
        for item in items {
            modelContext.delete(item)
        }
    }
}
