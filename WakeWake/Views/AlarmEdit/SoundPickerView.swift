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

                    // Sound List
                    List {
                        ForEach(AlarmSound.allCases) { sound in
                            Button(action: {
                                selectedSound = sound
                                AudioService.shared.previewSound(sound: sound, volume: volume)
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

                                    Image(systemName: "play.fill")
                                        .font(.caption)
                                        .foregroundColor(.cyan)
                                }
                                .padding(.vertical, 6)
                            }
                            .listRowBackground(Color.white.opacity(0.06))
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Alarm Sound")
            .navigationBarTitleDisplayMode(.inline)
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
