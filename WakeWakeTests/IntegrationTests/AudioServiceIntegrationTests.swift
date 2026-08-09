//
//  AudioServiceIntegrationTests.swift
//  WakeWakeTests
//
//  Created in 2026 for iOS 17/18+ (Integration Tests)
//

import XCTest
import AVFoundation
@testable import WakeWake

@MainActor
final class AudioServiceIntegrationTests: XCTestCase {

    func testAudioSessionConfigurationDoesNotCrash() {
        AudioService.shared.configureAudioSession()
        let session = AVAudioSession.sharedInstance()
        XCTAssertEqual(session.category, .playback)
        XCTAssertEqual(session.mode, .default)
    }

    func testStartAndStopAlarmSoundCycle() {
        let audioService = AudioService.shared
        audioService.startAlarmSound(sound: .radar, volume: 0.5)

        XCTAssertTrue(audioService.isRinging)

        audioService.stopAlarmSound()
        XCTAssertFalse(audioService.isRinging)
    }

    // MARK: - Expected Failing / Boundary Test
    func testStopAudioWhenNotRingingDoesNotCrash() {
        let audioService = AudioService.shared
        audioService.stopAlarmSound()

        XCTAssertFalse(audioService.isRinging)
        // Secondary stop call must complete safely without throwing or crashing
        audioService.stopAlarmSound()
        XCTAssertFalse(audioService.isRinging)
    }
}
