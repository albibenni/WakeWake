//
//  AlarmSoundTests.swift
//  WakeWakeTests
//
//  Created in 2026 for iOS 17/18+ (XCTest Unit Tests)
//

import XCTest
@testable import WakeWake

final class AlarmSoundTests: XCTestCase {

    func testAlarmSoundCasesHaveValidFilenames() {
        for sound in AlarmSound.allCases {
            XCTAssertFalse(sound.displayName.isEmpty)
            XCTAssertFalse(sound.filename.isEmpty)
            XCTAssertTrue(sound.filename.hasSuffix(".mp3") || sound.filename.hasSuffix(".wav"))
        }
    }

    func testAlarmSoundRawValueDecoding() {
        let sound = AlarmSound(rawValue: "emergency_bell")
        XCTAssertEqual(sound, .emergencyBell)

        let invalidSound = AlarmSound(rawValue: "non_existent_audio_file")
        XCTAssertNil(invalidSound, "Invalid sound raw value must evaluate to nil")
    }
}
