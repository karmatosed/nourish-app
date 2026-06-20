import Foundation
import SwiftData

@Model
final class SafetyProfile {
    var id: UUID = UUID()
    var allergies: [String] = []
    var intolerances: [String] = []
    var sensoryAvoids: [String] = []
    var dietPreferences: [String] = []
    var defaultEnergyRaw: String?

    var defaultEnergyLevel: EnergyLevel? {
        get {
            guard let defaultEnergyRaw else { return nil }
            return EnergyLevel(rawValue: defaultEnergyRaw)
        }
        set {
            defaultEnergyRaw = newValue?.rawValue
        }
    }

    var selectedDietPreferences: [DietPreference] {
        get { DietPreference.from(rawValues: dietPreferences) }
        set { dietPreferences = newValue.map(\.rawValue) }
    }

    init(
        id: UUID = UUID(),
        allergies: [String] = [],
        intolerances: [String] = [],
        sensoryAvoids: [String] = [],
        dietPreferences: [String] = [DietPreference.vegan.rawValue],
        defaultEnergyLevel: EnergyLevel? = nil
    ) {
        self.id = id
        self.allergies = allergies
        self.intolerances = intolerances
        self.sensoryAvoids = sensoryAvoids
        self.dietPreferences = dietPreferences
        self.defaultEnergyRaw = defaultEnergyLevel?.rawValue
    }

    static let defaultDietPreferenceRawValues = [DietPreference.vegan.rawValue]

    static func makeDefault(from seed: SafetyProfileSnapshot = SeedData.defaultSafetyProfile) -> SafetyProfile {
        SafetyProfile(
            allergies: seed.allergies,
            intolerances: seed.intolerances,
            sensoryAvoids: seed.sensoryAvoids,
            dietPreferences: seed.dietPreferences.map(\.rawValue),
            defaultEnergyLevel: seed.defaultEnergyLevel
        )
    }

    func applyDefaultDietPreferencesIfNeeded() {
        guard !AppPreferences.hasCustomizedDietPreferences else { return }

        var preferences = Set(selectedDietPreferences)
        for preference in SeedData.defaultSafetyProfile.dietPreferences {
            preferences.insert(preference)
        }
        selectedDietPreferences = Array(preferences)
    }
}

struct SafetyProfileSnapshot: Equatable, Sendable {
    let allergies: [String]
    let intolerances: [String]
    let sensoryAvoids: [String]
    let dietPreferences: [DietPreference]
    let defaultEnergyLevel: EnergyLevel?

    init(from profile: SafetyProfile) {
        allergies = profile.allergies
        intolerances = profile.intolerances
        sensoryAvoids = profile.sensoryAvoids
        dietPreferences = profile.selectedDietPreferences
        defaultEnergyLevel = profile.defaultEnergyLevel
    }

    init(
        allergies: [String] = [],
        intolerances: [String] = [],
        sensoryAvoids: [String] = [],
        dietPreferences: [DietPreference] = [],
        defaultEnergyLevel: EnergyLevel? = nil
    ) {
        self.allergies = allergies
        self.intolerances = intolerances
        self.sensoryAvoids = sensoryAvoids
        self.dietPreferences = dietPreferences
        self.defaultEnergyLevel = defaultEnergyLevel
    }
}
