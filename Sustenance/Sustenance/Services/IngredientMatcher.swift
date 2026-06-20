import Foundation

enum IngredientMatcher {
    static func normalize(_ text: String) -> String {
        text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static func matches(ingredient: String, pantryItem: String) -> Bool {
        let ingredientTokens = tokenSet(for: ingredient)
        let pantryTokens = tokenSet(for: pantryItem)

        guard !ingredientTokens.isEmpty, !pantryTokens.isEmpty else { return false }

        if ingredientTokens.isSubset(of: pantryTokens) || pantryTokens.isSubset(of: ingredientTokens) {
            return true
        }

        let ingredientJoined = ingredientTokens.sorted().joined(separator: " ")
        let pantryJoined = pantryTokens.sorted().joined(separator: " ")

        return ingredientJoined.contains(pantryJoined) || pantryJoined.contains(ingredientJoined)
    }

    static func matchesAnyProfileTerm(ingredient: String, terms: [String]) -> Bool {
        let normalizedIngredient = normalize(ingredient)

        return terms.contains { term in
            let normalizedTerm = normalize(term)
            guard !normalizedTerm.isEmpty else { return false }

            if isNegatedMatch(ingredient: normalizedIngredient, term: normalizedTerm) {
                return false
            }

            return matches(ingredient: ingredient, pantryItem: normalizedTerm)
                || normalizedIngredient.contains(normalizedTerm)
                || normalizedTerm.contains(normalizedIngredient)
        }
    }

    private static func isNegatedMatch(ingredient: String, term: String) -> Bool {
        let negatedPhrases = [
            "\(term) free",
            "free \(term)",
            "no \(term)",
            "without \(term)",
        ]

        return negatedPhrases.contains { ingredient.contains($0) }
    }

    static func isAvailable(ingredient: String, pantry: PantrySnapshot) -> Bool {
        pantry.names.contains { matches(ingredient: ingredient, pantryItem: $0) }
    }

    private static func tokenSet(for text: String) -> Set<String> {
        Set(normalize(text).split(separator: " ").map(String.init))
    }
}
