//
//  SettingsView.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationService = NotificationService.shared

    var onTestAlarm: ((Alarm) -> Void)? = nil

    public init(onTestAlarm: ((Alarm) -> Void)? = nil) {
        self.onTestAlarm = onTestAlarm
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Critical Alert Status Banner
                        GlassCard(
                            cornerRadius: 20,
                            borderColor: notificationService.isCriticalAlertAuthorized ? .green.opacity(0.4) : .yellow.opacity(0.4)
                        ) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: notificationService.isCriticalAlertAuthorized ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                                        .font(.title2)
                                        .foregroundColor(notificationService.isCriticalAlertAuthorized ? .green : .yellow)

                                    Text(notificationService.isCriticalAlertAuthorized ? "Critical Alerts Enabled" : "Critical Alerts Recommended")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }

                                Text("Critical Alerts allow WakeWake to play loud alarm siren even if your iPhone is in Mute Mode, Do Not Disturb, or Sleep Focus.")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Button(action: {
                                    Task {
                                        _ = await notificationService.requestPermissions()
                                    }
                                }) {
                                    Text(notificationService.isCriticalAlertAuthorized ? "Permissions Granted" : "Request Critical Alert Access")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(notificationService.isCriticalAlertAuthorized ? .green : .black)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(notificationService.isCriticalAlertAuthorized ? Color.green.opacity(0.15) : Color.yellow)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Emergency Test Trigger Card
                        GlassCard(cornerRadius: 20, borderColor: .cyan.opacity(0.3)) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "bell.badge.waveform.fill")
                                        .foregroundColor(.cyan)
                                    Text("Test Loud Alarm Sound")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }

                                Text("Test the loud emergency siren and mission flow right now to verify speaker volume and focus overrides.")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                NeonButton(
                                    title: "TEST ALARM & MISSION NOW",
                                    iconName: "play.fill",
                                    color: .cyan,
                                    textColor: .black
                                ) {
                                    let testSound: AlarmSound = AudioService.shared.getCustomRingtoneURL() != nil ? .customRingtone : .radar
                                    let demoAlarm = Alarm(
                                        label: "Test Mission Alarm",
                                        isEnabled: true,
                                        sound: testSound,
                                        volume: 1.0,
                                        missionType: .math,
                                        missionDifficulty: .easy,
                                        missionTargetCount: 2
                                    )
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        onTestAlarm?(demoAlarm)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // iOS Best Practice / DND Guide Card
                        GlassCard(cornerRadius: 20, borderColor: .white.opacity(0.1)) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("HOW OVERSIGHT WORKS ON iOS")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.gray)

                                guideRow(
                                    icon: "speaker.wave.3.fill",
                                    title: "AVAudioSession Category Override",
                                    detail: "Uses .playback category with .alarm mode to play sound on speaker hardware regardless of mute switch position."
                                )

                                Divider().background(Color.white.opacity(0.1))

                                guideRow(
                                    icon: "bell.badge.fill",
                                    title: "Apple Critical Alerts Entitlement",
                                    detail: "Configured with com.apple.developer.usernotifications.critical-alerts to breach Sleep Focus and Silent Mode."
                                )

                                Divider().background(Color.white.opacity(0.1))

                                guideRow(
                                    icon: "figure.walk",
                                    title: "CoreMotion Mission Verification",
                                    detail: "Sensors track accelerometer pulses and CMPedometer count before disarming loud audio playback."
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Alarm Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
                    .foregroundColor(.cyan)
                }
            }
        }
    }

    private func guideRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.cyan)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.white)

                Text(detail)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}
