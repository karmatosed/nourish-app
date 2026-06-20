import Foundation
import SwiftData

@Model
final class ShoppingListItem {
    var id: UUID = UUID()
    var name: String = ""
    var quantity: String = ""
    var isChecked: Bool = false
    var recipeID: UUID?
    var recipeTitle: String = ""
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        name: String,
        quantity: String = "",
        isChecked: Bool = false,
        recipeID: UUID? = nil,
        recipeTitle: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.isChecked = isChecked
        self.recipeID = recipeID
        self.recipeTitle = recipeTitle
        self.createdAt = createdAt
    }
}
