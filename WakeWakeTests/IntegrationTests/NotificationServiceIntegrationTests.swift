//
//  NotificationServiceIntegrationTests.swift
//  WakeWakeTests
//
//  Created in 2026 for iOS 17/18+ (Integration Tests)
//

import XCTest
import UserNotifications
@testable import WakeWake

@MainActor
final class NotificationServiceIntegrationTests: XCTestCase {

    func testNotificationServiceSingletonInitialization() {
        let service = NotificationService.shared
        XCTAssertNotNil(service)
    }

    func testCancelNotificationForAlarmDoesNotCrash() {
        let alarm = Alarm(label: "Cancel Test")
        NotificationService.shared.cancelNotification(for: alarm)
        // Verify method executes safely
        XCTAssertTrue(true)
    }

    // MARK: - Expected Failing / Boundary Test
    func testScheduleNotificationWithDisabledAlarmDoesNotAddRequest() async {
        let disabledAlarm = Alarm(label: "Disabled Test", isEnabled: false)
        await NotificationService.shared.scheduleNotification(for: disabledAlarm)

        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let containsDisabled = requests.contains(where: { $0.identifier == disabledAlarm.id.uuidString })

        XCTAssertFalse(containsDisabled, "Disabled alarm must never add a pending notification request!")
    }

    func testScheduleNearTermAlarmUsesTimeIntervalTrigger() async {
        let now = Date()
        let calendar = Calendar.current
        guard let nearTermDate = calendar.date(byAdding: .minute, value: 5, to: now) else {
            XCTFail("Could not create near term date")
            return
        }
        let alarm = Alarm(time: nearTermDate, isEnabled: true)

        await NotificationService.shared.scheduleNotification(for: alarm)

        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let matchingRequest = requests.first(where: { $0.identifier == alarm.id.uuidString })

        XCTAssertNotNil(matchingRequest, "Near term alarm notification must be scheduled!")
        XCTAssertTrue(matchingRequest?.trigger is UNTimeIntervalNotificationTrigger, "Alarms scheduled under 1 hour must use UNTimeIntervalNotificationTrigger!")
    }
}
