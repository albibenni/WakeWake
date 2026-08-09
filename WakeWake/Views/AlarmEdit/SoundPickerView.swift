//
//  SoundPickerView.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import SwiftUI

public struct SoundPickerView: View {
    @Binding var selectedSound: AlarmSound
    @Binding var volume: Double

    @Environment(\.dismiss) private var dismiss
    @State private var showFileImporter: Bool = false
    @State private var playingPreviewSound: AlarmSound? = nil

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Volume Control Card
                    GlassCard(cornerRadius: 20, borderColor: .cyan.opacity(0.3)) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundColor(.cyan)
                                Text("Loudness Level: \(Int(volume * 100))%")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }

                            Slider(value: $volume, in: 0.1...1.0, step: 0.05)
                                .tint(.cyan)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // Import Custom Ringtone Button
                    GlassCard(cornerRadius: 20, borderColor: .yellow.opacity(0.4)) {
                        Button(action: {
                            showFileImporter = true
                        }) {
                            HStack {
                                Image(systemName: "folder.badge.plus")
                                    .font(.title2)
                                    .foregroundColor(.yellow)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Import Custom Ringtone")
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(.white)

                                    Text(AudioService.shared.getCustomRingtoneURL() != nil ? "Currently: \(AudioService.shared.getCustomRingtoneName())" : "Pick .mp3, .wav, or .m4a from iPhone Files app")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Image(systemName: "square.and.arrow.down")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Sound List
                    List {
                        ForEach(AlarmSound.allCases) { sound in
                            let isCurrentlyPlaying = (playingPreviewSound == sound)

                            Button(action: {
                                selectedSound = sound
                                HapticService.shared.lightImpact()

                                if isCurrentlyPlaying {
                                    AudioService.shared.stopAlarmSound()
                                    playingPreviewSound = nil
                                } else {
                                    playingPreviewSound = sound
                                    AudioService.shared.previewSound(sound: sound, volume: volume)
                                }
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: selectedSound == sound ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundColor(selectedSound == sound ? .cyan : .gray)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(sound.displayName)
                                            .font(.body)
                                            .bold()
                                            .foregroundColor(.white)

                                        Text(sound.description)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    Image(systemName: isCurrentlyPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(isCurrentlyPlaying ? .yellow : .cyan)
                                        .padding(8)
                                        .background(isCurrentlyPlaying ? Color.yellow.opacity(0.25) : Color.cyan.opacity(0.15))
                                        .clipShape(Circle())
                                }
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.white.opacity(0.06))
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Alarm Sound")
            .navigationBarTitleDisplayMode(.inline)
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let selectedURL = urls.first {
                        if AudioService.shared.saveCustomRingtone(from: selectedURL) != nil {
                            selectedSound = .customRingtone
                            playingPreviewSound = .customRingtone
                            AudioService.shared.previewSound(sound: .customRingtone, volume: volume)
                        }
                    }
                case .failure(let error):
                    print("File import failed: \(error)")
                }
            }
            .onDisappear {
                AudioService.shared.stopAlarmSound()
                playingPreviewSound = nil
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        AudioService.shared.stopAlarmSound()
                        dismiss()
                    }
                    .bold()
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}
