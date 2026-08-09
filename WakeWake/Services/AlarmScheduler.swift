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
                if alarm.isEnabled {
                    Task {
                        await NotificationService.shared.scheduleNotification(for: alarm)
                    }
                } else {
                    NotificationService.shared.cancelNotification(for: alarm)
                }
            }
        } catch {
            print("❌ Failed to fetch alarms for rescheduling: \(error.localizedDescription)")
        }
    }

    /// Schedule next trigger for a specific alarm
    public func saveAndSchedule(alarm: Alarm, modelContext: ModelContext) {
        alarm.updatedAt = Date()
        modelContext.insert(alarm)
        try? modelContext.save()

        Task {
            _ = await NotificationService.shared.requestPermissions()
            if alarm.isEnabled {
                await NotificationService.shared.scheduleNotification(for: alarm)
            } else {
                NotificationService.shared.cancelNotification(for: alarm)
            }
        }
    }

    /// Handle snooze for an alarm (reschedules 5 minutes into the future)
    public func snoozeAlarm(_ alarm: Alarm, minutes: Int, modelContext: ModelContext) {
        let snoozeTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        
        // Create temporary snooze alarm
        let snoozedAlarm = Alarm(
            label: "Snoozed: \(alarm.label)",
            isEnabled: true,
            repeatDays: [],
            sound: alarm.sound,
            volume: alarm.volume,
            isVibrationEnabled: alarm.isVibrationEnabled,
            isSnoozeEnabled: alarm.isSnoozeEnabled,
            snoozeDurationMinutes: alarm.snoozeDurationMinutes,
            missionType: alarm.missionType,
            missionDifficulty: alarm.missionDifficulty,
            missionTargetCount: alarm.missionTargetCount
        )
        snoozedAlarm.time = snoozeTime

        modelContext.insert(snoozedAlarm)
        try? modelContext.save()

        Task {
            await NotificationService.shared.scheduleNotification(for: snoozedAlarm)
        }
    }

    /// Delete alarm and cancel notification
    public func deleteAlarm(_ alarm: Alarm, modelContext: ModelContext) {
        NotificationService.shared.cancelNotification(for: alarm)
        modelContext.delete(alarm)
        try? modelContext.save()
    }
}
