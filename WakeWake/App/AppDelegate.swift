//
//  AppDelegate.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import UIKit
import UserNotifications
import AVFoundation

public final class AppDelegate: NSObject, UIApplicationDelegate {

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // Initialize Audio Session for background alarm sound override
        Task { @MainActor in
            AudioService.shared.configureAudioSession()
        }

        return true
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        print("📱 Application entered background. Alarms scheduled via UNUserNotificationCenter.")
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        print("📱 Application entering foreground. Updating notification settings status.")
        Task { @MainActor in
            await NotificationService.shared.checkSettings()
        }
    }
}
