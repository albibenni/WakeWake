//
//  StepsSquatsMissionView.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import SwiftUI

public struct StepsSquatsMissionView: View {
    let targetCount: Int
    let onCompleted: () -> Void

    @StateObject private var motionService = MotionService.shared
    @State private var totalCompleted: Int = 0

    public init(targetCount: Int, onCompleted: @escaping () -> Void) {
        self.targetCount = targetCount
        self.onCompleted = onCompleted
    }

    public var body: some View {
        VStack(spacing: 24) {
            Text("Physical Motion Mission")
                .font(.headline)
                .foregroundColor(.gray)

            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(.green)
                    .scaleEffect(motionService.stepCount > 0 ? 1.1 : 1.0)
                    .animation(.spring(), value: motionService.stepCount)

                Text("Get out of bed & move!")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)

                Text("Walk or complete squats to shut down the alarm.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            // Stat Cards
            HStack(spacing: 16) {
                GlassCard(cornerRadius: 20, borderColor: .green.opacity(0.3)) {
                    VStack(spacing: 8) {
                        Text("STEPS")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.gray)

                        Text("\(motionService.stepCount)")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity)
                }

                GlassCard(cornerRadius: 20, borderColor: .orange.opacity(0.3)) {
                    VStack(spacing: 8) {
                        Text("SQUATS")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.gray)

                        Text("\(motionService.squatCount)")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(.orange)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Progress Bar
            VStack(spacing: 8) {
                HStack {
                    Text("Total Activity Progress")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(totalCompleted) / \(targetCount)")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.cyan)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 14)

                        Capsule()
                            .fill(
                                LinearGradient(colors: [.green, .cyan], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geo.size.width * min(CGFloat(totalCompleted) / CGFloat(targetCount), 1.0), height: 14)
                            .animation(.spring(), value: totalCompleted)
                    }
                }
                .frame(height: 14)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            motionService.startStepsAndSquatsTracking(
                targetCount: targetCount,
                onStepProgress: { steps in
                    updateTotal(steps: steps, squats: motionService.squatCount)
                },
                onSquatProgress: { squats in
                    updateTotal(steps: motionService.stepCount, squats: squats)
                }
            )
        }
        .onDisappear {
            motionService.stopStepsAndSquatsTracking()
        }
    }

    private func updateTotal(steps: Int, squats: Int) {
        // 1 squat = 3 steps equivalent
        let combined = steps + (squats * 3)
        self.totalCompleted = combined
        if combined >= targetCount {
            motionService.stopStepsAndSquatsTracking()
            onCompleted()
        }
    }
}
