import XCTest
@testable import Sustenance

final class MealTrackingServiceTests: XCTestCase {
    private let recipeID = UUID()
    private let calendar = Calendar(identifier: .gregorian)

    private func entry(
        daysAgo: Int,
        hour: Int = 12,
        referenceDate: Date
    ) -> MealLogSnapshot {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: referenceDate))!
        let madeAt = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
        return MealLogSnapshot(
            recipeID: recipeID,
            recipeTitle: "Plain Rice Bowl",
            madeAt: madeAt,
            energyLevel: .low
        )
    }

    func testSameDayRepeatReminderTriggersOnSecondLog() {
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 20, hour: 18))!
        let entries = [entry(daysAgo: 0, hour: 8, referenceDate: referenceDate)]

        let reminder = MealTrackingService.repeatReminder(
            for: recipeID,
            recipeTitle: "Plain Rice Bowl",
            in: entries,
            includingPendingLog: true,
            referenceDate: referenceDate,
            calendar: calendar
        )

        XCTAssertEqual(reminder?.kind, .sameDay(count: 2))
        XCTAssertEqual(reminder?.message, "You've had Plain Rice Bowl twice today.")
    }

    func testFrequentRepeatReminderTriggersAfterFourLogsInSevenDays() {
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 20, hour: 18))!
        let entries = [
            entry(daysAgo: 1, referenceDate: referenceDate),
            entry(daysAgo: 2, referenceDate: referenceDate),
            entry(daysAgo: 4, referenceDate: referenceDate),
        ]

        let reminder = MealTrackingService.repeatReminder(
            for: recipeID,
            recipeTitle: "Plain Rice Bowl",
            in: entries,
            includingPendingLog: true,
            referenceDate: referenceDate,
            calendar: calendar
        )

        XCTAssertEqual(reminder?.kind, .frequent(count: 4, withinDays: 7))
    }

    func testSameDayReminderTakesPriorityOverWeeklyReminder() {
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 20, hour: 18))!
        let entries = [
            entry(daysAgo: 0, hour: 8, referenceDate: referenceDate),
            entry(daysAgo: 1, referenceDate: referenceDate),
            entry(daysAgo: 3, referenceDate: referenceDate),
        ]

        let reminder = MealTrackingService.repeatReminder(
            for: recipeID,
            recipeTitle: "Plain Rice Bowl",
            in: entries,
            includingPendingLog: true,
            referenceDate: referenceDate,
            calendar: calendar
        )

        XCTAssertEqual(reminder?.kind, .sameDay(count: 2))
    }

    func testActiveRemindersReturnsUniqueRecipes() {
        let otherRecipeID = UUID()
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 20, hour: 18))!
        let entries = [
            entry(daysAgo: 0, hour: 8, referenceDate: referenceDate),
            entry(daysAgo: 0, hour: 12, referenceDate: referenceDate),
            MealLogSnapshot(
                recipeID: otherRecipeID,
                recipeTitle: "Creamy Oats with Berries",
                madeAt: referenceDate,
                energyLevel: .low
            ),
        ]

        let reminders = MealTrackingService.activeReminders(
            in: entries,
            referenceDate: referenceDate,
            calendar: calendar
        )

        XCTAssertEqual(reminders.count, 1)
        XCTAssertEqual(reminders.first?.recipeID, recipeID)
    }

    func testDismissedRecipeDoesNotReturnReminder() {
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 20, hour: 18))!
        let entries = [
            entry(daysAgo: 0, hour: 8, referenceDate: referenceDate),
            entry(daysAgo: 0, hour: 12, referenceDate: referenceDate),
        ]

        let reminder = MealTrackingService.repeatReminder(
            for: recipeID,
            recipeTitle: "Plain Rice Bowl",
            in: entries,
            referenceDate: referenceDate,
            calendar: calendar,
            remindersEnabled: true,
            dismissedRecipeIDs: [recipeID]
        )

        XCTAssertNil(reminder)
    }

    func testRemindersDisabledReturnsNoActiveReminders() {
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 20, hour: 18))!
        let entries = [
            entry(daysAgo: 0, hour: 8, referenceDate: referenceDate),
            entry(daysAgo: 0, hour: 12, referenceDate: referenceDate),
        ]

        let reminders = MealTrackingService.activeReminders(
            in: entries,
            referenceDate: referenceDate,
            calendar: calendar,
            remindersEnabled: false,
            dismissedRecipeIDs: []
        )

        XCTAssertTrue(reminders.isEmpty)
    }

    func testLogTimestampUsesNowForToday() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: .now)
        let timestamp = MealTrackingService.logTimestamp(for: today, calendar: calendar)

        XCTAssertTrue(calendar.isDateInToday(timestamp))
    }

    func testLogTimestampUsesMiddayForPastDays() {
        let calendar = Calendar(identifier: .gregorian)
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 20))!
        let pastDate = calendar.date(byAdding: .day, value: -2, to: referenceDate)!
        let timestamp = MealTrackingService.logTimestamp(for: pastDate, calendar: calendar)

        XCTAssertEqual(calendar.component(.hour, from: timestamp), 12)
        XCTAssertTrue(calendar.isDate(timestamp, inSameDayAs: pastDate))
    }

    func testCustomMealRecipeIDIsStableForSameTitle() {
        let first = MealTrackingService.customMealRecipeID(for: "  Beans on toast  ")
        let second = MealTrackingService.customMealRecipeID(for: "beans on toast")

        XCTAssertEqual(first, second)
    }

    func testCustomMealRecipeIDDiffersForDifferentTitles() {
        let first = MealTrackingService.customMealRecipeID(for: "Beans on toast")
        let second = MealTrackingService.customMealRecipeID(for: "Peanut butter sandwich")

        XCTAssertNotEqual(first, second)
    }
}
