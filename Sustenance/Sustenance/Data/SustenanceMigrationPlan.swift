import SwiftData

/// Legacy version markers kept for reference. The app opens the current schema
/// directly and resets the local store if an older file cannot be opened.
enum SustenanceSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Recipe.self, PantryItem.self, SafetyProfile.self, MealLogEntry.self, ShoppingListItem.self]
    }
}

enum SustenanceMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SustenanceSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
