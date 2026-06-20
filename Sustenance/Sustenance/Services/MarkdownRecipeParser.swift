import Foundation

struct ParsedMarkdownRecipe: Equatable, Sendable {
    var title: String
    var ingredients: [RecipeIngredient]
    var steps: [String]
    var notes: String
    var prepTimeMinutes: Int
    var requiredEnergy: EnergyLevel
    var isSafeMeal: Bool
    var isComfortMeal: Bool
}

enum MarkdownRecipeParser {
    static func parse(_ markdown: String) throws -> ParsedMarkdownRecipe {
        let lines = markdown
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard !lines.isEmpty else {
            throw ParseError.emptyDocument
        }

        var title = "Imported Recipe"
        var notes = ""
        var prepTimeMinutes = 20
        var requiredEnergy: EnergyLevel = .okay
        var isSafeMeal = false
        var isComfortMeal = false
        var ingredients: [RecipeIngredient] = []
        var steps: [String] = []

        var section: Section = .none

        for line in lines {
            if line.isEmpty { continue }

            if line.hasPrefix("# ") {
                title = String(line.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
                section = .none
                continue
            }

            if let heading = sectionHeading(for: line) {
                section = heading
                continue
            }

            if let metadata = parseMetadata(line) {
                switch metadata.key {
                case "time", "prep", "prep time":
                    prepTimeMinutes = Int(metadata.value.filter(\.isNumber)) ?? prepTimeMinutes
                case "energy":
                    requiredEnergy = EnergyLevel(rawValue: metadata.value.lowercased()) ?? requiredEnergy
                case "safe meal", "safe":
                    isSafeMeal = metadata.value.lowercased() == "yes" || metadata.value.lowercased() == "true"
                case "comfort meal", "comfort":
                    isComfortMeal = metadata.value.lowercased() == "yes" || metadata.value.lowercased() == "true"
                default:
                    break
                }
                continue
            }

            switch section {
            case .ingredients:
                if let ingredient = parseListItem(line) {
                    ingredients.append(ingredient)
                }
            case .steps:
                if let step = parseStep(line) {
                    steps.append(step)
                }
            case .notes:
                notes += line + "\n"
            case .none:
                if let ingredient = parseListItem(line), ingredients.isEmpty, !line.hasPrefix("#") {
                    ingredients.append(ingredient)
                }
            }
        }

        title = title.isEmpty ? "Imported Recipe" : title
        notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !ingredients.isEmpty else { throw ParseError.missingIngredients }
        guard !steps.isEmpty else { throw ParseError.missingSteps }

        return ParsedMarkdownRecipe(
            title: title,
            ingredients: ingredients,
            steps: steps,
            notes: notes,
            prepTimeMinutes: max(prepTimeMinutes, 1),
            requiredEnergy: requiredEnergy,
            isSafeMeal: isSafeMeal,
            isComfortMeal: isComfortMeal
        )
    }

    enum ParseError: LocalizedError {
        case emptyDocument
        case missingIngredients
        case missingSteps

        var errorDescription: String? {
            switch self {
            case .emptyDocument: "The file is empty."
            case .missingIngredients: "No ingredients found. Add an ## Ingredients section."
            case .missingSteps: "No steps found. Add a ## Steps section."
            }
        }
    }

    private enum Section {
        case none
        case ingredients
        case steps
        case notes
    }

    private static func sectionHeading(for line: String) -> Section? {
        let normalized = line.trimmingCharacters(in: CharacterSet(charactersIn: "#")).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "ingredients", "ingredient": return .ingredients
        case "steps", "directions", "method": return .steps
        case "notes", "note": return .notes
        default: return nil
        }
    }

    private static func parseMetadata(_ line: String) -> (key: String, value: String)? {
        let parts = line.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        guard parts.count == 2 else { return nil }
        return (parts[0].lowercased(), parts[1])
    }

    private static func parseListItem(_ line: String) -> RecipeIngredient? {
        var content = line
        if content.hasPrefix("- ") { content = String(content.dropFirst(2)) }
        else if content.hasPrefix("* ") { content = String(content.dropFirst(2)) }
        else if let match = content.firstMatch(of: /^\d+\.\s+/) { content.removeSubrange(match.range) }

        content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return nil }

        if let dashRange = content.range(of: " — ") ?? content.range(of: " - ") {
            let name = String(content[..<dashRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let quantity = String(content[dashRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return RecipeIngredient(name: name, quantity: quantity.isEmpty ? nil : quantity)
        }

        return RecipeIngredient(name: content)
    }

    private static func parseStep(_ line: String) -> String? {
        var content = line
        if content.hasPrefix("- ") || content.hasPrefix("* ") {
            content = String(content.dropFirst(2))
        } else if let match = content.firstMatch(of: /^\d+\.\s+/) {
            content.removeSubrange(match.range)
        }

        content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return content.isEmpty ? nil : content
    }
}
