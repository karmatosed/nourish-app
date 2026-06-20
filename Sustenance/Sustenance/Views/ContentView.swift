import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(selectedTab: $selectedTab)
            SafeMealsView()
            PantryView()
            RecipesView()
            ShoppingListView()
            MealCalendarView()
            SettingsView()
        }
        .tint(SustenanceTheme.accent)
        .onAppear {
            DataSeeder.maintain(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [Recipe.self, PantryItem.self, SafetyProfile.self, MealLogEntry.self, ShoppingListItem.self],
            inMemory: true
        )
}
