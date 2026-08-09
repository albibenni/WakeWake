//
//  NotificationService.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+ (Critical Alerts & Swift Concurrency)
//

import Foundation
@preconcurrency import UserNotifications
import Combine

@MainActor
public final class NotificationService: NSObject, ObservableObject {
    public static let shared = NotificationService()

    public static let alarmCategoryIdentifier = "WAKE_WAKE_ALARM_CATEGORY"
    public static let snoozeActionIdentifier = "ACTION_SNOOZE"
    public static let dismissActionIdentifier = "ACTION_DISMISS"

    @Published public var isAuthorized: Bool = false
    @Published public var isCriticalAlertAuthorized: Bool = false
    @Published public var currentRingingAlarmID: UUID?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupCategories()
    }

    /// Request Critical Alert & standard notification permissions from user
    public func requestPermissions() async -> (granted: Bool, criticalGranted: Bool) {
        let center = UNUserNotificationCenter.current()
        
        do {
            // Options include .criticalAlert which bypasses Do Not Disturb / Sleep Focus / Mute Switch
            let options: UNAuthorizationOptions = [.alert, .sound, .badge, .criticalAlert]
            let granted = try await center.requestAuthorization(options: options)
            
            let settings = await center.notificationSettings()
            let criticalGranted = (settings.criticalAlertSetting == .enabled)
            
            self.isAuthorized = granted
            self.isCriticalAlertAuthorized = criticalGranted
            
            return (granted, criticalGranted)
        } catch {
            print("⚠️ Failed to request notification authorization: \(error)")
            return (false, false)
        }
    }

    /// Check existing notification settings
    public func checkSettings() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        self.isCriticalAlertAuthorized = settings.criticalAlertSetting == .enabled
    }

    /// Register notification categories for Lock Screen banner actions
    private func setupCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: Self.snoozeActionIdentifier,
            title: "Snooze",
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: Self.dismissActionIdentifier,
            title: "Wake Up (Mission)",
            options: [.foreground, .authenticationRequired]
        )

        let category = UNNotificationCategory(
            identifier: Self.alarmCategoryIdentifier,
            actions: [dismissAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// Schedule or re-schedule a local notification for an alarm
    public func scheduleNotification(for alarm: Alarm) async {
        guard alarm.isEnabled else {
            cancelNotification(for: alarm)
            return
        }

        guard let triggerDate = alarm.nextTriggerDate() else { return }

        let content = UNMutableNotificationContent()
        content.title = "⏰ " + alarm.label
        content.body = "Mission required: \(alarm.missionType.title)! Tap to wake up now."
        content.categoryIdentifier = Self.alarmCategoryIdentifier
        content.userInfo = ["alarm_id": alarm.id.uuidString]

        // Sound configuration: Critical Alert if authorized, otherwise standard loud sound
        if isCriticalAlertAuthorized {
            content.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: Float(alarm.volume))
        } else {
            content.sound = UNNotificationSound.default
        }

        // Interrupting & high-priority flags
        content.interruptionLevel = .timeSensitive

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Scheduled Critical Alert Notification for alarm '\(alarm.label)' at \(triggerDate)")
        } catch {
            print("❌ Failed to schedule notification: \(error.localizedDescription)")
        }
    }

    /// Cancel a scheduled notification
    public func cancelNotification(for alarm: Alarm) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
    }

    /// Cancel all notifications
    public func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {

    /// Handle notification when app is in FOREGROUND
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        if let idString = userInfo["alarm_id"] as? String, let alarmID = UUID(uuidString: idString) {
            await MainActor.run {
                self.currentRingingAlarmID = alarmID
            }
        }
        // Show banner, play critical sound, badge
        return [.banner, .sound, .badge, .list]
    }

    /// Handle notification action responses (e.g. user tapped notification or snooze button)
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let idString = userInfo["alarm_id"] as? String, let alarmID = UUID(uuidString: idString) else { return }

        switch response.actionIdentifier {
        case NotificationService.snoozeActionIdentifier:
            print("💤 Snooze action tapped for alarm \(alarmID)")
            NotificationCenter.default.post(name: .snoozeAlarmTriggered, object: alarmID)
        case NotificationService.dismissActionIdentifier, UNNotificationDefaultActionIdentifier:
            print("🔔 Dismiss/Tap action launched app for alarm \(alarmID)")
            await MainActor.run {
                self.currentRingingAlarmID = alarmID
            }
            NotificationCenter.default.post(name: .startAlarmMissionTriggered, object: alarmID)
        default:
            break
        }
    }
}

extension Notification.Name {
    public static let snoozeAlarmTriggered = Notification.Name("snoozeAlarmTriggered")
    public static let startAlarmMissionTriggered = Notification.Name("startAlarmMissionTriggered")
}
