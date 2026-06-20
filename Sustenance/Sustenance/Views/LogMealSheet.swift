import SwiftUI
import SwiftData

struct LogMealSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Recipe.title) private var recipes: [Recipe]
    @Query(sort: \PantryItem.name) private var pantryItems: [PantryItem]
    @Query private var profiles: [SafetyProfile]

    @AppStorage("todayEnergyLevel") private var storedEnergyLevel = EnergyLevel.okay.rawValue

    let selectedDate: Date

    @State private var energyLevel: EnergyLevel = .okay
    @State private var customMealTitle = ""
    @State private var recipeSearchText = ""

    private var trimmedCustomTitle: String {
        customMealTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var profileCompatibleRecipes: [Recipe] {
        RecipeLibraryFilter.filtered(
            recipes: recipes,
            pantry: pantryItems,
            profile: profiles.first,
            options: RecipeLibraryFilter.Options(profileCompatibleOnly: true),
            energyLevelForScoring: energyLevel
        )
    }

    private var filteredRecipes: [Recipe] {
        let base = profileCompatibleRecipes
        guard !recipeSearchText.isEmpty else { return base }

        return base.filter {
            $0.title.localizedCaseInsensitiveContains(recipeSearchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    customMealSection
                    dayAndEnergySection
                    recipeSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(SustenanceTheme.background)
            .navigationTitle("Log a meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let stored = EnergyLevel(rawValue: storedEnergyLevel) {
                    energyLevel = stored
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var customMealSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Log what you ate")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text("Takeaway, snacks, or anything not in your recipe library.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("What did you eat?", text: $customMealTitle)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .padding(12)
                .background(SustenanceTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(SustenanceTheme.border, lineWidth: 1)
                )
                .onSubmit(logCustomMeal)

            Button(action: logCustomMeal) {
                Label("Log this meal", systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(SustenanceTheme.accent)
            .disabled(trimmedCustomTitle.isEmpty)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SustenanceTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var dayAndEnergySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            EnergySelectorView(selection: $energyLevel, title: "Energy when eaten")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SustenanceTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var recipeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Or pick a saved recipe")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            if !recipes.isEmpty {
                TextField("Search recipes", text: $recipeSearchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(SustenanceTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(SustenanceTheme.border, lineWidth: 1)
                    )
            }

            if recipes.isEmpty {
                Text("Add recipes in your library to log them quickly from this list.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if filteredRecipes.isEmpty {
                Text(
                    recipeSearchText.isEmpty
                        ? "No saved recipes match your diet profile."
                        : "No recipes match your search."
                )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(filteredRecipes) { recipe in
                        Button {
                            log(recipe)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipe.title)
                                        .foregroundStyle(.primary)

                                    Text("\(recipe.prepTimeMinutes) min · \(recipe.requiredEnergy.displayName) energy")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer(minLength: 8)

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 4)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Log \(recipe.title)")

                        if recipe.id != filteredRecipes.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SustenanceTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func logCustomMeal() {
        guard MealTrackingService.logCustomMeal(
            title: trimmedCustomTitle,
            energyLevel: energyLevel,
            madeAt: MealTrackingService.logTimestamp(for: selectedDate),
            in: modelContext
        ) else {
            return
        }

        dismiss()
    }

    private func log(_ recipe: Recipe) {
        MealTrackingService.log(
            recipeID: recipe.id,
            recipeTitle: recipe.title,
            energyLevel: energyLevel,
            madeAt: MealTrackingService.logTimestamp(for: selectedDate),
            in: modelContext
        )
        dismiss()
    }
}

#Preview {
    LogMealSheet(selectedDate: .now)
        .modelContainer(for: [Recipe.self, MealLogEntry.self], inMemory: true)
}
