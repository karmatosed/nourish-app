import SwiftUI
import SwiftData

struct PantryItemEditorView: View {
    enum Mode: Identifiable {
        case add
        case edit(PantryItem)

        var id: String {
            switch self {
            case .add: "add"
            case .edit(let item): item.id.uuidString
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let mode: Mode

    @State private var name = ""
    @State private var location: StorageLocation = .pantry
    @State private var category = "Other"

    private let categorySuggestions = [
        "Grains", "Protein", "Produce", "Dairy", "Frozen",
        "Oils", "Spices", "Canned", "Broth", "Sweeteners", "Legumes", "Other",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Picker("Location", selection: $location) {
                        ForEach(StorageLocation.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }

                    Picker("Category", selection: $category) {
                        ForEach(categorySuggestions, id: \.self) { suggestion in
                            Text(suggestion).tag(suggestion)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if isEditing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Delete", role: .destructive, action: deleteItem)
                    }
                }
            }
            .onAppear(perform: load)
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func load() {
        guard case .edit(let item) = mode else { return }
        name = item.name
        location = item.location
        category = item.category
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        switch mode {
        case .add:
            modelContext.insert(
                PantryItem(name: trimmedName, location: location, category: category)
            )
        case .edit(let item):
            item.name = trimmedName
            item.location = location
            item.category = category
        }

        try? modelContext.save()
        dismiss()
    }

    private func deleteItem() {
        guard case .edit(let item) = mode else { return }
        modelContext.delete(item)
        try? modelContext.save()
        dismiss()
    }
}
