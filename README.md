# ⏰ WakeWake — iOS Action Alarm App

**WakeWake** is a high-performance, loud action alarm clock application built for iOS 17/18/26+ using **Swift 6**, **SwiftUI**, **SwiftData**, **UserNotifications Critical Alerts**, and **CoreMotion**.

WakeWake prevents users from falling back asleep by forcing them to complete interactive **Wake-Up Missions** before turning off the alarm siren.

---

## 🌟 Key Features

1. **System Override & Critical Alarm Reliability**
   - **Silent / Mute Switch Bypass:** Uses `AVAudioSession` `.playback` category and `.alarm` mode to ring loudly even when the silent switch is ON.
   - **Sleep Focus & DND Override:** Integrates Apple `UNAuthorizationOptions.criticalAlert` to sound alarms during Do Not Disturb / Sleep Focus modes.
   - **Offline Reliability:** Uses local `UNCalendarNotificationTrigger` and `UNTimeIntervalNotificationTrigger` (0 internet connection required, works 100% offline & in Airplane Mode).

2. **Standard iOS Alarm Ringtones & Custom Audio Import**
   - 🎵 **Official Stock iOS Ringtones:** Bundled studio `.mp3` tracks for **Radar** (Default Classic), **Reflection**, **Chime**, **Beacon**, **Apex**, **Circuit**, **Signal**, and **Slow Rise**.
   - 📁 **Custom Ringtone Import:** Import any `.mp3`, `.m4a`, `.wav`, or `.aac` file directly from iPhone Storage or iCloud Files app.
   - ⏯️ **Interactive Sound Preview:** Tap Play/Pause to preview ringtones instantly in the sound picker.

3. **Interactive Wake-Up Missions**
   - 🧮 **Math Problems:** Solve arithmetic equations (Easy, Medium, Hard, Extreme) with customizable problem counts.
   - 📱 **Shake Phone:** Vigorously shake the phone with live CoreMotion accelerometer progress gauge.
   - 🚶‍♂️ **Steps & Squats:** CMPedometer step tracking and accelerometer pitch-angle squat detector.
   - 🧩 **Memory Puzzle:** 3x3 Simon-Says glowing pattern sequence solver.
   - ✍️ **Motivational Typing:** Type morning declarations accurately without mistakes.

4. **Modern UI & Bedside Dashboard**
   - **Next Alarm Countdown:** Live header indicator showing time remaining until the next active alarm ("Ringing in 7h 12m").
   - **Glassmorphic Dark UI:** Modern neon accents, high contrast glass cards, tactile haptic feedback.
   - **Nightstand Mode:** Bedside digital clock view with smooth brightness dimmer.

---

## 📖 User Guide — How to Use WakeWake

### 1. Setting Up an Alarm
1. Tap the **`+`** button in the top-right corner of the main dashboard.
2. Select your wake-up **Time** using the wheel picker.
3. Choose **Repeat Days** (e.g. Mon–Fri or Every Day).
4. Enter an optional **Alarm Label** (e.g., *"Job Interview"*).

### 2. Choosing Sound & Volume
1. Tap **Alarm Sound** in the edit screen.
2. Select any standard iOS ringtone (e.g., **Radar**, **Reflection**, **Chime**).
3. Tap the **Play / Pause (⏯️)** button on any row to preview the sound.
4. Adjust the **Loudness Level** slider to your preferred volume.
5. Tap **Import Custom Ringtone** to pick a song file from your iPhone Files app.

### 3. Selecting a Wake-Up Mission
1. Tap **Wake-Up Mission** in the edit screen.
2. Pick your mission:
   - **Math Problems:** Set difficulty (Easy to Extreme) and number of problems.
   - **Shake Phone:** Set target shake count (10 to 100 shakes).
   - **Steps / Squats:** Set required physical steps or squats.
   - **Memory Puzzle:** Set required memory round count.
   - **Motivational Typing:** Set morning affirmation sentence.
3. Tap **Save** to activate your alarm.

### 4. When the Alarm Rings
- The alarm will pop up in full-screen mode and ring at full volume (bypassing mute switch & Do Not Disturb).
- **Snooze:** Tap **Snooze (5 min)** to delay the alarm.
- **Dismiss:** You **MUST** complete the assigned mission (e.g. solve math problems or shake your phone) before the alarm turns off.

---

## 💻 Developer & Makefile Commands

WakeWake includes a root [`Makefile`](file:///Users/benni-projects/WakeWake/Makefile) for fast terminal development, building, testing, and CI/CD integration:

| Command | Description |
| :--- | :--- |
| **`make help`** | Displays available Makefile commands. |
| **`make build`** | Builds the WakeWake app target for iOS Simulator. |
| **`make test`** | Runs unit & integration test suite (<4 seconds). |
| **`make coverage`** | Runs test suite with code coverage reporting. |
| **`make install-hooks`** | Installs Git pre-push hook in `.git/hooks/pre-push`. |
| **`make clean`** | Cleans build artifacts and derived data directory. |
| **`make list-destinations`** | Lists available Xcode simulator target destinations. |

---

## ⚓️ Git Pre-Push Hook (CI/CD Safety)

To ensure broken code is never pushed to remote Git repositories:

```bash
make install-hooks
```

Whenever you run `git push`, Git automatically executes `.git/hooks/pre-push`:
1. Runs `make build` to verify app target compiles cleanly.
2. Runs `make test` to verify all 29 unit and integration tests pass.
3. 🛑 If either step fails, `git push` is **aborted automatically**.

---

## 📄 Licensing & Entitlements
Refer to [APPLE_ENTITLEMENT_GUIDE.md](file:///Users/benni-projects/WakeWake/APPLE_ENTITLEMENT_GUIDE.md) for details on applying for Apple's Critical Alert entitlement for App Store release.
