//
//  MissionContainerView.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import SwiftUI

public struct MissionContainerView: View {
    let alarm: Alarm
    let onCompleted: () -> Void
    let onFailed: () -> Void

    @State private var timeRemaining: Int = 60
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init(alarm: Alarm, onCompleted: @escaping () -> Void, onFailed: @escaping () -> Void) {
        self.alarm = alarm
        self.onCompleted = onCompleted
        self.onFailed = onFailed
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Mission Header with Timer & Give Up Button
            HStack {
                Button(action: {
                    HapticService.shared.errorNotification()
                    onFailed()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Give Up")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(Color.red.opacity(0.18))
                    .cornerRadius(20)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .foregroundColor(timeRemaining <= 10 ? .red : .yellow)
                    Text("\(timeRemaining)s")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(timeRemaining <= 10 ? .red : .yellow)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 14)
                .background(Color.white.opacity(0.12))
                .cornerRadius(20)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color.black)

            Group {
                switch alarm.missionType {
                case .math:
                    MathMissionView(
                        difficulty: alarm.missionDifficulty,
                        targetCount: alarm.missionTargetCount,
                        onCompleted: onCompleted
                    )
                case .shake:
                    ShakeMissionView(
                        targetCount: alarm.missionTargetCount,
                        onCompleted: onCompleted
                    )
                case .stepsSquats:
                    StepsSquatsMissionView(
                        targetCount: alarm.missionTargetCount,
                        onCompleted: onCompleted
                    )
                case .memory:
                    MemoryMissionView(
                        targetRounds: alarm.missionTargetCount,
                        onCompleted: onCompleted
                    )
                case .typing, .qrScan:
                    TypingMissionView(
                        onCompleted: onCompleted
                    )
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                HapticService.shared.errorNotification()
                onFailed()
            }
        }
    }
}
