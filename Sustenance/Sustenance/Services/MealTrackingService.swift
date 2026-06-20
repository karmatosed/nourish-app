import CryptoKit
import Foundation
import SwiftData

struct MealRepeatReminder: Equatable, Sendable, Identifiable {
    enum Kind: Equatable {
        case sameDay(count: Int)
        case frequent(count: Int, withinDays: Int)
    }

    var id: UUID { recipeID }

    let recipeID: UUID
    let recipeTitle: String
    let kind: Kind

    var message: String {
        switch kind {
        case .sameDay(let count):
            if count == 2 {
                return "You've had \(recipeTitle) twice today."
            }
            return "You've had \(recipeTitle) \(count) times today."
        case .frequent(let count, let withinDays):
            return "\(recipeTitle) has been a go-to \(count) times in the last \(withinDays) days."
        }
    }

    var guidance: String {
        "Variety can help when you have the energy — no pressure to change."
    }
}

enum MealTrackingService {
    static let weeklyLookbackDays = 7
    static let frequentRepeatThreshold = 4
    static let sameDayRepeatThreshold = 2

    static func log(
        recipeID: UUID,
        recipeTitle: String,
        energyLevel: EnergyLevel,
        madeAt: Date = .now,
        in modelContext: ModelContext
    ) {
        modelContext.insert(
            MealLogEntry(
                recipeID: recipeID,
                recipeTitle: recipeTitle,
                madeAt: madeAt,
                energyLevel: energyLevel
            )
        )
        try? modelContext.save()
    }

    static func logCustomMeal(
        title: String,
        energyLevel: EnergyLevel,
        madeAt: Date = .now,
        in modelContext: ModelContext
    ) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        log(
            recipeID: customMealRecipeID(for: trimmed),
            recipeTitle: trimmed,
            energyLevel: energyLevel,
            madeAt: madeAt,
            in: modelContext
        )
        return true
    }

    static func customMealRecipeID(for title: String) -> UUID {
        let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let digest = SHA256.hash(data: Data("sustenance.custom-meal.\(normalized)".utf8))
        let bytes = Array(digest.prefix(16))
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    static func remove(_ entry: MealLogEntry, in modelContext: ModelContext) {
        modelContext.delete(entry)
        try? modelContext.save()
    }

    static func logTimestamp(for selectedDate: Date, calendar: Calendar = .current) -> Date {
        if calendar.isDateInToday(selectedDate) {
            return .now
        }

        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate
    }

    static func logs(
        on date: Date,
        in entries: [MealLogSnapshot],
        calendar: Calendar = .current
    ) -> [MealLogSnapshot] {
        entries.filter { calendar.isDate($0.madeAt, inSameDayAs: date) }
    }

    static func logs(
        for recipeID: UUID,
        in entries: [MealLogSnapshot],
        withinDays days: Int,
        from referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [MealLogSnapshot] {
        guard
            let start = calendar.date(
                byAdding: .day,
                value: -(days - 1),
                to: calendar.startOfDay(for: referenceDate)
            )
        else {
            return []
        }

        return entries.filter { $0.recipeID == recipeID && $0.madeAt >= start }
    }

    static func count(
        for recipeID: UUID,
        on date: Date,
        in entries: [MealLogSnapshot],
        calendar: Calendar = .current
    ) -> Int {
        logs(on: date, in: entries, calendar: calendar)
            .filter { $0.recipeID == recipeID }
            .count
    }

    static func repeatReminder(
        for recipeID: UUID,
        recipeTitle: String,
        in entries: [MealLogSnapshot],
        includingPendingLog: Bool = false,
        referenceDate: Date = .now,
        calendar: Calendar = .current,
        remindersEnabled: Bool = true,
        dismissedRecipeIDs: Set<UUID> = []
    ) -> MealRepeatReminder? {
        guard remindersEnabled else { return nil }
        guard !dismissedRecipeIDs.contains(recipeID) else { return nil }

        let todayCount = count(for: recipeID, on: referenceDate, in: entries, calendar: calendar)
        let adjustedTodayCount = todayCount + (includingPendingLog ? 1 : 0)

        if adjustedTodayCount >= sameDayRepeatThreshold {
            return MealRepeatReminder(
                recipeID: recipeID,
                recipeTitle: recipeTitle,
                kind: .sameDay(count: adjustedTodayCount)
            )
        }

        let weeklyCount = logs(
            for: recipeID,
            in: entries,
            withinDays: weeklyLookbackDays,
            from: referenceDate,
            calendar: calendar
        ).count + (includingPendingLog ? 1 : 0)

        if weeklyCount >= frequentRepeatThreshold {
            return MealRepeatReminder(
                recipeID: recipeID,
                recipeTitle: recipeTitle,
                kind: .frequent(count: weeklyCount, withinDays: weeklyLookbackDays)
            )
        }

        return nil
    }

    static func activeReminders(
        in entries: [MealLogSnapshot],
        referenceDate: Date = .now,
        calendar: Calendar = .current,
        remindersEnabled: Bool = true,
        dismissedRecipeIDs: Set<UUID> = []
    ) -> [MealRepeatReminder] {
        guard remindersEnabled else { return [] }

        let recipeIDs = Set(entries.map(\.recipeID))

        return recipeIDs.compactMap { recipeID in
            let title = entries
                .filter { $0.recipeID == recipeID }
                .max(by: { $0.madeAt < $1.madeAt })?
                .recipeTitle ?? "This meal"

            return repeatReminder(
                for: recipeID,
                recipeTitle: title,
                in: entries,
                referenceDate: referenceDate,
                calendar: calendar,
                remindersEnabled: remindersEnabled,
                dismissedRecipeIDs: dismissedRecipeIDs
            )
        }
        .sorted { lhs, rhs in
            lhs.recipeTitle.localizedCaseInsensitiveCompare(rhs.recipeTitle) == .orderedAscending
        }
    }
}
