import XCTest
@testable import Sustenance

final class DietPreferenceMatcherTests: XCTestCase {
    func testGlutenFreeAllowsLabeledGlutenFreeIngredients() {
        XCTAssertFalse(
            DietPreferenceMatcher.violates(ingredient: "gluten-free pasta", preferences: [.glutenFree])
        )
    }

    func testVeganFlagsEggs() {
        XCTAssertTrue(
            DietPreferenceMatcher.violates(ingredient: "eggs", preferences: [.vegan])
        )
    }

    func testVeganAllowsPlantMilks() {
        XCTAssertFalse(
            DietPreferenceMatcher.violates(ingredient: "oat milk", preferences: [.vegan])
        )
        XCTAssertFalse(
            DietPreferenceMatcher.violates(ingredient: "coconut milk", preferences: [.vegan])
        )
    }

    func testHalalFlagsHam() {
        XCTAssertTrue(
            DietPreferenceMatcher.violates(ingredient: "ham", preferences: [.halal])
        )
    }
}
