import XCTest
@testable import Sustenance

final class MarkdownRecipeParserTests: XCTestCase {
    func testParsesStandardMarkdownRecipe() throws {
        let markdown = """
        # Soft Scrambled Eggs
        Time: 10 min
        Energy: low

        ## Ingredients
        - eggs — 2
        - salt

        ## Steps
        1. Whisk eggs with salt.
        2. Cook gently and serve.

        ## Notes
        Gentle protein for low-energy days.
        """

        let parsed = try MarkdownRecipeParser.parse(markdown)

        XCTAssertEqual(parsed.title, "Soft Scrambled Eggs")
        XCTAssertEqual(parsed.prepTimeMinutes, 10)
        XCTAssertEqual(parsed.requiredEnergy, .low)
        XCTAssertEqual(parsed.ingredients.count, 2)
        XCTAssertEqual(parsed.ingredients[0].name, "eggs")
        XCTAssertEqual(parsed.ingredients[0].quantity, "2")
        XCTAssertEqual(parsed.steps.count, 2)
        XCTAssertEqual(parsed.notes, "Gentle protein for low-energy days.")
    }

    func testParsesAlternateSectionHeadings() throws {
        let markdown = """
        # Rice Bowl
        Prep: 15
        Safe: yes

        ## Directions
        - Combine rice and toppings.

        ## Ingredient
        - rice
        """

        let parsed = try MarkdownRecipeParser.parse(markdown)

        XCTAssertEqual(parsed.title, "Rice Bowl")
        XCTAssertEqual(parsed.prepTimeMinutes, 15)
        XCTAssertTrue(parsed.isSafeMeal)
        XCTAssertEqual(parsed.steps, ["Combine rice and toppings."])
    }

    func testMissingIngredientsThrows() {
        let markdown = """
        # Empty Recipe

        ## Steps
        1. Do something.
        """

        XCTAssertThrowsError(try MarkdownRecipeParser.parse(markdown)) { error in
            XCTAssertEqual(error as? MarkdownRecipeParser.ParseError, .missingIngredients)
        }
    }
}
