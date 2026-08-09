//
//  WakeWakeApp.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+ (Swift 6 & SwiftUI App)
//

import SwiftUI
import SwiftData

@main
struct WakeWakeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            AlarmListView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: Alarm.self)
    }
}
