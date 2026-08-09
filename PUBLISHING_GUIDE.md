# 🚀 Complete App Store Publishing & Entitlement Guide for WakeWake

This guide outlines the step-by-step process to configure, build, test, and publish **WakeWake** to the Apple App Store.

---

## 📋 Table of Contents
1. [Prerequisites](#1-prerequisites)
2. [Step 1: Apple Critical Alerts Entitlement Approval](#step-1-apple-critical-alerts-entitlement-approval)
3. [Step 2: Xcode Project Configuration](#step-2-xcode-project-configuration)
4. [Step 3: Background Modes & Permissions Checklist](#step-3-background-modes--permissions-checklist)
5. [Step 4: Creating App Store Connect Record](#step-4-creating-app-store-connect-record)
6. [Step 5: Archiving and Uploading Build](#step-5-archiving-and-uploading-build)
7. [Step 6: App Store Review Guidelines & Demo Video](#step-6-app-store-review-guidelines--demo-video)

---

## 1. Prerequisites

Before beginning the submission process:
- Active **Apple Developer Program** membership ($99/year).
- macOS device with **Xcode 15+** or **Xcode 16/17+**.
- Registered iOS device for hardware motion/audio testing.
- App assets ready:
  - 1024x1024 App Icon (`AppIcon.appiconset`)
  - App Store Screenshots (6.7" iPhone, 6.5" iPhone)

---

## Step 1: Apple Critical Alerts Entitlement Approval

Because **WakeWake** plays loud alarm sounds even when the physical Mute Switch is ON or during **Sleep Focus / Do Not Disturb**, Apple requires entitlement authorization for `com.apple.developer.usernotifications.critical-alerts`.

### Submission Instructions:
1. Log in to your Apple Developer Account.
2. Go to the [Apple Critical Alerts Request Form](https://developer.apple.com/contact/request/notifications-critical-alerts-entitlement/).
3. Fill in the required fields:
   - **App Name:** WakeWake (or your custom app name)
   - **Bundle ID:** `com.wakewake.actionalarm`
   - **App Store Category:** Utilities / Productivity
   - **Detailed Justification:**
     > *"WakeWake is an action alarm app designed for deep sleepers. Critical Alert authorization is necessary so scheduled morning alarms play loud audio even if the device is set to Silent Mode or Sleep Focus. Without Critical Alerts, scheduled morning alarms would be silenced by iOS Focus modes, causing users to miss work or critical appointments."*
4. Submit the form and wait for approval confirmation from Apple Developer Support (typically 1–3 business days).

---

## Step 2: Xcode Project Configuration

1. Open `WakeWake.xcodeproj` in Xcode.
2. Select the top-level **WakeWake** project in the Project Navigator.
3. Select the **WakeWake** target under **Targets**.
4. Go to the **Signing & Capabilities** tab:
   - Select your **Development Team**.
   - Set a unique **Bundle Identifier** (e.g. `com.yourcompany.wakewake`).
   - Click **+ Capability** and add:
     - **Background Modes** (check *Audio, AirPlay, and Picture in Picture*).
     - **Critical Alerts** (appears once Apple approves your account entitlement).

---

## Step 3: Background Modes & Permissions Checklist

Verify that `WakeWake/App/Info.plist` contains the following keys:

| Key | Type | Description / Value |
| :--- | :--- | :--- |
| `UIBackgroundModes` | Array | `audio`, `processing` |
| `NSMotionUsageDescription` | String | "WakeWake needs motion sensor access to count steps and squats for wake-up missions." |
| `NSCameraUsageDescription` | String | "WakeWake needs camera access to scan barcodes for wake-up missions." |

Verify that `WakeWake/Entitlements/WakeWake.entitlements` contains:
```xml
<key>com.apple.developer.usernotifications.critical-alerts</key>
<true/>
```

---

## Step 4: Creating App Store Connect Record

1. Go to [App Store Connect](https://appstoreconnect.apple.com/).
2. Select **My Apps** -> **+ New App**.
3. Choose **iOS**, select your Bundle ID, and assign a unique SKU (e.g. `wakewake-ios-01`).
4. Fill in standard metadata:
   - **Title:** WakeWake - Action Alarm Clock
   - **Subtitle:** Loud Alarm & Wake-up Missions
   - **Description:** Outline Alarmy-style features (Math, Shake, Steps/Squats missions, Critical Alerts).
   - **Keywords:** `alarm, loud alarm, wake up, alarmy, math alarm, step alarm, critical alert`
   - **Support URL & Privacy Policy URL**

---

## Step 5: Archiving and Uploading Build

1. Connect a generic iOS device in Xcode (`Any iOS Device (arm64)`).
2. Select **Product** -> **Archive** from the Xcode menu bar.
3. Once the archive completes, the **Organizer** window will open automatically.
4. Click **Validate App** to run automated checks against App Store submission rules.
5. Click **Distribute App** -> Select **App Store Connect** -> **Upload**.

---

## Step 6: App Store Review Guidelines & Demo Video

Apple App Review guidelines strictly inspect Critical Alert and Motion sensor usage.

### Best Practices for Review Submission:
1. **Provide Reviewer Notes:**
   Explain that the app requires Critical Alerts for alarm reliability.
2. **Provide a Video Link:**
   Attach a unlisted YouTube or Cloud video link showing the alarm triggering while the device is in Silent Mode / Sleep Focus.
3. **Include Test Credentials / Demo Instructions:**
   Tell the reviewer to open **Settings** -> tap **"TEST ALARM & MISSION NOW"** to test sound override and mission disarm without waiting for a scheduled alarm time.
