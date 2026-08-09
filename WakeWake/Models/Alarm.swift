//
//  Alarm.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+ (Swift 6 & SwiftData)
//

import Foundation
import SwiftData

@Model
public final class Alarm {
    @Attribute(.unique) public var id: UUID
    public var time: Date
    public var label: String
    public var isEnabled: Bool
    public var repeatDaysRawValue: Int
    public var soundRawValue: String
    public var volume: Double // 0.0 to 1.0
    public var isVibrationEnabled: Bool
    public var isSnoozeEnabled: Bool
    public var snoozeDurationMinutes: Int
    
    // Mission configuration
    public var missionTypeRawValue: String
    public var missionDifficultyRawValue: String
    public var missionTargetCount: Int // e.g. 5 math problems, 30 shakes, 20 steps
    
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        time: Date = Date(),
        label: String = "Wake Up!",
        isEnabled: Bool = true,
        repeatDays: Set<RepeatDay> = [],
        sound: AlarmSound = .emergencyBell,
        volume: Double = 1.0,
        isVibrationEnabled: Bool = true,
        isSnoozeEnabled: Bool = true,
        snoozeDurationMinutes: Int = 5,
        missionType: MissionType = .math,
        missionDifficulty: MissionDifficulty = .medium,
        missionTargetCount: Int = 5,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.time = time
        self.label = label
        self.isEnabled = isEnabled
        self.repeatDaysRawValue = RepeatDay.encode(repeatDays)
        self.soundRawValue = sound.rawValue
        self.volume = volume
        self.isVibrationEnabled = isVibrationEnabled
        self.isSnoozeEnabled = isSnoozeEnabled
        self.snoozeDurationMinutes = snoozeDurationMinutes
        self.missionTypeRawValue = missionType.rawValue
        self.missionDifficultyRawValue = missionDifficulty.rawValue
        self.missionTargetCount = missionTargetCount
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    public var repeatDays: Set<RepeatDay> {
        get { RepeatDay.decode(repeatDaysRawValue) }
        set { repeatDaysRawValue = RepeatDay.encode(newValue) }
    }

    public var sound: AlarmSound {
        get { AlarmSound(rawValue: soundRawValue) ?? .emergencyBell }
        set { soundRawValue = newValue.rawValue }
    }

    public var missionType: MissionType {
        get { MissionType(rawValue: missionTypeRawValue) ?? .math }
        set { missionTypeRawValue = newValue.rawValue }
    }

    public var missionDifficulty: MissionDifficulty {
        get { MissionDifficulty(rawValue: missionDifficultyRawValue) ?? .medium }
        set { missionDifficultyRawValue = newValue.rawValue }
    }

    /// Formatted time string (e.g., "07:30 AM")
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    /// Formatted time components
    public var hourMinuteString: (hour: String, minute: String, amPm: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        let parts = formatter.string(from: time).split(separator: " ")
        let timeParts = parts.first?.split(separator: ":") ?? ["07", "00"]
        let amPm = parts.count > 1 ? String(parts[1]) : ""
        return (String(timeParts[0]), String(timeParts[1]), amPm)
    }

    /// Readable repeat string (e.g. "Mon, Tue, Wed", "Everyday", "Weekdays", "Off")
    public var repeatSummary: String {
        let days = repeatDays
        if days.isEmpty { return "Once" }
        if days.count == 7 { return "Everyday" }
        if days == [.monday, .tuesday, .wednesday, .thursday, .friday] { return "Weekdays" }
        if days == [.saturday, .sunday] { return "Weekends" }
        
        let ordered: [RepeatDay] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        return ordered.filter { days.contains($0) }.map { $0.shortName }.joined(separator: ", ")
    }

    /// Computes the exact next trigger Date
    public func nextTriggerDate(from currentDate: Date = Date()) -> Date? {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        guard let targetHour = timeComponents.hour, let targetMinute = timeComponents.minute else { return nil }

        if repeatDays.isEmpty {
            // One-off alarm
            var candidateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
            candidateComponents.hour = targetHour
            candidateComponents.minute = targetMinute
            candidateComponents.second = 0
            
            if let candidate = calendar.date(from: candidateComponents) {
                // If candidate is in the future or within the current minute (last 59s), schedule for today
                if candidate.timeIntervalSince(currentDate) > -59 {
                    return candidate
                } else {
                    return calendar.date(byAdding: .day, value: 1, to: candidate)
                }
            }
            return nil
        } else {
            // Repeating alarm
            let checkDate = currentDate
            for dayOffset in 0...7 {
                guard let candidateDate = calendar.date(byAdding: .day, value: dayOffset, to: checkDate) else { continue }
                var candidateComponents = calendar.dateComponents([.year, .month, .day, .weekday], from: candidateDate)
                candidateComponents.hour = targetHour
                candidateComponents.minute = targetMinute
                candidateComponents.second = 0

                guard let fullCandidate = calendar.date(from: candidateComponents),
                      let weekdayIndex = candidateComponents.weekday,
                      let repeatDay = RepeatDay(weekdayIndex: weekdayIndex) else { continue }

                if repeatDays.contains(repeatDay) && fullCandidate > currentDate {
                    return fullCandidate
                }
            }
            return nil
        }
    }
}

// MARK: - RepeatDay Enum
public enum RepeatDay: Int, Codable, CaseIterable, Identifiable, Hashable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    public var id: Int { rawValue }

    public var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    public var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    public init?(weekdayIndex: Int) {
        self.init(rawValue: weekdayIndex)
    }

    public static func encode(_ days: Set<RepeatDay>) -> Int {
        var bitmask = 0
        for day in days {
            bitmask |= (1 << day.rawValue)
        }
        return bitmask
    }

    public static func decode(_ bitmask: Int) -> Set<RepeatDay> {
        var days = Set<RepeatDay>()
        for day in RepeatDay.allCases {
            if (bitmask & (1 << day.rawValue)) != 0 {
                days.insert(day)
            }
        }
        return days
    }
}
