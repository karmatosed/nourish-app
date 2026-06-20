import SwiftUI

struct MealRepeatReminderBanner: View {
    let reminder: MealRepeatReminder
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(reminder.message, systemImage: "leaf.circle")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SustenanceTheme.accent)

            Text(reminder.guidance)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let onDismiss {
                Button("Turn off for this meal", action: onDismiss)
                    .font(.caption.weight(.medium))
                    .buttonStyle(.borderless)
                    .tint(SustenanceTheme.accent)
                    .accessibilityHint("Stops repeat reminders for \(reminder.recipeTitle)")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SustenanceTheme.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reminder.message) \(reminder.guidance)")
    }
}

struct TodaysMealsSection: View {
    let meals: [MealLogSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Logged today")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            ForEach(meals) { meal in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.recipeTitle)
                            .font(.body.weight(.medium))

                        Text("\(meal.madeAt.formatted(date: .omitted, time: .shortened)) · \(meal.energyLevel.displayName) energy")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SustenanceTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(meal.recipeTitle), logged at \(meal.madeAt.formatted(date: .omitted, time: .shortened)), \(meal.energyLevel.displayName) energy")
            }
        }
    }
}

enum MealReminderPreferences {
    static func activeReminders(
        in entries: [MealLogSnapshot],
        remindersEnabled: Bool,
        dismissedRecipeIDs: Set<UUID>
    ) -> [MealRepeatReminder] {
        MealTrackingService.activeReminders(
            in: entries,
            remindersEnabled: remindersEnabled,
            dismissedRecipeIDs: dismissedRecipeIDs
        )
    }

    static func repeatReminder(
        for recipeID: UUID,
        recipeTitle: String,
        in entries: [MealLogSnapshot],
        includingPendingLog: Bool = false,
        remindersEnabled: Bool,
        dismissedRecipeIDs: Set<UUID>
    ) -> MealRepeatReminder? {
        MealTrackingService.repeatReminder(
            for: recipeID,
            recipeTitle: recipeTitle,
            in: entries,
            includingPendingLog: includingPendingLog,
            remindersEnabled: remindersEnabled,
            dismissedRecipeIDs: dismissedRecipeIDs
        )
    }

    static func dismissReminder(for recipeID: UUID) -> Set<UUID> {
        AppPreferences.dismissRepeatReminder(for: recipeID)
        return AppPreferences.dismissedRepeatReminderRecipeIDs
    }
}
