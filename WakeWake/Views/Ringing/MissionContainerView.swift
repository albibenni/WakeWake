//
//  MissionContainerView.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import SwiftUI

public struct MissionContainerView: View {
    let alarm: Alarm
    let onMissionFinished: () -> Void

    public init(alarm: Alarm, onMissionFinished: @escaping () -> Void) {
        self.alarm = alarm
        self.onMissionFinished = onMissionFinished
    }

    public var body: some View {
        Group {
            switch alarm.missionType {
            case .math:
                MathMissionView(
                    difficulty: alarm.missionDifficulty,
                    targetCount: alarm.missionTargetCount,
                    onCompleted: onMissionFinished
                )
            case .shake:
                ShakeMissionView(
                    targetCount: alarm.missionTargetCount,
                    onCompleted: onMissionFinished
                )
            case .stepsSquats:
                StepsSquatsMissionView(
                    targetCount: alarm.missionTargetCount,
                    onCompleted: onMissionFinished
                )
            case .memory:
                MemoryMissionView(
                    targetRounds: alarm.missionTargetCount,
                    onCompleted: onMissionFinished
                )
            case .typing, .qrScan:
                TypingMissionView(
                    onCompleted: onMissionFinished
                )
            }
        }
    }
}
