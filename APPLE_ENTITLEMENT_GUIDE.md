# WakeWake iOS notification policy

WakeWake is a third-party iPhone alarm app. iOS delivers its local notifications while the app is not running, but does not automatically launch WakeWake into a full-screen mission or start its looping app audio.

## Supported behavior

- Schedule a local notification for each one-off alarm, or one repeating calendar notification for each selected weekday.
- Use the **Time Sensitive** interruption level when it is enabled in the person's notification settings.
- Open the mission and play looped foreground audio only after the person taps **Start Mission** or opens the notification.
- Store all mission and alarm data on device unless the privacy policy says otherwise.

## Critical Alerts

WakeWake does not request Critical Alerts. Apple reserves the entitlement for exceptional health and safety use cases. Do not claim that WakeWake bypasses the Ring/Silent switch, Do Not Disturb, or Sleep Focus.

If the product changes to an Apple-approved health or safety use case, obtain the entitlement from Apple first, add the Critical Alerts capability and provisioning profile, request `.criticalAlert`, and use a critical notification sound. That is a separate product/review decision, not a fallback for conventional wake-up alarms.

## Review checklist

- Explain notification and motion permissions at the moment each feature is enabled.
- Test every alarm on real iPhones: locked, foregrounded, terminated, Focus on/off, low power, time-zone change, and daylight-saving transition.
- Provide App Review with steps to test every mission and all notification actions.
