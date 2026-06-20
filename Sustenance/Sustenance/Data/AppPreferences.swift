import Foundation

enum AppPreferences {
    static let hasSeededSampleDataKey = "hasSeededSampleData"
    static let hasSeenFirstRunTipsKey = "hasSeenFirstRunTips"
    static let appearanceModeKey = "appearanceMode"
    static let todayEnergyLevelKey = "todayEnergyLevel"
    static let repeatMealRemindersEnabledKey = "repeatMealRemindersEnabled"
    static let dismissedRepeatReminderRecipeIDsKey = "dismissedRepeatReminderRecipeIDs"
    static let isUsingLocalStoreOnlyKey = "isUsingLocalStoreOnly"
    static let hasCustomizedDietPreferencesKey = "hasCustomizedDietPreferences"
    static let sampleContentVersionKey = "sampleContentVersion"
    static let currentSampleContentVersion = 2

    static var isUsingLocalStoreOnly: Bool {
        get { UserDefaults.standard.bool(forKey: isUsingLocalStoreOnlyKey) }
        set { UserDefaults.standard.set(newValue, forKey: isUsingLocalStoreOnlyKey) }
    }

    static var hasSeededSampleData: Bool {
        get { UserDefaults.standard.bool(forKey: hasSeededSampleDataKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasSeededSampleDataKey) }
    }

    static var hasSeenFirstRunTips: Bool {
        get { UserDefaults.standard.bool(forKey: hasSeenFirstRunTipsKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasSeenFirstRunTipsKey) }
    }

    static var hasCustomizedDietPreferences: Bool {
        get { UserDefaults.standard.bool(forKey: hasCustomizedDietPreferencesKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCustomizedDietPreferencesKey) }
    }

    static var sampleContentVersion: Int {
        get { UserDefaults.standard.integer(forKey: sampleContentVersionKey) }
        set { UserDefaults.standard.set(newValue, forKey: sampleContentVersionKey) }
    }

    static var repeatMealRemindersEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: repeatMealRemindersEnabledKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: repeatMealRemindersEnabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: repeatMealRemindersEnabledKey) }
    }

    static var dismissedRepeatReminderRecipeIDs: Set<UUID> {
        get {
            let rawValues = UserDefaults.standard.stringArray(forKey: dismissedRepeatReminderRecipeIDsKey) ?? []
            return Set(rawValues.compactMap(UUID.init(uuidString:)))
        }
        set {
            UserDefaults.standard.set(
                newValue.map(\.uuidString).sorted(),
                forKey: dismissedRepeatReminderRecipeIDsKey
            )
        }
    }

    static func dismissRepeatReminder(for recipeID: UUID) {
        var dismissed = dismissedRepeatReminderRecipeIDs
        dismissed.insert(recipeID)
        dismissedRepeatReminderRecipeIDs = dismissed
    }

    static func resetFirstRunTips() {
        hasSeenFirstRunTips = false
    }

    static func clearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: todayEnergyLevelKey)
        UserDefaults.standard.removeObject(forKey: repeatMealRemindersEnabledKey)
        UserDefaults.standard.removeObject(forKey: dismissedRepeatReminderRecipeIDsKey)
        hasCustomizedDietPreferences = false
        hasSeededSampleData = true
    }
}
