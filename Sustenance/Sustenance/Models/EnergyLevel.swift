import Foundation

enum EnergyLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case low
    case okay
    case good

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: "Low"
        case .okay: "Okay"
        case .good: "Good"
        }
    }

    var sortOrder: Int {
        switch self {
        case .low: 0
        case .okay: 1
        case .good: 2
        }
    }

    func canMake(recipeEnergy: EnergyLevel) -> Bool {
        sortOrder >= recipeEnergy.sortOrder
    }
}
