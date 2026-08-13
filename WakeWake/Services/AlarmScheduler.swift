//
//  AlarmScheduler.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+ (SwiftData & UserNotifications Sync)
//

import Foundation
import SwiftData
import UserNotifications

@MainActor
public final class AlarmScheduler: ObservableObject {
    public static let shared = AlarmScheduler()

    private init() {}

    /// Sync active alarms with UNUserNotificationCenter
    public func rescheduleAllActiveAlarms(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Alarm>()
        do {
            let alarms = try modelContext.fetch(descriptor)
            for alarm in alarms {
                if alarm.repeatDays.isEmpty, alarm.time < Date() {
                    // One-off alarms expire after their scheduled date; they never roll into tomorrow.
                    alarm.isEnabled = false
                    NotificationService.shared.cancelNotification(for: alarm)
                    continue
                }
                if alarm.isEnabled {
                    Task {
                        await NotificationService.shared.scheduleNotification(for: alarm)
                    }
                } else {
                    NotificationService.shared.cancelNotification(for: alarm)
                }
            }
            try? modelContext.save()
        } catch {
            print("❌ Failed to fetch alarms for rescheduling: \(error.localizedDescription)")
        }
    }

    /// Schedule next trigger for a specific alarm
    public func saveAndSchedule(alarm: Alarm, modelContext: ModelContext) {
        if alarm.repeatDays.isEmpty, let nextDate = alarm.nextTriggerDate() {
            // Persist the exact planned occurrence so this alarm is truly one-off.
            alarm.time = nextDate
        }
        alarm.updatedAt = Date()
        modelContext.insert(alarm)
        try? modelContext.save()

        Task {
            _ = await NotificationService.shared.requestPermissions()
            if alarm.isEnabled {
                await NotificationService.shared.cancelSnoozes(for: alarm)
                await NotificationService.shared.scheduleNotification(for: alarm)
            } else {
                NotificationService.shared.cancelNotification(for: alarm)
                await NotificationService.shared.cancelSnoozes(for: alarm)
            }
        }
    }

    /// Schedule an ephemeral notification rather than persisting a duplicate alarm.
    public func snoozeAlarm(_ alarm: Alarm, minutes: Int, modelContext _: ModelContext) {
        Task {
            await NotificationService.shared.scheduleSnooze(for: alarm, minutes: minutes)
        }
    }

    /// Delete alarm and cancel notification
    public func deleteAlarm(_ alarm: Alarm, modelContext: ModelContext) {
        NotificationService.shared.cancelNotification(for: alarm)
        Task { await NotificationService.shared.cancelSnoozes(for: alarm) }
        modelContext.delete(alarm)
        try? modelContext.save()
    }
}
