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

        // 1. Check for custom user ringtone imported from iOS Files app
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

        // 2. Attempt to load bundled audio file
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

        // 3. Fallback: Play generated high-volume alarm siren WAV file via AVAudioPlayer
        if let sirenURL = ensureDefaultSirenFileExists() {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: sirenURL)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely
                audioPlayer?.volume = Float(volume)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                print("🚨 Playing default emergency siren WAV at volume \(volume)")
            } catch {
                print("❌ Failed to play siren WAV: \(error.localizedDescription)")
            }
        }

        // Secondary physical system alert sound fallback
        AudioServicesPlayAlertSound(SystemSoundID(1005))
    }

    /// Preview sound for picker UI
    public func previewSound(sound: AlarmSound, volume: Double = 1.0) {
        startAlarmSound(sound: sound, volume: volume)
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

    // MARK: - Procedural Siren WAV Generator
    private func ensureDefaultSirenFileExists() -> URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = docs.appendingPathComponent("alarm_siren.wav")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }

        let sampleRate: Float = 44100.0
        let duration: Float = 1.0
        let numSamples = Int(sampleRate * duration)
        var samples = [Int16]()
        samples.reserveCapacity(numSamples)

        for i in 0..<numSamples {
            let time = Float(i) / sampleRate
            let sirenMod = sin(2.0 * .pi * 4.0 * time)
            let freq: Float = sirenMod > 0 ? 950.0 : 750.0
            let value = sin(2.0 * .pi * freq * time)
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
            print("✅ Generated default high-volume alarm_siren.wav successfully!")
            return fileURL
        } catch {
            print("❌ Failed to write siren WAV file: \(error)")
            return nil
        }
    }
}
