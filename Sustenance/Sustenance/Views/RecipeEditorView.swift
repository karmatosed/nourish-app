import SwiftUI
import SwiftData
import PhotosUI

struct RecipeEditorView: View {
    enum Mode: Identifiable {
        case add
        case edit(Recipe)

        var id: String {
            switch self {
            case .add: "add"
            case .edit(let recipe): recipe.id.uuidString
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let mode: Mode

    @State private var title = ""
    @State private var prepTimeMinutes = 15
    @State private var requiredEnergy: EnergyLevel = .okay
    @State private var isSafeMeal = false
    @State private var isComfortMeal = false
    @State private var notes = ""
    @State private var ingredients: [RecipeIngredient] = [RecipeIngredient(name: "")]
    @State private var steps: [String] = [""]
    @State private var photoData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    if let photoData {
                        RecipePhotoView(photoData: photoData, height: 200)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(photoData == nil ? "Add photo" : "Replace photo", systemImage: "photo")
                    }
                    .accessibilityHint("Choose a photo from your library")

                    if photoData != nil {
                        Button("Remove photo", role: .destructive) {
                            photoData = nil
                            selectedPhotoItem = nil
                        }
                    }
                }

                Section("Basics") {
                    TextField("Title", text: $title)

                    Stepper("Prep time: \(prepTimeMinutes) min", value: $prepTimeMinutes, in: 1...180)

                    Picker("Energy needed", selection: $requiredEnergy) {
                        ForEach(EnergyLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }

                    Toggle("Safe meal", isOn: $isSafeMeal)
                    Toggle("Comfort meal", isOn: $isComfortMeal)
                }

                Section("Ingredients") {
                    ForEach(ingredients.indices, id: \.self) { index in
                        HStack(spacing: 8) {
                            TextField("Ingredient", text: ingredientNameBinding(index))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            TextField("Qty", text: ingredientQuantityBinding(index))
                                .frame(width: 70)
                        }
                    }
                    .onDelete(perform: deleteIngredients)

                    Button {
                        ingredients.append(RecipeIngredient(name: ""))
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add ingredient")
                }

                Section("Steps") {
                    ForEach(steps.indices, id: \.self) { index in
                        TextField("Step \(index + 1)", text: stepBinding(index), axis: .vertical)
                            .lineLimit(2...4)
                    }
                    .onDelete(perform: deleteSteps)

                    Button {
                        steps.append("")
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add step")
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(isEditing ? "Edit Recipe" : "Add Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
                if isEditing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Delete", role: .destructive, action: deleteRecipe)
                    }
                }
            }
            .onAppear(perform: load)
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    await loadPhoto(from: newItem)
                }
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !cleanedIngredients.isEmpty
            && !cleanedSteps.isEmpty
    }

    private var cleanedIngredients: [RecipeIngredient] {
        ingredients
            .map { RecipeIngredient(name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines), quantity: $0.quantity?.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.name.isEmpty }
    }

    private var cleanedSteps: [String] {
        steps.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    private func ingredientNameBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { ingredients[index].name },
            set: { ingredients[index].name = $0 }
        )
    }

    private func ingredientQuantityBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { ingredients[index].quantity ?? "" },
            set: { ingredients[index].quantity = $0.isEmpty ? nil : $0 }
        )
    }

    private func stepBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { steps[index] },
            set: { steps[index] = $0 }
        )
    }

    private func load() {
        guard case .edit(let recipe) = mode else { return }
        title = recipe.title
        prepTimeMinutes = recipe.prepTimeMinutes
        requiredEnergy = recipe.requiredEnergy
        isSafeMeal = recipe.isSafeMeal
        isComfortMeal = recipe.isComfortMeal
        notes = recipe.notes
        ingredients = recipe.ingredients.isEmpty ? [RecipeIngredient(name: "")] : recipe.ingredients
        steps = recipe.steps.isEmpty ? [""] : recipe.steps
        photoData = recipe.photoData
    }

    private func loadPhoto(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        photoData = RecipePhotoProcessor.process(data)
    }

    private func save() {
        guard canSave else { return }

        switch mode {
        case .add:
            modelContext.insert(
                Recipe(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    ingredients: cleanedIngredients,
                    steps: cleanedSteps,
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                    prepTimeMinutes: prepTimeMinutes,
                    requiredEnergy: requiredEnergy,
                    isSafeMeal: isSafeMeal,
                    isComfortMeal: isComfortMeal,
                    photoData: photoData
                )
            )
        case .edit(let recipe):
            recipe.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            recipe.ingredients = cleanedIngredients
            recipe.steps = cleanedSteps
            recipe.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            recipe.prepTimeMinutes = prepTimeMinutes
            recipe.requiredEnergy = requiredEnergy
            recipe.isSafeMeal = isSafeMeal
            recipe.isComfortMeal = isComfortMeal
            recipe.photoData = photoData
        }

        try? modelContext.save()
        dismiss()
    }

    private func deleteRecipe() {
        guard case .edit(let recipe) = mode else { return }
        modelContext.delete(recipe)
        try? modelContext.save()
        dismiss()
    }

    private func deleteIngredients(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
        if ingredients.isEmpty {
            ingredients = [RecipeIngredient(name: "")]
        }
    }

    private func deleteSteps(at offsets: IndexSet) {
        steps.remove(atOffsets: offsets)
        if steps.isEmpty {
            steps = [""]
        }
    }
}
