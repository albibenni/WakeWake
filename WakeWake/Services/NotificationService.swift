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
            options: [.foreground]
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

        // Sound & Interruption Level configuration
        content.relevanceScore = 1.0 // Prioritize at top of iOS Notification Center & Lock Screen

        if isCriticalAlertAuthorized {
            content.interruptionLevel = .critical
            content.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: Float(alarm.volume))
        } else {
            content.interruptionLevel = .timeSensitive
            content.sound = UNNotificationSound.default
        }

        let timeInterval = triggerDate.timeIntervalSinceNow
        let trigger: UNNotificationTrigger
        if timeInterval > 0 && timeInterval <= 3600 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, timeInterval), repeats: false)
        } else {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

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
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        if let idString = userInfo["alarm_id"] as? String, let alarmID = UUID(uuidString: idString) {
            DispatchQueue.main.async {
                NotificationService.shared.currentRingingAlarmID = alarmID
                NotificationCenter.default.post(name: .startAlarmMissionTriggered, object: alarmID)
            }
        }
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification action responses (e.g. user tapped notification or snooze button)
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let idString = userInfo["alarm_id"] as? String, let alarmID = UUID(uuidString: idString) {
            DispatchQueue.main.async {
                switch response.actionIdentifier {
                case NotificationService.snoozeActionIdentifier:
                    print("💤 Snooze action tapped for alarm \(alarmID)")
                    NotificationCenter.default.post(name: .snoozeAlarmTriggered, object: alarmID)
                case NotificationService.dismissActionIdentifier, UNNotificationDefaultActionIdentifier:
                    print("🔔 Dismiss/Tap action launched app for alarm \(alarmID)")
                    NotificationService.shared.currentRingingAlarmID = alarmID
                    NotificationCenter.default.post(name: .startAlarmMissionTriggered, object: alarmID)
                default:
                    break
                }
            }
        }
        completionHandler()
    }
}

extension Notification.Name {
    public static let snoozeAlarmTriggered = Notification.Name("snoozeAlarmTriggered")
    public static let startAlarmMissionTriggered = Notification.Name("startAlarmMissionTriggered")
}
