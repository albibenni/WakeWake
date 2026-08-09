//
//  AlarmModelTests.swift
//  WakeWakeTests
//
//  Created in 2026 for iOS 17/18+ (XCTest Unit Tests)
//

import XCTest
@testable import WakeWake

final class AlarmModelTests: XCTestCase {

    func testAlarmDefaultInitialization() {
        let alarm = Alarm()
        XCTAssertNotNil(alarm.id)
        XCTAssertEqual(alarm.label, "Wake Up!")
        XCTAssertTrue(alarm.isEnabled)
        XCTAssertEqual(alarm.volume, 1.0)
        XCTAssertTrue(alarm.isVibrationEnabled)
        XCTAssertTrue(alarm.isSnoozeEnabled)
        XCTAssertEqual(alarm.snoozeDurationMinutes, 5)
        XCTAssertEqual(alarm.missionType, .math)
        XCTAssertEqual(alarm.missionDifficulty, .medium)
    }

    func testTimeFormatting() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = 7
        components.minute = 30
        let date = calendar.date(from: components)!

        let alarm = Alarm(time: date)
        let timeParts = alarm.hourMinuteString

        XCTAssertEqual(timeParts.hour, "07")
        XCTAssertEqual(timeParts.minute, "30")
        XCTAssertEqual(timeParts.amPm.lowercased(), "am")
    }

    func testRepeatSummaryStrings() {
        let alarmOnce = Alarm(repeatDays: [])
        XCTAssertEqual(alarmOnce.repeatSummary, "Once")

        let alarmEveryday = Alarm(repeatDays: [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday])
        XCTAssertEqual(alarmEveryday.repeatSummary, "Everyday")

        let alarmWeekdays = Alarm(repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday])
        XCTAssertEqual(alarmWeekdays.repeatSummary, "Weekdays")

        let alarmWeekends = Alarm(repeatDays: [.saturday, .sunday])
        XCTAssertEqual(alarmWeekends.repeatSummary, "Weekends")
    }

    func testNextTriggerDateFutureCalculation() {
        let now = Date()
        let calendar = Calendar.current
        
        // Alarm set 1 hour from now
        guard let futureTime = calendar.date(byAdding: .hour, value: 1, to: now) else {
            XCTFail("Could not construct future date")
            return
        }

        let alarm = Alarm(time: futureTime, repeatDays: [])
        let triggerDate = alarm.nextTriggerDate(from: now)

        XCTAssertNotNil(triggerDate)
        XCTAssertGreaterThan(triggerDate!, now)
    }

    // MARK: - Expected Failing / Edge Case Tests
    func testNextTriggerDateMustNeverReturnPastDate() {
        let now = Date()
        let calendar = Calendar.current

        // Alarm set 2 hours in the past today
        guard let pastTime = calendar.date(byAdding: .hour, value: -2, to: now) else {
            XCTFail("Could not construct past date")
            return
        }

        let alarm = Alarm(time: pastTime, repeatDays: [])
        let triggerDate = alarm.nextTriggerDate(from: now)

        XCTAssertNotNil(triggerDate)
        // Expected behavior: Past time for a one-off alarm rolls over to tomorrow (must be strictly in the future)
        XCTAssertGreaterThan(triggerDate!, now, "Trigger date must never be in the past!")
    }

    func testCurrentMinuteAlarmScheduledForToday() {
        let now = Date()
        let calendar = Calendar.current

        // Setting an alarm for current hour and minute (e.g. 10s into current minute)
        let alarm = Alarm(time: now, repeatDays: [])
        let triggerDate = alarm.nextTriggerDate(from: now)

        XCTAssertNotNil(triggerDate)
        let isSameDay = calendar.isDate(triggerDate!, inSameDayAs: now)
        XCTAssertTrue(isSameDay, "Alarm set for current minute must be scheduled for TODAY, not tomorrow!")
    }
}
