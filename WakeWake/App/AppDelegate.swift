//
//  AppDelegate.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import UIKit
import UserNotifications

@MainActor
public final class AppDelegate: NSObject, UIApplicationDelegate {

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // Synchronously register notification delegate on app launch so iOS handles notification taps
        UNUserNotificationCenter.current().delegate = NotificationService.shared
        
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
