//
//  AlarmRingingView.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import SwiftUI
import SwiftData

public struct AlarmRingingView: View {
    let alarm: Alarm
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var isMissionActive: Bool = false
    @State private var isPulseAnimating: Bool = false
    @State private var showSnoozedToast: Bool = false

    public init(alarm: Alarm, onDismiss: @escaping () -> Void) {
        self.alarm = alarm
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            // High Voltage Dark Background with glowing pulsing aura
            Color.black.ignoresSafeArea()

            RadialGradient(
                colors: [
                    isPulseAnimating ? Color.red.opacity(0.45) : Color.orange.opacity(0.25),
                    Color.black
                ],
                center: .center,
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulseAnimating)

            if isMissionActive {
                MissionContainerView(
                    alarm: alarm,
                    onCompleted: {
                        // Mission successfully completed! Stop alarm completely
                        AudioService.shared.stopAlarmSound()
                        HapticService.shared.stopVibration()
                        HapticService.shared.successNotification()
                        onDismiss()
                    },
                    onFailed: {
                        // Challenge failed or timed out! Resume loud alarm siren
                        withAnimation {
                            isMissionActive = false
                        }
                        AudioService.shared.startAlarmSound(sound: alarm.sound, volume: alarm.volume)
                        if alarm.isVibrationEnabled {
                            HapticService.shared.startContinuousVibration()
                        }
                    }
                )
            } else {
                VStack(spacing: 32) {
                    Spacer()

                    // Ringing Icon Indicator
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .scaleEffect(isPulseAnimating ? 1.25 : 0.95)

                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 64, weight: .black))
                            .foregroundColor(.red)
                    }

                    // Alarm Details
                    VStack(spacing: 8) {
                        Text(alarm.formattedTime)
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundColor(.white)

                        Text(alarm.label)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white.opacity(0.9))

                        HStack(spacing: 6) {
                            Image(systemName: alarm.missionType.iconName)
                            Text("Mission required: \(alarm.missionType.title)")
                        }
                        .font(.subheadline)
                        .foregroundColor(.yellow)
                        .padding(.top, 4)
                    }

                    Spacer()

                    // Action Controls
                    VStack(spacing: 16) {
                        NeonButton(
                            title: "START WAKE-UP MISSION",
                            iconName: "play.circle.fill",
                            color: .cyan,
                            textColor: .black
                        ) {
                            // Pause alarm while doing challenge
                            AudioService.shared.stopAlarmSound()
                            HapticService.shared.stopVibration()
                            
                            withAnimation {
                                isMissionActive = true
                            }
                        }

                        if alarm.isSnoozeEnabled {
                            Button(action: {
                                snoozeAlarm()
                            }) {
                                HStack {
                                    Image(systemName: "moon.zzz.fill")
                                    Text("Snooze (\(alarm.snoozeDurationMinutes) min)")
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            isPulseAnimating = true
            AudioService.shared.startAlarmSound(sound: alarm.sound, volume: alarm.volume)
            if alarm.isVibrationEnabled {
                HapticService.shared.startContinuousVibration()
            }
        }
        .onDisappear {
            AudioService.shared.stopAlarmSound()
            HapticService.shared.stopVibration()
        }
    }

    private func snoozeAlarm() {
        AudioService.shared.stopAlarmSound()
        HapticService.shared.stopVibration()
        AlarmScheduler.shared.snoozeAlarm(alarm, minutes: alarm.snoozeDurationMinutes, modelContext: modelContext)
        onDismiss()
    }
}
