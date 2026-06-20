import XCTest
@testable import Sustenance

final class IngredientMatcherTests: XCTestCase {
    func testMatchesPantryItemWithDifferentSpacing() {
        XCTAssertTrue(IngredientMatcher.matches(ingredient: "canned chickpeas", pantryItem: "chickpeas"))
        XCTAssertTrue(IngredientMatcher.matches(ingredient: "gluten-free oats", pantryItem: "oats"))
    }

    func testDoesNotMatchUnrelatedItems() {
        XCTAssertFalse(IngredientMatcher.matches(ingredient: "salmon", pantryItem: "rice"))
    }

    func testNegatedTermsDoNotTriggerIntoleranceMatch() {
        XCTAssertFalse(
            IngredientMatcher.matchesAnyProfileTerm(
                ingredient: "lactose-free milk",
                terms: ["lactose"]
            )
        )
    }
}

final class SuggestionEngineTests: XCTestCase {
    private let engine = SuggestionEngine()
    private let profile = SeedData.defaultSafetyProfile
    private let pantry = PantrySnapshot(names: SeedData.pantryItems.map(\.name))

    func testExcludesRecipesWithAllergens() {
        let peanutRecipe = RecipeSnapshot(
            title: "Peanut Butter Toast",
            ingredients: [RecipeIngredient(name: "peanut butter"), RecipeIngredient(name: "bread")],
            steps: ["Spread and eat."],
            prepTimeMinutes: 5,
            requiredEnergy: .low,
            isSafeMeal: true
        )

        let suggestions = engine.topSuggestions(
            from: SeedData.recipes + [peanutRecipe],
            pantry: pantry,
            profile: profile,
            energyLevel: .low
        )

        XCTAssertFalse(suggestions.contains { $0.recipeTitle == peanutRecipe.title })
    }

    func testLowEnergyPrioritizesSafeMeals() {
        let suggestions = engine.topSuggestions(
            from: SeedData.recipes,
            pantry: pantry,
            profile: profile,
            energyLevel: .low
        )

        XCTAssertEqual(suggestions.count, 3)
        XCTAssertTrue(suggestions.allSatisfy { $0.isSafeMeal || $0.isComfortMeal || $0.prepTimeMinutes <= 20 })
        XCTAssertTrue(suggestions.filter(\.isSafeMeal).count >= 2)
    }

    func testEnergyLevelChangesRanking() {
        let low = engine.topSuggestions(
            from: SeedData.recipes,
            pantry: pantry,
            profile: profile,
            energyLevel: .low
        )
        let good = engine.topSuggestions(
            from: SeedData.recipes,
            pantry: pantry,
            profile: profile,
            energyLevel: .good
        )

        XCTAssertNotEqual(
            low.map(\.recipeTitle),
            good.map(\.recipeTitle)
        )
    }

    func testPantryContentsAffectMissingIngredientCounts() {
        let fullPantry = pantry
        let sparsePantry = PantrySnapshot(names: ["rice", "salt"])

        let full = engine.topSuggestions(
            from: SeedData.recipes,
            pantry: fullPantry,
            profile: profile,
            energyLevel: .okay
        )
        let sparse = engine.topSuggestions(
            from: SeedData.recipes,
            pantry: sparsePantry,
            profile: profile,
            energyLevel: .okay
        )

        XCTAssertLessThan(
            full.first?.missingIngredientCount ?? Int.max,
            sparse.first?.missingIngredientCount ?? 0
        )
    }

    func testIntolerancesMarkCautionButDoNotExclude() {
        let onionRecipe = RecipeSnapshot(
            title: "Onion Broth",
            ingredients: [RecipeIngredient(name: "onion"), RecipeIngredient(name: "vegetable broth")],
            steps: ["Simmer."],
            prepTimeMinutes: 15,
            requiredEnergy: .low,
            isSafeMeal: true
        )

        let score = engine.score(
            recipe: onionRecipe,
            pantry: pantry,
            profile: profile,
            energyLevel: .low
        )

        XCTAssertNotNil(score)
        XCTAssertEqual(score?.safetyStatus, .caution)
        XCTAssertTrue(score?.cautionIngredients.contains("onion") ?? false)
    }

    func testSafetyProfileChangesSuggestions() {
        let withoutOnionIntolerance = SafetyProfileSnapshot(
            allergies: profile.allergies,
            intolerances: ["lactose"],
            sensoryAvoids: profile.sensoryAvoids
        )
        let withOnionIntolerance = SafetyProfileSnapshot(
            allergies: profile.allergies,
            intolerances: ["lactose", "onion"],
            sensoryAvoids: profile.sensoryAvoids
        )

        let onionRecipe = RecipeSnapshot(
            title: "Onion Broth",
            ingredients: [
                RecipeIngredient(name: "onion"),
                RecipeIngredient(name: "vegetable broth")
            ],
            steps: ["Simmer."],
            prepTimeMinutes: 15,
            requiredEnergy: .low,
            isSafeMeal: true
        )

        let scoreWithout = engine.score(
            recipe: onionRecipe,
            pantry: pantry,
            profile: withoutOnionIntolerance,
            energyLevel: .low
        )
        let scoreWith = engine.score(
            recipe: onionRecipe,
            pantry: pantry,
            profile: withOnionIntolerance,
            energyLevel: .low
        )

        XCTAssertNotNil(scoreWithout)
        XCTAssertNotNil(scoreWith)
        XCTAssertEqual(scoreWith?.safetyStatus, .caution)
        XCTAssertGreaterThan(scoreWithout?.score ?? 0, scoreWith?.score ?? 0)
    }

    func testSafeMealsReturnsOnlyTrustedMeals() {
        let safeMeals = engine.safeMeals(
            from: SeedData.recipes,
            pantry: pantry,
            profile: profile,
            energyLevel: .low
        )

        XCTAssertFalse(safeMeals.isEmpty)
        XCTAssertTrue(safeMeals.allSatisfy { $0.isSafeMeal || $0.isComfortMeal })
    }

    func testSeedSafeMealsAreVeganCompatible() {
        let safeMealRecipes = SeedData.recipes.filter(\.isSafeMeal)

        for recipe in safeMealRecipes {
            for ingredient in recipe.ingredients {
                XCTAssertFalse(
                    DietPreferenceMatcher.violates(ingredient: ingredient.name, preferences: [.vegan]),
                    "\(recipe.title) includes non-vegan ingredient: \(ingredient.name)"
                )
            }
        }
    }

    func testClassifiesAvailableMissingAndCautionIngredients() {
        let recipe = RecipeSnapshot(
            title: "Test Bowl",
            ingredients: [
                RecipeIngredient(name: "rice"),
                RecipeIngredient(name: "lemon"),
                RecipeIngredient(name: "onion")
            ],
            steps: ["Combine."],
            prepTimeMinutes: 10,
            requiredEnergy: .low
        )

        let classified = engine.classifyIngredients(
            recipe: recipe,
            pantry: pantry,
            profile: profile
        )

        XCTAssertEqual(classified.first { $0.name == "rice" }?.availability, .available)
        XCTAssertEqual(classified.first { $0.name == "lemon" }?.availability, .missing)
        XCTAssertEqual(classified.first { $0.name == "onion" }?.availability, .caution)
    }

    func testVeganPreferenceExcludesEggRecipes() {
        let veganProfile = SafetyProfileSnapshot(
            allergies: profile.allergies,
            intolerances: profile.intolerances,
            sensoryAvoids: profile.sensoryAvoids,
            dietPreferences: [.vegan]
        )

        let eggRecipe = RecipeSnapshot(
            title: "Egg Toast",
            ingredients: [RecipeIngredient(name: "eggs"), RecipeIngredient(name: "toast")],
            steps: ["Cook."],
            prepTimeMinutes: 5,
            requiredEnergy: .low,
            isSafeMeal: true
        )

        XCTAssertNil(
            engine.score(recipe: eggRecipe, pantry: pantry, profile: veganProfile, energyLevel: .low)
        )
    }

    func testGlutenFreeAllowsGlutenFreePasta() {
        let glutenFreeProfile = SafetyProfileSnapshot(dietPreferences: [.glutenFree])

        let recipe = RecipeSnapshot(
            title: "GF Pasta Bowl",
            ingredients: [RecipeIngredient(name: "gluten-free pasta"), RecipeIngredient(name: "olive oil")],
            steps: ["Cook."],
            prepTimeMinutes: 12,
            requiredEnergy: .low
        )

        let score = engine.score(
            recipe: recipe,
            pantry: pantry,
            profile: glutenFreeProfile,
            energyLevel: .low
        )

        XCTAssertNotNil(score)
        XCTAssertEqual(score?.unsafeIngredients, [])
    }

    func testHalalPreferenceExcludesPork() {
        let halalProfile = SafetyProfileSnapshot(dietPreferences: [.halal])

        let porkRecipe = RecipeSnapshot(
            title: "Ham Sandwich",
            ingredients: [RecipeIngredient(name: "ham"), RecipeIngredient(name: "bread")],
            steps: ["Assemble."],
            prepTimeMinutes: 5,
            requiredEnergy: .low
        )

        XCTAssertNil(
            engine.score(recipe: porkRecipe, pantry: pantry, profile: halalProfile, energyLevel: .low)
        )
    }
}
