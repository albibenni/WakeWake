//
//  MotionServiceIntegrationTests.swift
//  WakeWakeTests
//
//  Created in 2026 for iOS 17/18+ (Integration Tests)
//

import XCTest
@testable import WakeWake

@MainActor
final class MotionServiceIntegrationTests: XCTestCase {

    func testMotionServiceInitialState() {
        let service = MotionService.shared
        XCTAssertEqual(service.shakeCount, 0)
        XCTAssertEqual(service.stepCount, 0)
        XCTAssertEqual(service.squatCount, 0)
        XCTAssertFalse(service.isMotionActive)
    }

    func testStopTrackingResetsMotionState() {
        let service = MotionService.shared
        service.startShakeTracking(targetCount: 10) { _ in }

        service.stopShakeTracking()
        XCTAssertFalse(service.isMotionActive)
    }

    // MARK: - Expected Failing / Boundary Test
    func testMultipleStopTrackingCallsDoNotThrow() {
        let service = MotionService.shared
        service.stopShakeTracking()
        service.stopStepsAndSquatsTracking()
        XCTAssertFalse(service.isMotionActive)
    }
}
