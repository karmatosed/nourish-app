import SwiftUI
import SwiftData

struct TodayView: View {
    @Binding var selectedTab: Int

    @Query(sort: \Recipe.title) private var recipes: [Recipe]
    @Query(sort: \PantryItem.name) private var pantryItems: [PantryItem]
    @Query private var profiles: [SafetyProfile]
    @Query(sort: \MealLogEntry.madeAt, order: .reverse) private var mealLogs: [MealLogEntry]

    @AppStorage("todayEnergyLevel") private var storedEnergyLevel = EnergyLevel.okay.rawValue
    @State private var selectedEnergy: EnergyLevel = .okay
    @State private var navigationPath = NavigationPath()

    private var mealLogSnapshots: [MealLogSnapshot] {
        mealLogs.map(MealLogSnapshot.init)
    }

    private var todaysMeals: [MealLogSnapshot] {
        MealTrackingService.logs(on: .now, in: mealLogSnapshots)
            .sorted { $0.madeAt > $1.madeAt }
    }

    private var suggestions: [SuggestionScore] {
        MealSuggestions.topSuggestions(
            recipes: recipes,
            pantry: pantryItems,
            profile: profiles.first,
            energyLevel: selectedEnergy
        )
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            SustenanceScreenBackground(asset: .today, style: .inlineHero) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        SustenanceInlineHero(asset: .today)

                        header

                        EnergySelectorView(selection: $selectedEnergy)

                        mealTrackingShortcut

                        safeMealsShortcut

                        suggestionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .scrollIndicators(.visible)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Today")
            .navigationDestination(for: UUID.self) { recipeID in
                RecipeDetailView(recipeID: recipeID, energyLevel: selectedEnergy)
            }
            .onAppear {
                if let stored = EnergyLevel(rawValue: storedEnergyLevel) {
                    selectedEnergy = stored
                } else if let defaultEnergy = profiles.first?.defaultEnergyLevel {
                    selectedEnergy = defaultEnergy
                }
            }
            .onChange(of: selectedEnergy) { _, newValue in
                storedEnergyLevel = newValue.rawValue
            }
        }
        .tabItem {
            Label("Today", systemImage: "sun.max")
        }
        .tag(0)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What can you make right now?")
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            Text("Three ideas based on your energy, pantry, and safety profile.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var mealTrackingShortcut: some View {
        Button {
            selectedTab = 5
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title3)
                        .foregroundStyle(SustenanceTheme.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Log what you ate")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(todaysMeals.isEmpty ? "Open Calendar to track meals" : "\(todaysMeals.count) logged today in Calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                if !todaysMeals.isEmpty {
                    TodaysMealsSection(meals: todaysMeals)
                }
            }
            .padding(16)
            .background(SustenanceTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            todaysMeals.isEmpty
                ? "Open Calendar to log meals"
                : "Open Calendar. \(todaysMeals.count) meals logged today."
        )
    }

    private var safeMealsShortcut: some View {
        Button {
            selectedTab = 1
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "heart.text.square.fill")
                    .font(.title3)
                    .foregroundStyle(SustenanceTheme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Need something easy?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Open your trusted safe meals")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(SustenanceTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open safe meals. Trusted options when deciding feels like too much.")
    }

    @ViewBuilder
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggestions for you")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if suggestions.isEmpty {
                emptyState
            } else {
                ForEach(suggestions) { suggestion in
                    Button {
                        navigationPath.append(suggestion.recipeID)
                    } label: {
                        SuggestionCardView(suggestion: suggestion)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens recipe details")
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No matches right now")
                .font(.subheadline.weight(.semibold))

            Text("Try a different energy level, update your pantry, or browse safe meals.")
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
    TodayView(selectedTab: .constant(0))
        .modelContainer(for: [Recipe.self, PantryItem.self, SafetyProfile.self, MealLogEntry.self], inMemory: true)
}
