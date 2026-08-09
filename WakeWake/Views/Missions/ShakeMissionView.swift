//
//  ShakeMissionView.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import SwiftUI

public struct ShakeMissionView: View {
    let targetCount: Int
    let onCompleted: () -> Void

    @StateObject private var motionService = MotionService.shared
    @State private var progress: Double = 0.0

    public init(targetCount: Int, onCompleted: @escaping () -> Void) {
        self.targetCount = targetCount
        self.onCompleted = onCompleted
    }

    public var body: some View {
        VStack(spacing: 32) {
            Text("Shake Mission")
                .font(.headline)
                .foregroundColor(.gray)

            Spacer()

            // Large Circular Shake Gauge
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 24)
                    .frame(width: 240, height: 240)

                Circle()
                    .trim(from: 0.0, to: min(CGFloat(progress), 1.0))
                    .stroke(
                        AngularGradient(
                            colors: [.cyan, .yellow, .orange, .red],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 240, height: 240)
                    .animation(.spring(), value: progress)

                VStack(spacing: 8) {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.yellow)

                    Text("\(motionService.shakeCount) / \(targetCount)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text("SHAKES")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.gray)
                }
            }

            Text("Vigorously shake your phone until the circle completes!")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            motionService.startShakeTracking(targetCount: targetCount) { count in
                self.progress = Double(count) / Double(targetCount)
                if count >= targetCount {
                    motionService.stopShakeTracking()
                    onCompleted()
                }
            }
        }
        .onDisappear {
            motionService.stopShakeTracking()
        }
    }
}
