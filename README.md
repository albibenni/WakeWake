# ⏰ WakeWake — iOS Action Alarm App

**WakeWake** is a high-performance, loud action alarm clock application built for iOS 17/18+ using **Swift 6**, **SwiftUI**, **SwiftData**, **UserNotifications Critical Alerts**, and **CoreMotion**.

WakeWake prevents users from falling back asleep by forcing them to complete interactive **Wake-Up Missions** before turning off the alarm siren.

---

## 🌟 Key Features

1. **System Override Reliability**
   - **Silent / Mute Switch Bypass:** Uses `AVAudioSession` `.playback` category and `.alarm` mode to ring loudly even when the silent switch is ON.
   - **Sleep Focus & DND Override:** Integrates Apple `UNAuthorizationOptions.criticalAlert` to sound alarms during Do Not Disturb / Sleep Focus modes.
   - **Volume Boost & Procedural Siren:** Includes high-gain procedural siren fallback using `AVAudioEngine` if custom sound files are unavailable.

2. **Interactive Wake-Up Missions**
   - 🧮 **Math Problems:** Solve arithmetic equations (Easy, Medium, Hard, Extreme) with customizable problem counts.
   - 📱 **Shake Phone:** Vigorously shake the phone with live CoreMotion accelerometer progress gauge.
   - 🚶‍♂️ **Steps & Squats:** CMPedometer step tracking and accelerometer pitch-angle squat detector.
   - 🧩 **Memory Puzzle:** 3x3 Simon-Says glowing pattern sequence solver.
   - ✍️ **Motivational Typing:** Type morning declarations accurately without mistakes.

3. **Modern iOS Aesthetics & Dashboard**
   - **Next Alarm Countdown:** Live header indicator showing time remaining until the next active alarm ("Ringing in 7h 12m").
   - **Glassmorphic Cyber Dark UI:** Modern neon accents, high contrast glass cards, tactile haptic feedback.
   - **Nightstand Mode:** Bedside digital clock view with smooth brightness dimmer.

---

## 📁 Repository Architecture

```
wake-wake/
├── WakeWake.xcodeproj/       # Xcode Project File
│   └── project.pbxproj
├── WakeWake/
│   ├── App/                  # App Entry Point & App Delegate
│   │   ├── WakeWakeApp.swift
│   │   ├── AppDelegate.swift
│   │   └── Info.plist
│   ├── Entitlements/         # Apple Critical Alerts Entitlement
│   │   └── WakeWake.entitlements
│   ├── Models/               # SwiftData Persistence Models
│   │   ├── Alarm.swift
│   │   ├── Mission.swift
│   │   └── AlarmSound.swift
│   ├── Services/             # Core Services & Hardware Interlocking
│   │   ├── NotificationService.swift (Critical Alerts)
│   │   ├── AudioService.swift (AVAudioSession & Siren Engine)
│   │   ├── MotionService.swift (CoreMotion & CMPedometer)
│   │   ├── HapticService.swift (Continuous Vibrations)
│   │   └── AlarmScheduler.swift (SwiftData Sync)
│   ├── Views/
│   │   ├── AlarmList/        # Main Dashboard & Nightstand Mode
│   │   ├── AlarmEdit/        # Time, Day, Sound & Mission Configuration
│   │   ├── Ringing/          # Full Screen Emergency Ringing Override
│   │   ├── Missions/         # Math, Shake, Steps/Squats, Memory, Typing
│   │   ├── Settings/         # Entitlement Status & Emergency Test Alarm
│   │   └── Components/       # GlassCard & NeonButton
│   └── Assets.xcassets/
├── Package.swift             # Swift Package Manager Manifest
├── APPLE_ENTITLEMENT_GUIDE.md # Apple App Store Submission Guide
└── README.md
```

---

## 🚀 How to Run in Xcode

1. Open `WakeWake.xcodeproj` in **Xcode 15+** or **Xcode 16/17/18**.
2. Select your target device or iOS Simulator (iOS 17.0+).
3. Build and Run (`⌘ + R`).
4. To test the critical alarm immediately, open **Settings** inside the app and tap **"TEST ALARM & MISSION NOW"**.

---

## 📄 Licensing & Entitlements
Refer to [APPLE_ENTITLEMENT_GUIDE.md](file:///home/albibenni/benni-projects/wake-wake/APPLE_ENTITLEMENT_GUIDE.md) for details on applying for Apple's Critical Alert entitlement for App Store release.
