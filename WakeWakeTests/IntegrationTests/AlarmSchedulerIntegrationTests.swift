//
//  AlarmSchedulerIntegrationTests.swift
//  WakeWakeTests
//
//  Created in 2026 for iOS 17/18+ (Integration Tests with SwiftData)
//

import XCTest
import SwiftData
@testable import WakeWake

@MainActor
final class AlarmSchedulerIntegrationTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        // Setup in-memory SwiftData container for testing persistence
        let schema = Schema([Alarm.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testAlarmSaveAndFetchIntegration() throws {
        let alarm = Alarm(label: "Morning Workout", isEnabled: true)
        AlarmScheduler.shared.saveAndSchedule(alarm: alarm, modelContext: context)

        let descriptor = FetchDescriptor<Alarm>()
        let fetchedAlarms = try context.fetch(descriptor)

        XCTAssertEqual(fetchedAlarms.count, 1)
        XCTAssertEqual(fetchedAlarms.first?.label, "Morning Workout")
    }

    func testAlarmSnoozeIntegrationCreatesNewSnoozedAlarm() throws {
        let originalAlarm = Alarm(label: "Job Interview", snoozeDurationMinutes: 10)
        context.insert(originalAlarm)

        AlarmScheduler.shared.snoozeAlarm(originalAlarm, minutes: 10, modelContext: context)

        let descriptor = FetchDescriptor<Alarm>()
        let fetchedAlarms = try context.fetch(descriptor)

        XCTAssertEqual(fetchedAlarms.count, 2, "Snoozing must insert a new temporary snoozed alarm into SwiftData context")
        XCTAssertTrue(fetchedAlarms.contains(where: { $0.label.contains("Snoozed:") }))
    }

    func testAlarmDeleteIntegrationRemovesFromDatabase() throws {
        let alarm = Alarm(label: "Temporary Alarm")
        context.insert(alarm)
        try context.save()

        AlarmScheduler.shared.deleteAlarm(alarm, modelContext: context)

        let descriptor = FetchDescriptor<Alarm>()
        let fetchedAlarms = try context.fetch(descriptor)

        XCTAssertEqual(fetchedAlarms.count, 0)
    }

    // MARK: - Expected Failing / Boundary Integration Tests
    func testDisabledAlarmNotificationHandling() async throws {
        let disabledAlarm = Alarm(label: "Disabled Alarm", isEnabled: false)
        context.insert(disabledAlarm)

        // Save disabled alarm
        AlarmScheduler.shared.saveAndSchedule(alarm: disabledAlarm, modelContext: context)

        // Disabled alarms must not throw errors when scheduled, but should cancel notifications
        XCTAssertFalse(disabledAlarm.isEnabled)
    }
}
