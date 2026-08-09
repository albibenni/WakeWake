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

        // 1. Check for custom user ringtone imported from iOS Files app or Music Library
        if sound == .customRingtone, let customURL = getCustomRingtoneURL() {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: customURL)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely
                audioPlayer?.volume = Float(volume)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                print("🔊 Playing custom imported ringtone: \(customURL.lastPathComponent)")
                return
            } catch {
                print("⚠️ Failed to play custom ringtone: \(error.localizedDescription)")
            }
        }

        // 2. Attempt to load bundled audio file if present
        if let soundURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") ??
                            Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.volume = Float(volume)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                print("🔊 Playing bundled sound '\(sound.displayName)' at volume \(volume)")
                return
            } catch {
                print("⚠️ Could not initialize AVAudioPlayer: \(error.localizedDescription)")
            }
        }

        // 3. Fallback: Generate and play distinct, sound-specific WAV audio for each sound option
        if let soundWavURL = ensureSoundFileExists(for: sound) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundWavURL)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely
                audioPlayer?.volume = Float(volume)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                print("🚨 Playing distinct sound WAV '\(sound.rawValue)' at volume \(volume)")
                return
            } catch {
                print("❌ Failed to play sound WAV: \(error.localizedDescription)")
            }
        }

        // Secondary fallback alert sound
        AudioServicesPlayAlertSound(SystemSoundID(1005))
    }

    /// Preview sound for picker UI (plays preview cycle once)
    public func previewSound(sound: AlarmSound, volume: Double = 1.0) {
        configureAudioSession()
        stopAlarmSound()

        // 1. Custom ringtone preview
        if sound == .customRingtone, let customURL = getCustomRingtoneURL() {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: customURL)
                audioPlayer?.numberOfLoops = 0
                audioPlayer?.volume = Float(volume)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                print("🔊 Previewing custom ringtone: \(customURL.lastPathComponent)")
                return
            } catch {
                print("⚠️ Failed previewing custom ringtone: \(error)")
            }
        }

        // 2. Bundled audio file preview
        if let soundURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") ??
                            Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.numberOfLoops = 0
                audioPlayer?.volume = Float(volume)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                print("🔊 Previewing bundled sound '\(sound.displayName)'")
                return
            } catch {}
        }

        // 3. Distinct sound option WAV preview
        if let soundWavURL = ensureSoundFileExists(for: sound) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundWavURL)
                audioPlayer?.numberOfLoops = 0
                audioPlayer?.volume = Float(volume)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                print("🚨 Previewing sound WAV '\(sound.rawValue)'")
                return
            } catch {}
        }

        AudioServicesPlayAlertSound(SystemSoundID(1005))
    }

    /// Stop playing alarm sound
    public func stopAlarmSound() {
        isRinging = false

        if let player = audioPlayer {
            player.stop()
        }
        audioPlayer = nil

        if isPlayingToneEngine {
            audioEngine?.stop()
            audioEngine = nil
            isPlayingToneEngine = false
        }
    }

    // MARK: - Custom Ringtone Storage Management
    public func saveCustomRingtone(from sourceURL: URL) -> String? {
        guard sourceURL.startAccessingSecurityScopedResource() else { return nil }
        defer { sourceURL.stopAccessingSecurityScopedResource() }

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let ext = sourceURL.pathExtension.isEmpty ? "mp3" : sourceURL.pathExtension
        let destURL = docs.appendingPathComponent("custom_ringtone.\(ext)")

        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            let displayName = sourceURL.deletingPathExtension().lastPathComponent
            UserDefaults.standard.set(destURL.lastPathComponent, forKey: "CustomRingtoneFilename")
            UserDefaults.standard.set(displayName, forKey: "CustomRingtoneDisplayName")
            print("✅ Successfully imported custom ringtone: \(displayName)")
            return displayName
        } catch {
            print("❌ Failed to copy custom ringtone: \(error)")
            return nil
        }
    }

    public func getCustomRingtoneURL() -> URL? {
        guard let filename = UserDefaults.standard.string(forKey: "CustomRingtoneFilename") else { return nil }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    public func getCustomRingtoneName() -> String {
        return UserDefaults.standard.string(forKey: "CustomRingtoneDisplayName") ?? "Custom Sound"
    }

    // MARK: - Distinct Procedural Sound Generator (Generates distinct WAV for each sound option)
    private func ensureSoundFileExists(for sound: AlarmSound) -> URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = docs.appendingPathComponent("sound_\(sound.rawValue).wav")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }

        let sampleRate: Float = 44100.0
        let duration: Float = 1.2
        let numSamples = Int(sampleRate * duration)
        var samples = [Int16]()
        samples.reserveCapacity(numSamples)

        for i in 0..<numSamples {
            let time = Float(i) / sampleRate
            var freq: Float = 440.0
            var amplitude: Float = 1.0

            switch sound {
            case .emergencyBell:
                // Piercing dual siren 950Hz / 700Hz
                let mod = sin(2.0 * .pi * 4.0 * time)
                freq = mod > 0 ? 950.0 : 700.0
            case .fireSignal:
                // Rapid high-pitch staccato pulse 1200Hz
                let pulse = sin(2.0 * .pi * 12.0 * time)
                freq = 1200.0
                amplitude = pulse > 0 ? 1.0 : 0.05
            case .highVoltage:
                // Heavy buzzing electric sawtooth 150Hz
                freq = 150.0
                amplitude = (fmod(time * freq, 1.0) < 0.5) ? 1.0 : -1.0
            case .neonPulse:
                // Arpeggiated synth 440Hz -> 880Hz -> 1320Hz
                let step = Int(time * 8.0) % 3
                freq = step == 0 ? 440.0 : (step == 1 ? 880.0 : 1320.0)
            case .radarAlert:
                // Submarine sonar ping with silence gap
                let pingCycle = fmod(time, 0.4)
                freq = 600.0
                amplitude = pingCycle < 0.1 ? sin(2.0 * .pi * freq * time) * exp(-pingCycle * 20.0) : 0.0
            case .militaryBugle:
                // Reveille bugle pitch sequence 440Hz -> 554Hz -> 659Hz
                let bugleStep = Int(time * 5.0) % 3
                freq = bugleStep == 0 ? 440.0 : (bugleStep == 1 ? 554.37 : 659.25)
            case .customRingtone:
                freq = 880.0
            }

            let value = amplitude * sin(2.0 * .pi * freq * time)
            let pcmValue = Int16(max(-32767, min(32767, value * 32767.0)))
            samples.append(pcmValue)
        }

        var header = Data()
        let subchunk2Size = UInt32(numSamples * 2)
        let chunkSize = UInt32(36 + subchunk2Size)

        header.append(contentsOf: "RIFF".utf8)
        header.append(contentsOf: withUnsafeBytes(of: chunkSize.littleEndian) { Array($0) })
        header.append(contentsOf: "WAVEfmt ".utf8)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt32(44100).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt32(88200).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) })
        header.append(contentsOf: "data".utf8)
        header.append(contentsOf: withUnsafeBytes(of: subchunk2Size.littleEndian) { Array($0) })

        var wavData = header
        samples.withUnsafeBufferPointer { buffer in
            let rawPtr = UnsafeRawPointer(buffer.baseAddress!)
            wavData.append(rawPtr.assumingMemoryBound(to: UInt8.self), count: numSamples * 2)
        }

        do {
            try wavData.write(to: fileURL)
            print("✅ Generated distinct WAV sound for '\(sound.rawValue)' successfully!")
            return fileURL
        } catch {
            print("❌ Failed to write sound WAV file: \(error)")
            return nil
        }
    }
}
