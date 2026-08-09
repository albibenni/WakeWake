//
//  AudioService.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import Foundation
import AVFoundation
import AudioToolbox
import UIKit

@MainActor
public final class AudioService: NSObject, ObservableObject {
    public static let shared = AudioService()

    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var isPlayingToneEngine: Bool = false

    @Published public private(set) var isRinging: Bool = false

    private override init() {
        super.init()
    }

    /// Configure Audio Session to override Mute Switch, Do Not Disturb, and Low Battery Mode
    public func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback category ensures audio plays even when mute switch is ON or screen is locked
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
            print("🔊 AudioSession successfully configured for Alarm Playback.")
        } catch {
            print("❌ Failed to set AVAudioSession category: \(error.localizedDescription)")
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {}
        }
    }

    /// Start playing alarm sound loudly with continuous looping
    public func startAlarmSound(sound: AlarmSound, volume: Double = 1.0) {
        configureAudioSession()
        stopAlarmSound()

        isRinging = true

        // Attempt to load bundle sound file
        if let soundURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") ??
                            Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely until mission complete
                audioPlayer?.volume = Float(volume)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                print("🔊 Playing bundled sound '\(sound.displayName)' at volume \(volume)")
                return
            } catch {
                print("⚠️ Could not initialize AVAudioPlayer: \(error.localizedDescription)")
            }
        }

        // Fallback: Use procedural tone generator via AVAudioEngine if audio files are missing
        startProceduralAlarmTone(volume: volume)
    }

    /// Preview sound for picker UI
    public func previewSound(sound: AlarmSound, volume: Double = 1.0) {
        configureAudioSession()
        stopAlarmSound()

        if let soundURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") ??
                            Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.numberOfLoops = 0 // Play once
                audioPlayer?.volume = Float(volume)
                audioPlayer?.play()
                return
            } catch {}
        }

        // Fallback preview
        AudioServicesPlaySystemSound(1005) // System Alarm Beep
    }

    /// Stop playing alarm sound
    public func stopAlarmSound() {
        isRinging = false

        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        audioPlayer = nil

        if isPlayingToneEngine {
            audioEngine?.stop()
            audioEngine = nil
            isPlayingToneEngine = false
        }

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {}
    }

    // MARK: - Procedural Synth Tone Engine (Fallback High Volume Siren)
    private func startProceduralAlarmTone(volume: Double) {
        isPlayingToneEngine = true
        let engine = AVAudioEngine()
        let mainMixer = engine.mainMixerNode
        let hardwareSampleRate = mainMixer.outputFormat(forBus: 0).sampleRate
        let sampleRate: Double = (hardwareSampleRate > 0 && !hardwareSampleRate.isNaN) ? hardwareSampleRate : 44100.0
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            AudioServicesPlayAlertSound(SystemSoundID(1005))
            return
        }

        var sampleTime: Double = 0.0
        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let frequency: Double = 880.0 // A5 pitch siren
            let phaseIncrement = (2.0 * Double.pi * frequency) / sampleRate

            for frame in 0..<Int(frameCount) {
                let sirenModulation = sin(2.0 * Double.pi * 4.0 * sampleTime / sampleRate) // 4Hz pulse
                let val = sin(sampleTime * phaseIncrement) * (sirenModulation > 0 ? 1.0 : 0.2) * volume
                let sampleVal = Float(val.isNaN ? 0.0 : val)
                sampleTime += 1.0

                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    if frame < buf.count {
                        buf[frame] = sampleVal
                    }
                }
            }
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mainMixer, format: format)

        do {
            try engine.start()
            self.audioEngine = engine
            print("🚨 Started procedural emergency siren fallback.")
        } catch {
            print("❌ Failed to start procedural audio engine: \(error)")
            // System sound emergency fallback
            AudioServicesPlayAlertSound(SystemSoundID(1005))
        }

        // Always play system sound alert once as secondary audio output
        AudioServicesPlayAlertSound(SystemSoundID(1005))
    }
}
