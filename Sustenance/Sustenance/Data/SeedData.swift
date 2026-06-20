import Foundation

enum SeedData {
    static let legacyNonVeganPantryItemNames = [
        "eggs",
        "chicken broth",
        "frozen salmon fillet",
        "lactose-free milk",
        "lactose-free yogurt",
    ]

    static let defaultSafetyProfile = SafetyProfileSnapshot(
        allergies: ["peanut", "shellfish"],
        intolerances: ["lactose", "onion"],
        sensoryAvoids: ["mushroom", "slimy texture"],
        dietPreferences: [.vegan],
        defaultEnergyLevel: .okay
    )

    static let pantryItems: [(name: String, location: StorageLocation, category: String)] = [
        ("rice", .pantry, "Grains"),
        ("gluten-free pasta", .pantry, "Grains"),
        ("olive oil", .pantry, "Oils"),
        ("salt", .pantry, "Spices"),
        ("black pepper", .pantry, "Spices"),
        ("canned chickpeas", .pantry, "Legumes"),
        ("red lentils", .pantry, "Legumes"),
        ("gluten-free oats", .pantry, "Grains"),
        ("maple syrup", .pantry, "Sweeteners"),
        ("oat milk", .pantry, "Plant milk"),
        ("vegetable broth", .pantry, "Broth"),
        ("firm tofu", .fridge, "Protein"),
        ("tahini", .pantry, "Spreads"),
        ("coconut milk", .pantry, "Canned"),
        ("tomato passata", .pantry, "Canned"),
        ("spinach", .fridge, "Produce"),
        ("carrots", .fridge, "Produce"),
        ("cucumber", .fridge, "Produce"),
        ("bell pepper", .fridge, "Produce"),
        ("frozen peas", .freezer, "Frozen"),
        ("frozen berries", .freezer, "Frozen"),
    ]

    static let recipes: [RecipeSnapshot] = [
        RecipeSnapshot(
            title: "Soft Tofu Scramble on Toast",
            ingredients: [
                RecipeIngredient(name: "firm tofu", quantity: "1/2 block"),
                RecipeIngredient(name: "olive oil", quantity: "1 tsp"),
                RecipeIngredient(name: "gluten-free bread", quantity: "1 slice"),
                RecipeIngredient(name: "salt"),
                RecipeIngredient(name: "black pepper")
            ],
            steps: [
                "Crumble tofu and warm gently in oil with salt and pepper.",
                "Cook over low heat until heated through.",
                "Serve on warmed toast."
            ],
            notes: "Gentle protein when chewing feels like effort.",
            prepTimeMinutes: 10,
            requiredEnergy: .low,
            isSafeMeal: true,
            isComfortMeal: true
        ),
        RecipeSnapshot(
            title: "Creamy Oats with Berries",
            ingredients: [
                RecipeIngredient(name: "gluten-free oats", quantity: "1/2 cup"),
                RecipeIngredient(name: "oat milk", quantity: "1 cup"),
                RecipeIngredient(name: "frozen berries", quantity: "1/2 cup"),
                RecipeIngredient(name: "maple syrup", quantity: "1 tsp"),
                RecipeIngredient(name: "salt", quantity: "pinch")
            ],
            steps: [
                "Simmer oats with milk and salt until soft.",
                "Warm berries separately or stir in at the end.",
                "Sweeten lightly if wanted."
            ],
            notes: "Warm, predictable, and easy to eat.",
            prepTimeMinutes: 12,
            requiredEnergy: .low,
            isSafeMeal: true,
            isComfortMeal: true
        ),
        RecipeSnapshot(
            title: "Plain Rice Bowl",
            ingredients: [
                RecipeIngredient(name: "rice", quantity: "1/2 cup dry"),
                RecipeIngredient(name: "olive oil", quantity: "1 tsp"),
                RecipeIngredient(name: "salt")
            ],
            steps: [
                "Cook rice until tender.",
                "Finish with a little oil and salt.",
                "Eat as-is or add what you have."
            ],
            notes: "A neutral base when everything else feels like too much.",
            prepTimeMinutes: 20,
            requiredEnergy: .low,
            isSafeMeal: true,
            isComfortMeal: false
        ),
        RecipeSnapshot(
            title: "Chickpea Tomato Stew",
            ingredients: [
                RecipeIngredient(name: "canned chickpeas", quantity: "1 can"),
                RecipeIngredient(name: "tomato passata", quantity: "1 cup"),
                RecipeIngredient(name: "olive oil", quantity: "1 tbsp"),
                RecipeIngredient(name: "spinach", quantity: "1 cup"),
                RecipeIngredient(name: "salt"),
                RecipeIngredient(name: "black pepper")
            ],
            steps: [
                "Warm passata with oil, salt, and pepper.",
                "Add drained chickpeas and simmer 10 minutes.",
                "Stir in spinach until wilted."
            ],
            notes: "One pot, pantry-friendly, filling.",
            prepTimeMinutes: 20,
            requiredEnergy: .okay,
            isSafeMeal: false,
            isComfortMeal: true
        ),
        RecipeSnapshot(
            title: "Red Lentil Soup",
            ingredients: [
                RecipeIngredient(name: "red lentils", quantity: "1/2 cup"),
                RecipeIngredient(name: "carrots", quantity: "1"),
                RecipeIngredient(name: "vegetable broth", quantity: "2 cups"),
                RecipeIngredient(name: "olive oil", quantity: "1 tsp"),
                RecipeIngredient(name: "salt"),
                RecipeIngredient(name: "black pepper")
            ],
            steps: [
                "Sauté chopped carrots in oil.",
                "Add lentils and broth, simmer until soft.",
                "Season and blend if preferred."
            ],
            notes: "Soft texture, good for low-appetite days.",
            prepTimeMinutes: 25,
            requiredEnergy: .okay,
            isSafeMeal: true,
            isComfortMeal: true
        ),
        RecipeSnapshot(
            title: "Cucumber Tahini Bowl",
            ingredients: [
                RecipeIngredient(name: "tahini", quantity: "2 tbsp"),
                RecipeIngredient(name: "cucumber", quantity: "1/2"),
                RecipeIngredient(name: "lemon juice", quantity: "1 tbsp"),
                RecipeIngredient(name: "oat milk", quantity: "2 tbsp"),
                RecipeIngredient(name: "salt"),
                RecipeIngredient(name: "black pepper")
            ],
            steps: [
                "Dice cucumber.",
                "Whisk tahini with oat milk, lemon, salt, and pepper until smooth.",
                "Stir in cucumber and serve chilled."
            ],
            notes: "Cool and light when hot food feels heavy.",
            prepTimeMinutes: 8,
            requiredEnergy: .low,
            isSafeMeal: true,
            isComfortMeal: false
        ),
        RecipeSnapshot(
            title: "Pasta with Olive Oil and Peas",
            ingredients: [
                RecipeIngredient(name: "gluten-free pasta", quantity: "2 oz"),
                RecipeIngredient(name: "olive oil", quantity: "2 tbsp"),
                RecipeIngredient(name: "frozen peas", quantity: "1/2 cup"),
                RecipeIngredient(name: "salt"),
                RecipeIngredient(name: "black pepper")
            ],
            steps: [
                "Cook pasta until tender.",
                "Toss with warmed peas, oil, salt, and pepper."
            ],
            notes: "Minimal chopping, familiar comfort.",
            prepTimeMinutes: 15,
            requiredEnergy: .low,
            isSafeMeal: false,
            isComfortMeal: true
        ),
        RecipeSnapshot(
            title: "Coconut Carrot Soup",
            ingredients: [
                RecipeIngredient(name: "carrots", quantity: "2"),
                RecipeIngredient(name: "coconut milk", quantity: "1 cup"),
                RecipeIngredient(name: "vegetable broth", quantity: "1 cup"),
                RecipeIngredient(name: "olive oil", quantity: "1 tsp"),
                RecipeIngredient(name: "ginger", quantity: "1 tsp"),
                RecipeIngredient(name: "salt")
            ],
            steps: [
                "Cook carrots in oil until soft.",
                "Add broth, coconut milk, and ginger.",
                "Simmer and blend until smooth."
            ],
            notes: "Smooth and gentle on the stomach.",
            prepTimeMinutes: 30,
            requiredEnergy: .okay,
            isSafeMeal: false,
            isComfortMeal: true
        ),
        RecipeSnapshot(
            title: "Bell Pepper Rice Skillet",
            ingredients: [
                RecipeIngredient(name: "rice", quantity: "1/2 cup dry"),
                RecipeIngredient(name: "bell pepper", quantity: "1"),
                RecipeIngredient(name: "olive oil", quantity: "1 tbsp"),
                RecipeIngredient(name: "tomato passata", quantity: "1/2 cup"),
                RecipeIngredient(name: "salt"),
                RecipeIngredient(name: "black pepper")
            ],
            steps: [
                "Cook rice until nearly done.",
                "Sauté chopped pepper in oil.",
                "Combine with passata, season, and finish cooking."
            ],
            notes: "Colorful but still straightforward.",
            prepTimeMinutes: 25,
            requiredEnergy: .good,
            isSafeMeal: false,
            isComfortMeal: false
        ),
        RecipeSnapshot(
            title: "Berry Oat Parfait",
            ingredients: [
                RecipeIngredient(name: "oat milk", quantity: "1/2 cup"),
                RecipeIngredient(name: "frozen berries", quantity: "1/2 cup"),
                RecipeIngredient(name: "gluten-free oats", quantity: "2 tbsp"),
                RecipeIngredient(name: "maple syrup", quantity: "1 tsp")
            ],
            steps: [
                "Layer oats, berries, and oat milk in a bowl.",
                "Drizzle with maple syrup if wanted."
            ],
            notes: "No cooking required.",
            prepTimeMinutes: 5,
            requiredEnergy: .low,
            isSafeMeal: true,
            isComfortMeal: true
        ),
        RecipeSnapshot(
            title: "Spinach Chickpea Scramble",
            ingredients: [
                RecipeIngredient(name: "canned chickpeas", quantity: "1/2 can"),
                RecipeIngredient(name: "spinach", quantity: "1 cup"),
                RecipeIngredient(name: "olive oil", quantity: "1 tsp"),
                RecipeIngredient(name: "salt"),
                RecipeIngredient(name: "black pepper")
            ],
            steps: [
                "Mash chickpeas lightly.",
                "Warm spinach in oil, then add chickpeas and heat through.",
                "Season and serve."
            ],
            notes: "Quick protein and greens without much chewing.",
            prepTimeMinutes: 10,
            requiredEnergy: .low,
            isSafeMeal: true,
            isComfortMeal: false
        ),
        RecipeSnapshot(
            title: "Pea and Carrot Mash",
            ingredients: [
                RecipeIngredient(name: "frozen peas", quantity: "1 cup"),
                RecipeIngredient(name: "carrots", quantity: "2"),
                RecipeIngredient(name: "olive oil", quantity: "1 tbsp"),
                RecipeIngredient(name: "salt"),
                RecipeIngredient(name: "black pepper")
            ],
            steps: [
                "Boil carrots until very soft.",
                "Warm peas, then mash together with oil and seasoning."
            ],
            notes: "Soft texture, low chewing effort.",
            prepTimeMinutes: 20,
            requiredEnergy: .low,
            isSafeMeal: true,
            isComfortMeal: true
        ),
        RecipeSnapshot(
            title: "Onion-Free Chickpea Salad",
            ingredients: [
                RecipeIngredient(name: "canned chickpeas", quantity: "1 can"),
                RecipeIngredient(name: "cucumber", quantity: "1/2"),
                RecipeIngredient(name: "olive oil", quantity: "1 tbsp"),
                RecipeIngredient(name: "lemon juice", quantity: "1 tbsp"),
                RecipeIngredient(name: "salt"),
                RecipeIngredient(name: "black pepper")
            ],
            steps: [
                "Rinse chickpeas and dice cucumber.",
                "Toss with oil, lemon, salt, and pepper."
            ],
            notes: "No cook, keeps well in the fridge.",
            prepTimeMinutes: 10,
            requiredEnergy: .okay,
            isSafeMeal: false,
            isComfortMeal: false
        )
    ]
}
