//
//  HapticService.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import UIKit
import AudioToolbox

@MainActor
public final class HapticService {
    public static let shared = HapticService()

    private var isVibratingLoop: Bool = false
    private var vibrationTimer: Timer?

    private init() {}

    public func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    public func successNotification() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    public func errorNotification() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    /// Continuous strong alarm vibration pulse
    public func startContinuousVibration() {
        stopVibration()
        isVibratingLoop = true

        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            // Trigger system haptic motor pulse
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }

    public func stopVibration() {
        isVibratingLoop = false
        vibrationTimer?.invalidate()
        vibrationTimer = nil
    }
}
