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

        // 1. Check for custom user ringtone imported from iOS Files app
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

        // 2. Play native iOS system alert sound loop!
        let soundID = SystemSoundID(sound.systemSoundID)
        AudioServicesPlayAlertSound(soundID)

        systemSoundTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { _ in
            AudioServicesPlayAlertSound(soundID)
        }
        print("🚨 Playing native iOS System Sound \(sound.systemSoundID) for '\(sound.displayName)'")
    }

    /// Preview sound for picker UI (plays single alert cycle)
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

        // 2. Play native iOS system alert sound once for preview
        let soundID = SystemSoundID(sound.systemSoundID)
        AudioServicesPlayAlertSound(soundID)
        print("🚨 Previewing native iOS System Sound \(sound.systemSoundID)")
    }

    /// Stop playing alarm sound
    public func stopAlarmSound() {
        isRinging = false

        systemSoundTimer?.invalidate()
        systemSoundTimer = nil

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
}
