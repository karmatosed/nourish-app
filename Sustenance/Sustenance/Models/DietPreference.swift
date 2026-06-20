import Foundation

enum DietPreference: String, CaseIterable, Codable, Identifiable, Sendable {
    case glutenFree
    case vegan
    case vegetarian
    case halal
    case kosher
    case dairyFree

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .glutenFree: "Gluten free"
        case .vegan: "Vegan"
        case .vegetarian: "Vegetarian"
        case .halal: "Halal"
        case .kosher: "Kosher"
        case .dairyFree: "Dairy free"
        }
    }

    var caption: String {
        switch self {
        case .glutenFree: "Avoid gluten-containing grains and flours."
        case .vegan: "No animal products."
        case .vegetarian: "No meat or fish."
        case .halal: "No pork, alcohol, or non-halal meat."
        case .kosher: "No pork or shellfish."
        case .dairyFree: "No milk or dairy ingredients."
        }
    }

    var blockedTerms: [String] {
        switch self {
        case .glutenFree:
            ["gluten", "wheat", "barley", "rye", "semolina", "couscous", "bulgur", "seitan"]
        case .vegan:
            [
                "meat", "chicken", "beef", "pork", "lamb", "bacon", "ham", "fish", "salmon",
                "tuna", "shrimp", "egg", "eggs", "milk", "dairy", "butter", "cheese", "yogurt",
                "honey", "gelatin", "whey", "casein", "cream",
            ]
        case .vegetarian:
            ["meat", "chicken", "beef", "pork", "lamb", "bacon", "ham", "fish", "salmon", "tuna", "shrimp", "gelatin"]
        case .halal:
            ["pork", "bacon", "ham", "prosciutto", "lard", "alcohol", "wine", "beer", "rum", "vodka", "gelatin"]
        case .kosher:
            ["pork", "bacon", "ham", "shellfish", "shrimp", "crab", "lobster", "clam"]
        case .dairyFree:
            ["milk", "dairy", "butter", "cheese", "yogurt", "cream", "whey", "casein"]
        }
    }

    var allowedQualifiers: [String] {
        switch self {
        case .glutenFree:
            ["gluten free", "gluten-free", "no gluten"]
        case .vegan:
            [
                "vegan", "plant based", "plant-based", "plant milk",
                "oat milk", "almond milk", "soy milk", "rice milk",
                "coconut milk", "cashew milk",
            ]
        case .vegetarian:
            ["vegetarian"]
        case .halal:
            ["halal"]
        case .kosher:
            ["kosher"]
        case .dairyFree:
            ["dairy free", "dairy-free", "lactose free", "lactose-free", "no dairy"]
        }
    }

    static func from(rawValues: [String]) -> [DietPreference] {
        rawValues.compactMap(DietPreference.init(rawValue:))
    }
}

enum DietPreferenceMatcher {
    static func violates(ingredient: String, preferences: [DietPreference]) -> Bool {
        preferences.contains { preference in
            violates(ingredient: ingredient, preference: preference)
        }
    }

    static func violates(ingredient: String, preference: DietPreference) -> Bool {
        let normalizedIngredient = IngredientMatcher.normalize(ingredient)

        if preference.allowedQualifiers.contains(where: { normalizedIngredient.contains(IngredientMatcher.normalize($0)) }) {
            return false
        }

        if preference == .glutenFree {
            if normalizedIngredient.contains("gluten free") || normalizedIngredient.contains("gluten-free") {
                return false
            }
            if normalizedIngredient.contains("bread") || normalizedIngredient.contains("pasta") {
                return !normalizedIngredient.contains("free")
            }
        }

        return preference.blockedTerms.contains { term in
            IngredientMatcher.matchesAnyProfileTerm(ingredient: ingredient, terms: [term])
        }
    }
}
