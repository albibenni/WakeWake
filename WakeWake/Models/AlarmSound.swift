//
//  AlarmSound.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import Foundation

public enum AlarmSound: String, Codable, CaseIterable, Identifiable {
    case radar = "radar"
    case reflection = "reflection"
    case chime = "chime"
    case beacon = "beacon"
    case apex = "apex"
    case circuit = "circuit"
    case signal = "signal"
    case slowRise = "slow_rise"
    case customRingtone = "custom_ringtone"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .radar: return "Radar (Default Classic) 🚨"
        case .reflection: return "Reflection 🎵"
        case .chime: return "Chime 🔔"
        case .beacon: return "Beacon 🗼"
        case .apex: return "Apex 🏔️"
        case .circuit: return "Circuit ⚡️"
        case .signal: return "Signal 📡"
        case .slowRise: return "Slow Rise 🌅"
        case .customRingtone:
            let name = UserDefaults.standard.string(forKey: "CustomRingtoneDisplayName") ?? "Custom Sound"
            return "🎵 \(name)"
        }
    }

    /// Sound audio filename for bundle loading
    public var filename: String {
        return "\(rawValue).wav"
    }

    /// System audio filename in iOS /System/Library/Audio/UISounds/
    public var systemAudioName: String {
        switch self {
        case .radar: return "Radar"
        case .reflection: return "Reflection"
        case .chime: return "Chime"
        case .beacon: return "Beacon"
        case .apex: return "Apex"
        case .circuit: return "Circuit"
        case .signal: return "Signal"
        case .slowRise: return "SlowRise"
        case .customRingtone: return "Radar"
        }
    }

    /// Native iOS built-in system sound ID
    public var systemSoundID: UInt32 {
        switch self {
        case .radar: return 1005       // Standard Radar Alarm
        case .reflection: return 1000  // iOS Reflection Tone
        case .chime: return 1008       // Chime
        case .beacon: return 1021      // Beacon
        case .apex: return 1026        // Apex Tone
        case .circuit: return 1023     // Circuit Tone
        case .signal: return 1016      // Signal Pulse Tone
        case .slowRise: return 1027    // Slow Rise Alarm
        case .customRingtone: return 1005
        }
    }

    /// Sound description for sound picker
    public var description: String {
        switch self {
        case .radar: return "Standard iOS high-volume alarm siren"
        case .reflection: return "Standard iOS melodic ringtone"
        case .chime: return "Gentle repeating acoustic chime"
        case .beacon: return "Rhythmic pulsating beacon tone"
        case .apex: return "High altitude crisp acoustic alarm"
        case .circuit: return "Energetic electronic pulse sequence"
        case .signal: return "Rapid high-frequency signal alert"
        case .slowRise: return "Gradually building morning wake-up sound"
        case .customRingtone: return "Your custom imported sound file from iPhone Storage / Files"
        }
    }
}
