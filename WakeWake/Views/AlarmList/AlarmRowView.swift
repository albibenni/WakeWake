//
//  AlarmRowView.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import SwiftUI

public struct AlarmRowView: View {
    @Bindable var alarm: Alarm
    let onToggle: (Bool) -> Void
    let onTap: () -> Void

    public init(alarm: Alarm, onToggle: @escaping (Bool) -> Void, onTap: @escaping () -> Void) {
        self.alarm = alarm
        self.onToggle = onToggle
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            GlassCard(
                cornerRadius: 22,
                borderColor: alarm.isEnabled ? .cyan.opacity(0.3) : .white.opacity(0.1),
                backgroundColor: alarm.isEnabled ? .cyan.opacity(0.06) : .black.opacity(0.4)
            ) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Time Display
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            let parts = alarm.hourMinuteString
                            Text("\(parts.hour):\(parts.minute)")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(alarm.isEnabled ? .white : .gray)

                            Text(parts.amPm)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(alarm.isEnabled ? .cyan : .gray.opacity(0.6))
                        }

                        // Label & Mission Badge
                        HStack(spacing: 8) {
                            Text(alarm.label)
                                .font(.subheadline)
                                .foregroundColor(alarm.isEnabled ? .white.opacity(0.9) : .gray)

                            Text("•")
                                .foregroundColor(.gray.opacity(0.5))

                            Text(alarm.repeatSummary)
                                .font(.caption)
                                .foregroundColor(alarm.isEnabled ? .cyan.opacity(0.8) : .gray)
                        }

                        // Mission Indicator Pill
                        HStack(spacing: 4) {
                            Image(systemName: alarm.missionType.iconName)
                            Text(alarm.missionType.title)
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(alarm.isEnabled ? .black : .white.opacity(0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(alarm.isEnabled ? Color.cyan : Color.white.opacity(0.15))
                        .cornerRadius(8)
                    }

                    Spacer()

                    // Enable / Disable Toggle Switch
                    Toggle("", isOn: $alarm.isEnabled)
                        .labelsHidden()
                        .tint(.cyan)
                        .onChange(of: alarm.isEnabled) { _, newValue in
                            HapticService.shared.lightImpact()
                            onToggle(newValue)
                        }
                }
                .padding(.vertical, 4)
            }
        }
        .buttonStyle(PressedScaleButtonStyle())
    }
}
