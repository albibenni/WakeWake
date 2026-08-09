//
//  AlarmSound.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import Foundation

public enum AlarmSound: String, Codable, CaseIterable, Identifiable {
    case emergencyBell = "emergency_bell"
    case fireSignal = "fire_signal"
    case highVoltage = "high_voltage"
    case neonPulse = "neon_pulse"
    case radarAlert = "radar_alert"
    case militaryBugle = "military_bugle"
    case customRingtone = "custom_ringtone"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .emergencyBell: return "Emergency Siren 🚨"
        case .fireSignal: return "Fire Signal Alarm 🔥"
        case .highVoltage: return "High Voltage Shock ⚡️"
        case .neonPulse: return "Neon Pulse Synth 🔊"
        case .radarAlert: return "Submarine Radar 🚢"
        case .militaryBugle: return "Reveille Bugle 🎺"
        case .customRingtone:
            let name = UserDefaults.standard.string(forKey: "CustomRingtoneDisplayName") ?? "Custom Sound"
            return "🎵 \(name)"
        }
    }

    /// System or bundle audio filename with extension
    public var filename: String {
        switch self {
        case .emergencyBell: return "emergency_bell.mp3"
        case .fireSignal: return "fire_signal.mp3"
        case .highVoltage: return "high_voltage.mp3"
        case .neonPulse: return "neon_pulse.mp3"
        case .radarAlert: return "radar_alert.mp3"
        case .militaryBugle: return "military_bugle.mp3"
        case .customRingtone: return "custom_ringtone"
        }
    }

    /// Sound description for sound picker preview
    public var description: String {
        switch self {
        case .emergencyBell: return "Maximum volume piercing siren designed for deep sleepers"
        case .fireSignal: return "Rapid high-frequency pulse that guarantees instant awakening"
        case .highVoltage: return "Rhythmic electric buzz sound with strong bass frequencies"
        case .neonPulse: return "Futuristic energetic synth loop"
        case .radarAlert: return "Repeating acoustic ping that overrides ambient room noise"
        case .militaryBugle: return "Classic military wake up call"
        case .customRingtone: return "Your custom imported sound file from iPhone Storage / Files"
        }
    }
}
