import Foundation

enum SafetyStatus: String, Codable, Sendable {
    case safe
    case caution
    case unsafe

    var displayName: String {
        switch self {
        case .safe: "Safe"
        case .caution: "Use caution"
        case .unsafe: "Not safe"
        }
    }
}

enum IngredientAvailability: String, Codable, Sendable {
    case available
    case missing
    case caution
    case unsafe

    var displayName: String {
        switch self {
        case .available: "Available"
        case .missing: "Missing"
        case .caution: "Caution"
        case .unsafe: "Unsafe"
        }
    }
}

struct ClassifiedIngredient: Equatable, Sendable {
    let name: String
    let quantity: String?
    let availability: IngredientAvailability
}
