//
//  NotificationService.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+ (local notifications & Swift Concurrency)
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
    @Published public var isTimeSensitiveEnabled: Bool = false
    @Published public var currentRingingAlarmID: UUID?
    @Published public var pendingSnoozeAlarmID: UUID?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupCategories()
    }

    /// Request the standard notification permission. Critical Alerts are not requested
    /// because they require a separate Apple-approved health or safety entitlement.
    public func requestPermissions() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await center.requestAuthorization(options: options)
            
            let settings = await center.notificationSettings()
            
            self.isAuthorized = granted
            self.isTimeSensitiveEnabled = settings.timeSensitiveSetting == .enabled
            
            return granted
        } catch {
            print("⚠️ Failed to request notification authorization: \(error)")
            return false
        }
    }

    /// Check existing notification settings
    public func checkSettings() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        self.isTimeSensitiveEnabled = settings.timeSensitiveSetting == .enabled
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

    private func requestIdentifier(for alarm: Alarm, weekday: RepeatDay? = nil) -> String {
        weekday.map { "\(alarm.id.uuidString)-weekday-\($0.rawValue)" } ?? alarm.id.uuidString
    }

    private func snoozeIdentifierPrefix(for alarm: Alarm) -> String {
        "snooze-\(alarm.id.uuidString)-"
    }

    private func content(for alarm: Alarm) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "⏰ " + alarm.label
        content.body = "Tap Start Mission to turn off this alarm."
        content.categoryIdentifier = Self.alarmCategoryIdentifier
        content.userInfo = ["alarm_id": alarm.id.uuidString]
        content.relevanceScore = 1.0
        content.interruptionLevel = isTimeSensitiveEnabled ? .timeSensitive : .active
        content.sound = .default
        return content
    }

    /// Schedule one request for a one-off alarm, or one repeating request per weekday.
    public func scheduleNotification(for alarm: Alarm) async {
        guard alarm.isEnabled else {
            cancelNotification(for: alarm)
            return
        }

        do {
            cancelNotification(for: alarm)
            let calendar = Calendar.autoupdatingCurrent
            let time = calendar.dateComponents([.hour, .minute], from: alarm.time)

            if alarm.repeatDays.isEmpty {
                guard let triggerDate = alarm.nextTriggerDate() else { return }
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
                let request = UNNotificationRequest(
                    identifier: requestIdentifier(for: alarm), content: content(for: alarm),
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                )
                try await UNUserNotificationCenter.current().add(request)
            } else {
                for weekday in alarm.repeatDays {
                    var components = time
                    components.weekday = weekday.rawValue
                    let request = UNNotificationRequest(
                        identifier: requestIdentifier(for: alarm, weekday: weekday), content: content(for: alarm),
                        trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                    )
                    try await UNUserNotificationCenter.current().add(request)
                }
            }
            print("✅ Scheduled notification(s) for '\(alarm.label)'")
        } catch {
            print("❌ Failed to schedule notification: \(error.localizedDescription)")
        }
    }

    /// Cancel a scheduled notification
    public func cancelNotification(for alarm: Alarm) {
        let identifiers = [requestIdentifier(for: alarm)] + RepeatDay.allCases.map {
            requestIdentifier(for: alarm, weekday: $0)
        }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    /// A snooze is intentionally not persisted as an Alarm model.
    public func scheduleSnooze(for alarm: Alarm, minutes: Int) async {
        let identifier = snoozeIdentifierPrefix(for: alarm) + UUID().uuidString
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(60, TimeInterval(minutes * 60)), repeats: false
        )
        do {
            try await UNUserNotificationCenter.current().add(
                UNNotificationRequest(identifier: identifier, content: content(for: alarm), trigger: trigger)
            )
        } catch {
            print("❌ Failed to schedule snooze: \(error.localizedDescription)")
        }
    }

    public func cancelSnoozes(for alarm: Alarm) async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let identifiers = requests.map(\.identifier).filter {
            $0.hasPrefix(snoozeIdentifierPrefix(for: alarm))
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
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
                    NotificationService.shared.pendingSnoozeAlarmID = alarmID
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
    public static let startAlarmMissionTriggered = Notification.Name("startAlarmMissionTriggered")
}
