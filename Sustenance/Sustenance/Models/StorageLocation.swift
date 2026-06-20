import Foundation

enum StorageLocation: String, Codable, CaseIterable, Identifiable, Sendable {
    case pantry
    case fridge
    case freezer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pantry: "Pantry"
        case .fridge: "Fridge"
        case .freezer: "Freezer"
        }
    }
}
