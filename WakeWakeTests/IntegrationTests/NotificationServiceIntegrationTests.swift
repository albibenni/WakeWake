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
}
