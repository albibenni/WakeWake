//
//  MotionService.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import Foundation
import CoreMotion
import Combine

@MainActor
public final class MotionService: ObservableObject {
    public static let shared = MotionService()

    private let motionManager = CMMotionManager()
    private let pedometer = CMPedometer()

    @Published public var shakeCount: Int = 0
    @Published public var stepCount: Int = 0
    @Published public var squatCount: Int = 0
    @Published public var isMotionActive: Bool = false
    @Published public var motionErrorMessage: String?

    private var lastAcceleration: CMAcceleration?
    private var squatState: SquatState = .standing
    private var pedometerStartDate: Date?

    private enum SquatState {
        case standing
        case squatted
    }

    private init() {}

    // MARK: - Shake Tracking
    public func startShakeTracking(targetCount: Int, onProgress: @escaping (Int) -> Void) {
        shakeCount = 0
        isMotionActive = true

        guard motionManager.isAccelerometerAvailable else {
            motionErrorMessage = "Accelerometer hardware unavailable on this device."
            return
        }

        motionManager.accelerometerUpdateInterval = 0.05 // 20Hz update
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }

            let accel = data.acceleration
            if let last = self.lastAcceleration {
                let deltaX = abs(accel.x - last.x)
                let deltaY = abs(accel.y - last.y)
                let deltaZ = abs(accel.z - last.z)

                // High threshold for a genuine intentional vigorous shake
                let totalDelta = deltaX + deltaY + deltaZ
                if totalDelta > 2.8 {
                    Task { @MainActor in
                        self.shakeCount += 1
                        onProgress(self.shakeCount)
                        HapticService.shared.lightImpact()
                    }
                }
            }
            self.lastAcceleration = accel
        }
    }

    public func stopShakeTracking() {
        motionManager.stopAccelerometerUpdates()
        lastAcceleration = nil
        isMotionActive = false
    }

    // MARK: - Step & Squat Tracking
    public func startStepsAndSquatsTracking(
        targetCount: Int,
        onStepProgress: @escaping (Int) -> Void,
        onSquatProgress: @escaping (Int) -> Void
    ) {
        stepCount = 0
        squatCount = 0
        isMotionActive = true
        pedometerStartDate = Date()

        // 1. Pedometer step tracking
        if CMPedometer.isStepCountingAvailable(), let startDate = pedometerStartDate {
            pedometer.startUpdates(from: startDate) { [weak self] data, error in
                guard let self = self, let data = data else { return }
                let steps = data.numberOfSteps.intValue
                Task { @MainActor in
                    self.stepCount = steps
                    onStepProgress(steps)
                }
            }
        }

        // 2. Device motion / Accelerometer for Squat detection (up/down pitch change)
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let self = self, let motion = motion else { return }

                // Pitch angle in radians: ~1.5 is vertical standing, < 0.6 indicates crouching/squatting
                let pitch = abs(motion.attitude.pitch)
                let userAccelY = motion.userAcceleration.y

                Task { @MainActor in
                    switch self.squatState {
                    case .standing:
                        // User lowered body into squat position
                        if pitch < 0.7 || userAccelY < -0.4 {
                            self.squatState = .squatted
                        }
                    case .squatted:
                        // User stood back up
                        if pitch > 1.2 && userAccelY > 0.3 {
                            self.squatState = .standing
                            self.squatCount += 1
                            onSquatProgress(self.squatCount)
                            HapticService.shared.successNotification()
                        }
                    }
                }
            }
        }
    }

    public func stopStepsAndSquatsTracking() {
        pedometer.stopUpdates()
        motionManager.stopDeviceMotionUpdates()
        isMotionActive = false
        pedometerStartDate = nil
    }
}
