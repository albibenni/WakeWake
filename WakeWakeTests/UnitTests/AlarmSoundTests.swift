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
        }
    }

    func testAlarmSoundRawValueDecoding() {
        let sound = AlarmSound(rawValue: "radar")
        XCTAssertEqual(sound, .radar)

        let invalidSound = AlarmSound(rawValue: "non_existent_audio_file")
        XCTAssertNil(invalidSound, "Invalid sound raw value must evaluate to nil")
    }

    func testCustomRingtoneDisplayNameFormatting() {
        UserDefaults.standard.set("MyTestSong", forKey: "CustomRingtoneDisplayName")
        let sound = AlarmSound.customRingtone
        XCTAssertTrue(sound.displayName.contains("MyTestSong"), "Custom ringtone display name must reflect imported title!")
    }
}
