import SwiftUI
import SwiftData

struct SafeMealsView: View {
    @Query(sort: \Recipe.title) private var recipes: [Recipe]
    @Query(sort: \PantryItem.name) private var pantryItems: [PantryItem]
    @Query private var profiles: [SafetyProfile]

    @AppStorage("todayEnergyLevel") private var storedEnergyLevel = EnergyLevel.okay.rawValue
    @State private var navigationPath = NavigationPath()

    private var energyLevel: EnergyLevel {
        EnergyLevel(rawValue: storedEnergyLevel) ?? profiles.first?.defaultEnergyLevel ?? .okay
    }

    private var safeMeals: [SuggestionScore] {
        MealSuggestions.safeMeals(
            recipes: recipes,
            pantry: pantryItems,
            profile: profiles.first,
            energyLevel: energyLevel
        )
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            SustenanceScreenBackground(asset: .safeMeals, style: .inlineHero) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        SustenanceInlineHero(asset: .safeMeals, maxWidth: 460, maxHeight: 460)

                        intro

                        if safeMeals.isEmpty {
                            emptyState
                        } else {
                            ForEach(safeMeals) { meal in
                                Button {
                                    navigationPath.append(meal.recipeID)
                                } label: {
                                    SuggestionCardView(suggestion: meal)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Opens recipe details")
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .scrollIndicators(.visible)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Safe Meals")
            .navigationDestination(for: UUID.self) { recipeID in
                RecipeDetailView(recipeID: recipeID, energyLevel: energyLevel)
            }
        }
        .tabItem {
            Label("Safe Meals", systemImage: "heart.text.square")
        }
        .tag(1)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Trusted options")
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            Text("Safe and comfort meals that fit your profile. Log what you ate in Calendar.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No safe meals yet")
                .font(.subheadline.weight(.semibold))

            Text("Mark recipes as safe or comfort meals in your library.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SustenanceTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    SafeMealsView()
        .modelContainer(for: [Recipe.self, PantryItem.self, SafetyProfile.self, MealLogEntry.self], inMemory: true)
}
