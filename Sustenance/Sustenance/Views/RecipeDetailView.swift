import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var matchingRecipes: [Recipe]
    @Query(sort: \PantryItem.name) private var pantryItems: [PantryItem]
    @Query private var profiles: [SafetyProfile]
    @Query(sort: \ShoppingListItem.createdAt, order: .reverse) private var shoppingListItems: [ShoppingListItem]

    let energyLevel: EnergyLevel

    @State private var didAddToList = false
    @State private var editorMode: RecipeEditorView.Mode?

    init(recipeID: UUID, energyLevel: EnergyLevel) {
        self.energyLevel = energyLevel
        let id = recipeID
        _matchingRecipes = Query(filter: #Predicate<Recipe> { recipe in
            recipe.id == id
        })
    }

    private var recipe: Recipe? {
        matchingRecipes.first
    }

    private var suggestion: SuggestionScore? {
        guard let recipe else { return nil }
        return MealSuggestions.score(
            recipe: recipe,
            pantry: pantryItems,
            profile: profiles.first,
            energyLevel: energyLevel
        )
    }

    var body: some View {
        Group {
            if let recipe, let suggestion {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        RecipePhotoView(photoData: recipe.photoData)

                        summarySection(recipe: recipe, suggestion: suggestion)
                        ingredientsSection(suggestion: suggestion)
                        stepsSection(recipe: recipe)
                        notesSection(recipe: recipe)
                        shoppingListButton(recipe: recipe, suggestion: suggestion)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .scrollIndicators(.visible)
            } else {
                ContentUnavailableView(
                    "Recipe not found",
                    systemImage: "book.closed",
                    description: Text("This recipe may have been removed.")
                )
            }
        }
        .background(SustenanceTheme.background)
        .navigationTitle(recipe?.title ?? "Recipe")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if let recipe {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        editorMode = .edit(recipe)
                    }
                    .accessibilityHint("Edit this recipe")
                }
            }
        }
        .sheet(item: $editorMode) { mode in
            RecipeEditorView(mode: mode)
        }
    }

    private func summarySection(recipe: Recipe, suggestion: SuggestionScore) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SafetyStatusBadge(status: suggestion.safetyStatus)

            HStack(spacing: 16) {
                Label("\(recipe.prepTimeMinutes) min", systemImage: "clock")
                Label("Needs \(recipe.requiredEnergy.displayName) energy", systemImage: "bolt")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                if recipe.isSafeMeal {
                    tagLabel("Safe meal", systemImage: "checkmark.circle")
                }
                if recipe.isComfortMeal {
                    tagLabel("Comfort meal", systemImage: "heart")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ingredientsSection(suggestion: SuggestionScore) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.headline)

            IngredientGroupView(
                title: "Available",
                ingredients: grouped(suggestion, availability: .available),
                availability: .available
            )
            IngredientGroupView(
                title: "Missing",
                ingredients: grouped(suggestion, availability: .missing),
                availability: .missing
            )
            IngredientGroupView(
                title: "Caution",
                ingredients: grouped(suggestion, availability: .caution),
                availability: .caution
            )
            IngredientGroupView(
                title: "Unsafe",
                ingredients: grouped(suggestion, availability: .unsafe),
                availability: .unsafe
            )
        }
    }

    private func stepsSection(recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Steps")
                .font(.headline)

            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SustenanceTheme.selectedLabelOnAccent)
                        .frame(width: 24, height: 24)
                        .background(SustenanceTheme.accent)
                        .clipShape(Circle())
                        .accessibilityHidden(true)

                    Text(step)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Step \(index + 1). \(step)")
            }
        }
    }

    @ViewBuilder
    private func notesSection(recipe: Recipe) -> some View {
        if !recipe.notes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)

                Text(recipe.notes)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func shoppingListButton(recipe: Recipe, suggestion: SuggestionScore) -> some View {
        let missingCount = grouped(suggestion, availability: .missing).count

        return Group {
            if missingCount > 0 {
                Button {
                    addMissingToShoppingList(recipe: recipe, suggestion: suggestion)
                } label: {
                    Label(
                        didAddToList ? "Added to shopping list" : "Add \(missingCount) missing to list",
                        systemImage: didAddToList ? "cart.fill.badge.plus" : "cart.badge.plus"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(SustenanceTheme.accent)
                .disabled(didAddToList)
                .accessibilityLabel(
                    didAddToList
                        ? "Missing ingredients already added to shopping list"
                        : "Add \(missingCount) missing ingredients to shopping list"
                )
            }
        }
    }

    private func addMissingToShoppingList(recipe: Recipe, suggestion: SuggestionScore) {
        ShoppingListService.addMissingIngredients(
            from: suggestion,
            recipeID: recipe.id,
            recipeTitle: recipe.title,
            existingItems: shoppingListItems,
            modelContext: modelContext
        )
        didAddToList = true
    }

    private func tagLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(SustenanceTheme.accent.opacity(0.08))
            .foregroundStyle(SustenanceTheme.accent)
            .clipShape(Capsule())
    }

    private func grouped(_ suggestion: SuggestionScore, availability: IngredientAvailability) -> [ClassifiedIngredient] {
        suggestion.classifiedIngredients.filter { $0.availability == availability }
    }
}
