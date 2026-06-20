import SwiftUI
import SwiftData

struct PantryView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PantryItem.name) private var items: [PantryItem]

    @State private var searchText = ""
    @State private var locationFilter: StorageLocation?
    @State private var editorMode: PantryItemEditorView.Mode?
    @State private var navigationPath = NavigationPath()

    private var filteredItems: [PantryItem] {
        items.filter { item in
            let matchesLocation = locationFilter == nil || item.location == locationFilter
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty
                || item.name.localizedCaseInsensitiveContains(query)
                || item.category.localizedCaseInsensitiveContains(query)
            return matchesLocation && matchesSearch
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            SustenanceScreenBackground(asset: .pantry) {
                Group {
                    if items.isEmpty {
                        emptyState
                    } else {
                        listContent
                    }
                }
            }
            .navigationTitle("Pantry")
            .searchable(text: $searchText, prompt: "Search pantry")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SustenanceAddButton(accessibilityLabel: "Add item") {
                        editorMode = .add
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                locationPicker
            }
            .sheet(item: $editorMode) { mode in
                PantryItemEditorView(mode: mode)
            }
        }
        .tabItem {
            Label("Pantry", systemImage: "basket")
        }
        .tag(2)
    }

    private var locationPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", isSelected: locationFilter == nil) {
                    locationFilter = nil
                }
                ForEach(StorageLocation.allCases) { location in
                    filterChip(title: location.displayName, isSelected: locationFilter == location) {
                        locationFilter = location
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .background(SustenanceTheme.background)
    }

    private var listContent: some View {
        List {
            if filteredItems.isEmpty {
                Text("No items match your search.")
                    .foregroundStyle(.secondary)
                    .listRowBackground(AdaptiveThemeBackground(color: SustenanceTheme.background))
            } else {
                ForEach(filteredItems, id: \.id) { item in
                    Button {
                        editorMode = .edit(item)
                    } label: {
                        PantryRowView(item: item)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(AdaptiveThemeBackground(color: SustenanceTheme.cardBackground))
                }
                .onDelete(perform: deleteItems)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        SustenanceEmptyStateView(
            asset: .pantry,
            title: "Pantry is empty",
            message: "Add what you have on hand. This helps Sustenance suggest meals you can actually make.",
            addAccessibilityLabel: "Add item"
        ) {
            editorMode = .add
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? SustenanceTheme.accent : SustenanceTheme.cardBackground)
                .foregroundStyle(
                    isSelected
                        ? AnyShapeStyle(SustenanceTheme.selectedLabelOnAccent)
                        : AnyShapeStyle(Color.primary)
                )
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(isSelected ? SustenanceTheme.accent : SustenanceTheme.border, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) filter")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredItems[index])
        }
        try? modelContext.save()
    }
}

private struct PantryRowView: View {
    let item: PantryItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                Text("\(item.location.displayName) · \(item.category)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.location.displayName), \(item.category)")
    }
}

#Preview {
    PantryView()
        .modelContainer(for: [PantryItem.self], inMemory: true)
}
