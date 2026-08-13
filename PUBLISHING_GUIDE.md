# WakeWake App Store release checklist

## Product scope

WakeWake is an **iPhone-only action alarm app**. It uses local notifications to deliver alarm reminders and opens the alarm mission only after the person interacts with the notification. It must not claim to replace the Apple Clock alarm or bypass Silent mode, Focus, or Do Not Disturb.

## Before archiving

1. Use a unique production bundle identifier and a valid Apple Developer team.
2. Verify the target device family is **iPhone** only.
3. Add an App Icon, support URL, and privacy-policy URL.
4. Ensure the camera permission is requested only after the QR/photo mission is actually implemented. Remove its usage description until then.
5. Ensure the motion explanation matches the enabled shake/steps/squat missions.
6. Use **Time Sensitive** notifications only for alarms that are due now; provide an in-app notification settings screen.

## Hardware test matrix

Test on current and previous supported iPhone/iOS combinations:

- one-off and weekday repeating alarms;
- notification actions, including snooze and Start Mission;
- locked, foregrounded, and terminated app;
- Focus enabled/disabled and notification permission disabled;
- time-zone changes and daylight-saving transitions;
- audio interruption, headphones/Bluetooth changes, and motion-permission denial.

## App Review notes

Give reviewers a short path to create an alarm one or two minutes ahead, trigger every mission, and verify the `Snooze`/`Start Mission` actions. Describe the actual behavior precisely: notification delivery occurs outside the app; looping mission audio begins after the app is opened.
