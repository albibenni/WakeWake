//
//  RepeatDayTests.swift
//  WakeWakeTests
//
//  Created in 2026 for iOS 17/18+ (XCTest Unit Tests)
//

import XCTest
@testable import WakeWake

final class RepeatDayTests: XCTestCase {

    func testRepeatDayBitmaskEncodingAndDecoding() {
        let inputDays: Set<RepeatDay> = [.monday, .wednesday, .friday]
        let encodedBitmask = RepeatDay.encode(inputDays)

        let decodedDays = RepeatDay.decode(encodedBitmask)
        XCTAssertEqual(decodedDays, inputDays)
    }

    func testEmptySetEncoding() {
        let empty: Set<RepeatDay> = []
        let mask = RepeatDay.encode(empty)
        XCTAssertEqual(mask, 0)
        XCTAssertTrue(RepeatDay.decode(0).isEmpty)
    }

    // MARK: - Expected Failing / Invalid Input Tests
    func testInvalidWeekdayIndexReturnsNil() {
        let invalidIndices = [0, -1, 8, 99]
        for idx in invalidIndices {
            let day = RepeatDay(weekdayIndex: idx)
            XCTAssertNil(day, "Weekday index \(idx) is invalid and must decode to nil")
        }
    }
}
