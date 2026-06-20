import SwiftUI
import SwiftData

struct MealCalendarView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \MealLogEntry.madeAt, order: .reverse) private var mealLogs: [MealLogEntry]

    @AppStorage(AppPreferences.repeatMealRemindersEnabledKey) private var repeatMealRemindersEnabled = true
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var dismissedRepeatReminderRecipeIDs = AppPreferences.dismissedRepeatReminderRecipeIDs
    @State private var isShowingLogMealSheet = false
    @State private var entryPendingRemoval: MealLogEntry?

    private var mealLogSnapshots: [MealLogSnapshot] {
        mealLogs.map(MealLogSnapshot.init)
    }

    private var logsForSelectedDate: [MealLogEntry] {
        mealLogs
            .filter { Calendar.current.isDate($0.madeAt, inSameDayAs: selectedDate) }
            .sorted { $0.madeAt > $1.madeAt }
    }

    private var repeatReminders: [MealRepeatReminder] {
        MealReminderPreferences.activeReminders(
            in: mealLogSnapshots,
            remindersEnabled: repeatMealRemindersEnabled,
            dismissedRecipeIDs: dismissedRepeatReminderRecipeIDs
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    intro

                    DatePicker(
                        "Select day",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .tint(SustenanceTheme.accent)
                    .padding(12)
                    .background(SustenanceTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    dayDetailSection

                    if !repeatReminders.isEmpty {
                        repeatRemindersSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(SustenanceTheme.background)
            .navigationTitle("Calendar")
            .sheet(isPresented: $isShowingLogMealSheet) {
                LogMealSheet(selectedDate: selectedDate)
            }
            .confirmationDialog(
                "Remove this meal log?",
                isPresented: Binding(
                    get: { entryPendingRemoval != nil },
                    set: { if !$0 { entryPendingRemoval = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Remove from calendar", role: .destructive) {
                    if let entryPendingRemoval {
                        remove(entryPendingRemoval)
                    }
                    entryPendingRemoval = nil
                }
                Button("Cancel", role: .cancel) {
                    entryPendingRemoval = nil
                }
            } message: {
                if let entryPendingRemoval {
                    Text("\(entryPendingRemoval.recipeTitle) will be removed from your meal history.")
                }
            }
        }
        .tabItem {
            Label("Calendar", systemImage: "calendar")
        }
        .tag(5)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Track what you ate")
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            Text("Log meals on the day you ate them. Remove any entry to take it off your calendar.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var dayDetailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedDayTitle)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Button {
                isShowingLogMealSheet = true
            } label: {
                Label("Log a meal", systemImage: "plus.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(SustenanceTheme.accent)
            .accessibilityHint("Log something you ate, with or without a saved recipe")

            if logsForSelectedDate.isEmpty {
                Text("No meals logged this day.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SustenanceTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ForEach(logsForSelectedDate, id: \.id) { entry in
                    MealLogRow(
                        entry: entry,
                        reminder: reminder(for: entry),
                        onRemove: { entryPendingRemoval = entry }
                    )
                }
            }
        }
    }

    private var repeatRemindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gentle reminders")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            ForEach(repeatReminders) { reminder in
                MealRepeatReminderBanner(reminder: reminder) {
                    dismissedRepeatReminderRecipeIDs = MealReminderPreferences.dismissReminder(
                        for: reminder.recipeID
                    )
                }
            }
        }
    }

    private var selectedDayTitle: String {
        selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private func remove(_ entry: MealLogEntry) {
        MealTrackingService.remove(entry, in: modelContext)
    }

    private func reminder(for entry: MealLogEntry) -> MealRepeatReminder? {
        MealReminderPreferences.repeatReminder(
            for: entry.recipeID,
            recipeTitle: entry.recipeTitle,
            in: mealLogSnapshots,
            remindersEnabled: repeatMealRemindersEnabled,
            dismissedRecipeIDs: dismissedRepeatReminderRecipeIDs
        )
    }
}

struct MealLogRow: View {
    let entry: MealLogEntry
    let reminder: MealRepeatReminder?
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.recipeTitle)
                        .font(.body.weight(.medium))

                    Text("\(entry.madeAt.formatted(date: .omitted, time: .shortened)) · \(entry.energyLevel.displayName) energy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Button("Remove", role: .destructive, action: onRemove)
                    .font(.caption.weight(.medium))
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Remove \(entry.recipeTitle) from calendar")
            }

            if let reminder {
                Text(reminder.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SustenanceTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [
            entry.recipeTitle,
            "\(entry.energyLevel.displayName) energy",
        ]

        if let reminder {
            parts.append(reminder.message)
        }

        return parts.joined(separator: ". ")
    }
}

#Preview {
    MealCalendarView()
        .modelContainer(for: [MealLogEntry.self, Recipe.self], inMemory: true)
}
