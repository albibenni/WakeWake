# 🍎 Apple Critical Alerts Entitlement & App Store Submission Guide

This document explains how **WakeWake** overrides iOS system constraints (Silent Mode, Do Not Disturb, Sleep Focus, and Low Battery Mode) and how to request Apple's entitlement approval for App Store publishing.

---

## 1. How System Override Works in WakeWake

To reliably wake up users regardless of device state, **WakeWake** uses a combination of three iOS frameworks:

### A. Critical Alerts (`UNAuthorizationOptions.criticalAlert`)
- **What it does:** Allows local notifications to play sounds even if the physical Silent/Mute switch is flipped ON, or if Do Not Disturb / Sleep Focus mode is active.
- **Payload setup:** Uses `UNNotificationSound.defaultCriticalSound(withAudioVolume: 1.0)` to play alarm sound at maximum volume.
- **Entitlement required:** `com.apple.developer.usernotifications.critical-alerts`.

### B. Audio Session Override (`AVAudioSession`)
- **Category:** `.playback`
- **Mode:** `.alarm`
- **Options:** `.duckOthers`, `.interruptSpokenAudioAndMixWithOthers`
- **What it does:** Instructs iOS audio hardware to route alarm sound directly to the main speaker at high output gain, ducking any background media (e.g., Spotify, Podcasts).

### C. Motion Sensor Interlock (`CoreMotion`)
- The loud alarm audio loop stays active until the user completes their designated **Wake-Up Mission** (Math, Shake, Steps/Squats, Memory, or Typing).

---

## 2. Requesting Apple Approval for Critical Alerts

Apple tightly restricts Critical Alerts to safety, medical, and alarm apps. To publish **WakeWake** on the iOS App Store, you must request entitlement approval from Apple.

### Step 1: Submit the Entitlement Request Form
1. Log in to your **Apple Developer Account**.
2. Visit the [Apple Critical Alerts Request Form](https://developer.apple.com/contact/request/notifications-critical-alerts-entitlement/).
3. Fill out the application details:
   - **App Name:** WakeWake (or your app title)
   - **Bundle Identifier:** `com.wakewake.actionalarm`
   - **App Category:** Utilities / Productivity / Health & Fitness
   - **Explanation of Use:** 
     > *"WakeWake is an action alarm app designed to wake deep sleepers. Critical Alert authorization is necessary so scheduled alarm sirens trigger loud audio even if the device is set to Silent Mode or Sleep Focus. Without Critical Alerts, scheduled morning alarms would be silenced by iOS Focus modes, causing users to miss work or critical appointments."*

### Step 2: Enable Entitlement in Xcode
Once Apple approves the request for your Team ID:
1. Open `WakeWake.xcodeproj` in Xcode.
2. Select the **WakeWake** target -> **Signing & Capabilities**.
3. Click **+ Capability** -> Add **Critical Alerts**.
4. Xcode will automatically update `WakeWake.entitlements`.

---

## 3. App Store Review Checklist

When submitting your app build to App Store Connect:

- [x] Ensure `NSMotionUsageDescription` is in `Info.plist` (Included in `WakeWake/App/Info.plist`).
- [x] Ensure `NSCameraUsageDescription` is in `Info.plist` (Included in `WakeWake/App/Info.plist`).
- [x] Ensure `UIBackgroundModes` contains `audio` (Included in `WakeWake/App/Info.plist`).
- [x] Include a short video recording in the App Review notes showing the alarm sounding while the phone is in Silent Mode.
