import Foundation

struct RecipeIngredient: Codable, Hashable, Sendable {
    var name: String
    var quantity: String?

    init(name: String, quantity: String? = nil) {
        self.name = name
        self.quantity = quantity
    }
}
