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
    private var systemSoundTimer: Timer?

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

        // 1. Custom user ringtone imported from Files app
        if sound == .customRingtone, let customURL = getCustomRingtoneURL() {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: customURL)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely
                audioPlayer?.volume = Float(volume)
                audioPlayer?.prepareToPlay()
                if audioPlayer?.play() == true {
                    print("🔊 Playing custom imported ringtone: \(customURL.lastPathComponent)")
                    return
                }
            } catch {
                print("⚠️ Failed to play custom ringtone: \(error.localizedDescription)")
            }
        }

        // 2. Bundled audio file in App Bundle
        if let bundleURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") ??
                            Bundle.main.url(forResource: sound.rawValue, withExtension: "m4a") ??
                            Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: bundleURL)
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.volume = Float(volume)
                audioPlayer?.prepareToPlay()
                if audioPlayer?.play() == true {
                    print("🔊 Playing bundled sound '\(sound.displayName)' at volume \(volume)")
                    return
                }
            } catch {}
        }

        // 3. High-fidelity acoustic tone generator matching iOS sound signature
        if let soundWavURL = generateExactSoundWav(for: sound) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundWavURL)
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.volume = Float(volume)
                audioPlayer?.prepareToPlay()
                if audioPlayer?.play() == true {
                    print("🚨 Playing acoustic tone WAV for '\(sound.rawValue)' at volume \(volume)")
                    return
                }
            } catch {
                print("❌ Failed to play acoustic sound WAV: \(error.localizedDescription)")
            }
        }

        // 4. Secondary physical system alert sound fallback
        let soundID = SystemSoundID(sound.systemSoundID)
        AudioServicesPlayAlertSound(soundID)

        systemSoundTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            AudioServicesPlayAlertSound(soundID)
        }
    }

    /// Preview sound for picker UI (plays single preview cycle)
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
            } catch {}
        }

        // 2. Bundled audio preview
        if let bundleURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") ??
                            Bundle.main.url(forResource: sound.rawValue, withExtension: "m4a") ??
                            Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: bundleURL)
                audioPlayer?.numberOfLoops = 0
                audioPlayer?.volume = Float(volume)
                audioPlayer?.prepareToPlay()
                if audioPlayer?.play() == true {
                    print("🔊 Previewing bundled sound '\(sound.displayName)'")
                    return
                }
            } catch {}
        }

        // 3. High-fidelity acoustic WAV preview
        if let soundWavURL = generateExactSoundWav(for: sound) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundWavURL)
                audioPlayer?.numberOfLoops = 0
                audioPlayer?.volume = Float(volume)
                audioPlayer?.prepareToPlay()
                if audioPlayer?.play() == true {
                    print("🚨 Previewing acoustic tone WAV for '\(sound.rawValue)'")
                    return
                }
            } catch {}
        }

        // 4. Native iOS system alert sound once
        let soundID = SystemSoundID(sound.systemSoundID)
        AudioServicesPlayAlertSound(soundID)
    }

    /// High-Fidelity Acoustic Tone Synthesizer matching iOS sound profiles
    private func generateExactSoundWav(for sound: AlarmSound) -> URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = docs.appendingPathComponent("sound_acoustic_\(sound.rawValue).wav")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let size = attrs[.size] as? UInt64, size > 44 {
                return fileURL
            } else {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }

        let sampleRate: Float = 44100.0
        let duration: Float = 1.4
        let numSamples = Int(sampleRate * duration)
        var samples = [Int16]()
        samples.reserveCapacity(numSamples)

        for i in 0..<numSamples {
            let time = Float(i) / sampleRate
            var freq: Float = 440.0
            var amplitude: Float = 1.0

            switch sound {
            case .radar:
                // Radar: Classic iOS dual siren pulse (850Hz & 1150Hz alternating ping)
                let cycle = fmod(time, 0.4)
                let isHigh = fmod(time, 0.8) < 0.4
                freq = isHigh ? 1150.0 : 850.0
                amplitude = cycle < 0.25 ? sin(2.0 * .pi * freq * time) * exp(-cycle * 4.0) : 0.0
            case .reflection:
                // Reflection: Melodic E major marimba arpeggio (E4 -> G#4 -> B4 -> E5)
                let noteIndex = Int(time * 6.0) % 4
                let notes: [Float] = [329.63, 415.30, 493.88, 659.25]
                freq = notes[noteIndex]
                let noteTime = fmod(time, 0.166)
                amplitude = exp(-noteTime * 12.0)
            case .chime:
                // Chime: Soft acoustic bell chime resonance (1320Hz with exponential decay)
                let cycle = fmod(time, 0.7)
                freq = 1320.0
                amplitude = cycle < 0.5 ? exp(-cycle * 6.0) : 0.0
            case .beacon:
                // Beacon: 3-tone rhythmic sonar beacon (440Hz -> 660Hz -> 880Hz)
                let step = Int(time * 5.0) % 3
                freq = step == 0 ? 440.0 : (step == 1 ? 660.0 : 880.0)
                let stepTime = fmod(time, 0.2)
                amplitude = exp(-stepTime * 8.0)
            case .apex:
                // Apex: Crisp high-altitude dual harmonic bell (1500Hz + 2000Hz)
                let cycle = fmod(time, 0.5)
                freq = 1500.0
                amplitude = cycle < 0.3 ? (sin(2.0 * .pi * 1500.0 * time) + 0.5 * sin(2.0 * .pi * 2000.0 * time)) * exp(-cycle * 7.0) : 0.0
            case .circuit:
                // Circuit: Fast 16th-note electronic synth pulse
                let step = Int(time * 12.0) % 4
                let freqs: [Float] = [523.25, 659.25, 783.99, 1046.50]
                freq = freqs[step]
                let stepTime = fmod(time, 0.083)
                amplitude = stepTime < 0.06 ? 0.9 : 0.1
            case .signal:
                // Signal: High-frequency rapid warning staccato pulse (1400Hz 10Hz)
                let pulse = sin(2.0 * .pi * 10.0 * time)
                freq = 1400.0
                amplitude = pulse > 0 ? 1.0 : 0.05
            case .slowRise:
                // Slow Rise: Warm building sine wave arpeggio
                let progress = time / duration
                let step = Int(time * 4.0) % 4
                let freqs: [Float] = [261.63, 329.63, 392.00, 523.25]
                freq = freqs[step]
                amplitude = progress * 0.9
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
        samples.withUnsafeBytes { rawBufferPointer in
            wavData.append(contentsOf: rawBufferPointer)
        }

        do {
            try wavData.write(to: fileURL)
            print("✅ Synthesized acoustic WAV for '\(sound.rawValue)' successfully (\(wavData.count) bytes)")
            return fileURL
        } catch {
            print("❌ Failed to write acoustic WAV file: \(error)")
            return nil
        }
    }

    /// Stop playing alarm sound
    public func stopAlarmSound() {
        isRinging = false

        systemSoundTimer?.invalidate()
        systemSoundTimer = nil

        if let player = audioPlayer {
            player.currentTime = 0
            player.pause()
            player.stop()
        }
        audioPlayer = nil

        // Stop all active system audio toolbox alerts
        for soundID: UInt32 in [1000, 1005, 1007, 1008, 1016, 1021, 1022, 1023, 1025, 1026, 1027, 1033] {
            AudioServicesDisposeSystemSoundID(SystemSoundID(soundID))
        }

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
}
