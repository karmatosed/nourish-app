import SwiftUI
import SwiftData

struct RecipesView: View {
    @Query(sort: \Recipe.title) private var recipes: [Recipe]
    @Query(sort: \PantryItem.name) private var pantryItems: [PantryItem]
    @Query private var profiles: [SafetyProfile]

    @AppStorage("todayEnergyLevel") private var storedEnergyLevel = EnergyLevel.okay.rawValue

    @State private var searchText = ""
    @State private var filters = RecipeLibraryFilter.Options()
    @State private var showFilters = false
    @State private var showImport = false
    @State private var editorMode: RecipeEditorView.Mode?
    @State private var navigationPath = NavigationPath()

    private var energyLevel: EnergyLevel {
        EnergyLevel(rawValue: storedEnergyLevel) ?? .okay
    }

    private var filteredRecipes: [Recipe] {
        var options = filters
        options.searchText = searchText
        return RecipeLibraryFilter.filtered(
            recipes: recipes,
            pantry: pantryItems,
            profile: profiles.first,
            options: options,
            energyLevelForScoring: energyLevel
        )
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            SustenanceScreenBackground(asset: .recipes) {
                Group {
                    if recipes.isEmpty {
                        emptyLibrary
                    } else {
                        listContent
                    }
                }
            }
            .navigationTitle("Recipes")
            .searchable(text: $searchText, prompt: "Search recipes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showFilters = true
                    } label: {
                        Label("Filters", systemImage: filters.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showImport = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    SustenanceAddButton(accessibilityLabel: "Add recipe") {
                        editorMode = .add
                    }
                }
            }
            .sheet(isPresented: $showImport) {
                RecipeMarkdownImportView()
            }
            .sheet(isPresented: $showFilters) {
                RecipeFiltersSheet(filters: $filters)
            }
            .sheet(item: $editorMode) { mode in
                RecipeEditorView(mode: mode)
            }
            .navigationDestination(for: UUID.self) { recipeID in
                RecipeDetailView(recipeID: recipeID, energyLevel: energyLevel)
            }
        }
        .tabItem {
            Label("Recipes", systemImage: "book")
        }
        .tag(3)
    }

    private var listContent: some View {
        List {
            if filteredRecipes.isEmpty {
                Text("No recipes match your filters.")
                    .foregroundStyle(.secondary)
                    .listRowBackground(AdaptiveThemeBackground(color: SustenanceTheme.background))
            } else {
                ForEach(filteredRecipes, id: \.id) { recipe in
                    Button {
                        navigationPath.append(recipe.id)
                    } label: {
                        RecipeRowView(recipe: recipe, pantry: pantryItems, profile: profiles.first, energyLevel: energyLevel)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(AdaptiveThemeBackground(color: SustenanceTheme.cardBackground))
                }
                .onDelete(perform: deleteRecipes)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyLibrary: some View {
        SustenanceEmptyStateView(
            asset: .recipes,
            title: "No recipes yet",
            message: "Add your own meals or keep the seeded starters after first launch.",
            addAccessibilityLabel: "Add recipe"
        ) {
            editorMode = .add
        }
    }

    private func deleteRecipes(at offsets: IndexSet) {
        for index in offsets {
            modelContextDelete(filteredRecipes[index])
        }
    }

    @Environment(\.modelContext) private var modelContext

    private func modelContextDelete(_ recipe: Recipe) {
        modelContext.delete(recipe)
        try? modelContext.save()
    }
}

private struct RecipeRowView: View {
    let recipe: Recipe
    let pantry: [PantryItem]
    let profile: SafetyProfile?
    let energyLevel: EnergyLevel

    private var score: SuggestionScore? {
        MealSuggestions.score(recipe: recipe, pantry: pantry, profile: profile, energyLevel: energyLevel)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RecipePhotoThumbnail(photoData: recipe.photoData)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(recipe.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    if let score {
                        SafetyStatusBadge(status: score.safetyStatus)
                    }
                }

                HStack(spacing: 12) {
                    Label("\(recipe.prepTimeMinutes) min", systemImage: "clock")
                    Label(recipe.requiredEnergy.displayName, systemImage: "bolt")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    if recipe.isSafeMeal {
                        badge("Safe")
                    }
                    if recipe.isComfortMeal {
                        badge("Comfort")
                    }
                    if let score, score.missingIngredientCount > 0 {
                        Text("\(score.missingIngredientCount) missing")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(recipeAccessibilityLabel)
    }

    private var recipeAccessibilityLabel: String {
        var parts = [recipe.title, "\(recipe.prepTimeMinutes) minutes", "\(recipe.requiredEnergy.displayName) energy"]
        if recipe.isSafeMeal { parts.append("Safe meal") }
        if recipe.isComfortMeal { parts.append("Comfort meal") }
        if let score {
            parts.append(score.safetyStatus.displayName)
            if score.missingIngredientCount > 0 {
                parts.append("\(score.missingIngredientCount) missing ingredients")
            }
        }
        return parts.joined(separator: ". ")
    }

    private func badge(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(SustenanceTheme.background)
            .overlay {
                Capsule().strokeBorder(SustenanceTheme.border, lineWidth: 1)
            }
            .clipShape(Capsule())
    }
}

private struct RecipeFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: RecipeLibraryFilter.Options

    @State private var draft: RecipeLibraryFilter.Options = .init()

    var body: some View {
        NavigationStack {
            Form {
                Section("Diet") {
                    Toggle("Match my diet profile", isOn: $draft.profileCompatibleOnly)
                }

                Section("Meal type") {
                    Toggle("Safe meals only", isOn: $draft.safeMealsOnly)
                    Toggle("Comfort meals only", isOn: $draft.comfortMealsOnly)
                }

                Section("Energy") {
                    Picker("Required energy", selection: $draft.energyLevel) {
                        Text("Any").tag(EnergyLevel?.none)
                        ForEach(EnergyLevel.allCases) { level in
                            Text(level.displayName).tag(Optional(level))
                        }
                    }
                }

                Section("Time") {
                    Picker("Max prep time", selection: $draft.maxPrepMinutes) {
                        Text("Any").tag(Int?.none)
                        Text("15 minutes or less").tag(Optional(15))
                        Text("30 minutes or less").tag(Optional(30))
                    }
                }

                Section("Pantry") {
                    Toggle("All ingredients available", isOn: $draft.availableIngredientsOnly)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        draft = RecipeLibraryFilter.Options()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        filters = draft
                        dismiss()
                    }
                }
            }
            .onAppear {
                draft = filters
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private extension RecipeLibraryFilter.Options {
    var isActive: Bool {
        !profileCompatibleOnly || safeMealsOnly || comfortMealsOnly || energyLevel != nil || maxPrepMinutes != nil || availableIngredientsOnly
    }
}

#Preview {
    RecipesView()
        .modelContainer(for: [Recipe.self, PantryItem.self, SafetyProfile.self], inMemory: true)
}
