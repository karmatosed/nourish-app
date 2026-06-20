import Foundation
import SwiftData

@Model
final class PantryItem {
    var id: UUID = UUID()
    var name: String = ""
    var locationRaw: String = StorageLocation.pantry.rawValue
    var category: String = ""
    var createdAt: Date = Date()

    var location: StorageLocation {
        get { StorageLocation(rawValue: locationRaw) ?? .pantry }
        set { locationRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        location: StorageLocation,
        category: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.locationRaw = location.rawValue
        self.category = category
        self.createdAt = createdAt
    }
}

struct PantrySnapshot: Equatable, Sendable {
    let names: [String]

    init(items: [PantryItem]) {
        names = items.map(\.name)
    }

    init(names: [String]) {
        self.names = names
    }
}
