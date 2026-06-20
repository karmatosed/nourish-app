import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ShoppingListItem.createdAt, order: .reverse) private var items: [ShoppingListItem]

    @State private var newItemName = ""
    @State private var showCheckedItems = false

    private var uncheckedItems: [ShoppingListItem] {
        items.filter { !$0.isChecked }
    }

    private var checkedItems: [ShoppingListItem] {
        items.filter(\.isChecked)
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .background(SustenanceTheme.background)
            .navigationTitle("List")
            .toolbar {
                if !checkedItems.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear done") {
                            clearCheckedItems()
                        }
                        .font(.subheadline)
                        .accessibilityHint("Removes checked items from your shopping list")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                addBar
            }
        }
        .tabItem {
            Label("List", systemImage: "cart")
        }
        .tag(4)
    }

    private var listContent: some View {
        List {
            if !uncheckedItems.isEmpty {
                Section("To buy") {
                    ForEach(uncheckedItems, id: \.id) { item in
                        ShoppingListRow(item: item) {
                            toggle(item)
                        }
                        .listRowBackground(AdaptiveThemeBackground(color: SustenanceTheme.cardBackground))
                    }
                    .onDelete { offsets in
                        deleteItems(at: offsets, from: uncheckedItems)
                    }
                }
            }

            if !checkedItems.isEmpty {
                Section {
                    if showCheckedItems {
                        ForEach(checkedItems, id: \.id) { item in
                            ShoppingListRow(item: item) {
                                toggle(item)
                            }
                            .listRowBackground(AdaptiveThemeBackground(color: SustenanceTheme.cardBackground))
                        }
                        .onDelete { offsets in
                            deleteItems(at: offsets, from: checkedItems)
                        }
                    }
                } header: {
                    Button {
                        withAnimation {
                            showCheckedItems.toggle()
                        }
                    } label: {
                        HStack {
                            Text("Done (\(checkedItems.count))")
                            Spacer()
                            Image(systemName: showCheckedItems ? "chevron.down" : "chevron.right")
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(showCheckedItems ? "Hide done items" : "Show done items")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var addBar: some View {
        HStack(spacing: 8) {
            TextField("Add item", text: $newItemName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit(addItem)
                .accessibilityLabel("Shopping list item")

            SustenanceAddButton(accessibilityLabel: "Add list item", style: .inline) {
                addItem()
            }
            .disabled(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(SustenanceTheme.cardBackground)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Nothing on your list", systemImage: "cart")
        } description: {
            Text("Add missing ingredients from a recipe, or type items below.")
        }
    }

    private func addItem() {
        ShoppingListService.addItem(name: newItemName, modelContext: modelContext)
        newItemName = ""
    }

    private func toggle(_ item: ShoppingListItem) {
        item.isChecked.toggle()
        try? modelContext.save()
    }

    private func deleteItems(at offsets: IndexSet, from source: [ShoppingListItem]) {
        for index in offsets {
            modelContext.delete(source[index])
        }
        try? modelContext.save()
    }

    private func clearCheckedItems() {
        for item in checkedItems {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}

private struct ShoppingListRow: View {
    let item: ShoppingListItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(
                        item.isChecked
                            ? AnyShapeStyle(SustenanceTheme.accent)
                            : AnyShapeStyle(Color.secondary)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .foregroundStyle(item.isChecked ? .secondary : .primary)
                        .strikethrough(item.isChecked)

                    if !item.quantity.isEmpty {
                        Text(item.quantity)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !item.recipeTitle.isEmpty {
                        Text("For \(item.recipeTitle)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.isChecked ? "Checked off \(item.name)" : item.name)
    }
}

#Preview {
    ShoppingListView()
        .modelContainer(for: [ShoppingListItem.self], inMemory: true)
}
