//
//  MissionPickerView.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import SwiftUI

public struct MissionPickerView: View {
    @Binding var selectedMissionType: MissionType
    @Binding var difficulty: MissionDifficulty
    @Binding var targetCount: Int

    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Mission Type Cards Grid
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SELECT WAKE-UP MISSION")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.gray)
                                .padding(.horizontal)

                            ForEach(MissionType.allCases) { mission in
                                Button(action: {
                                    HapticService.shared.lightImpact()
                                    selectedMissionType = mission
                                    targetCount = mission.defaultTargetCount
                                }) {
                                    GlassCard(
                                        cornerRadius: 18,
                                        borderColor: selectedMissionType == mission ? .cyan : .white.opacity(0.1),
                                        backgroundColor: selectedMissionType == mission ? .cyan.opacity(0.15) : .black.opacity(0.4)
                                    ) {
                                        HStack(spacing: 16) {
                                            ZStack {
                                                Circle()
                                                    .fill(selectedMissionType == mission ? .cyan : Color.white.opacity(0.1))
                                                    .frame(width: 44, height: 44)

                                                Image(systemName: mission.iconName)
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(selectedMissionType == mission ? .black : .white)
                                            }

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(mission.title)
                                                    .font(.headline)
                                                    .foregroundColor(.white)

                                                Text(mission.subtitle)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }

                                            Spacer()

                                            if selectedMissionType == mission {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.cyan)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Mission Settings Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("MISSION CONFIGURATION")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.gray)
                                .padding(.horizontal)

                            GlassCard(cornerRadius: 20, borderColor: .white.opacity(0.1)) {
                                VStack(alignment: .leading, spacing: 20) {
                                    // Difficulty Picker (for Math/Memory)
                                    if selectedMissionType == .math {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Difficulty Level")
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(.white)

                                            Picker("Difficulty", selection: $difficulty) {
                                                ForEach(MissionDifficulty.allCases) { diff in
                                                    Text(diff.title).tag(diff)
                                                }
                                            }
                                            .pickerStyle(.segmented)
                                        }
                                    }

                                    // Target Count Stepper
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Repeat Count / Target")
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(.white)

                                            Text(targetCountText(for: selectedMissionType, count: targetCount))
                                                .font(.caption)
                                                .foregroundColor(.cyan)
                                        }

                                        Spacer()

                                        Stepper("", value: $targetCount, in: 1...100)
                                            .labelsHidden()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Wake-Up Mission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .bold()
                    .foregroundColor(.cyan)
                }
            }
        }
    }

    private func targetCountText(for type: MissionType, count: Int) -> String {
        switch type {
        case .math: return "\(count) math problems"
        case .shake: return "\(count) vigorous shakes"
        case .stepsSquats: return "\(count) steps / squat units"
        case .memory: return "\(count) pattern rounds"
        case .typing: return "1 declaration phrase"
        case .qrScan: return "1 QR code scan"
        }
    }
}
