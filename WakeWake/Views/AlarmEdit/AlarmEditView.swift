//
//  AlarmEditView.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import SwiftUI
import SwiftData

public struct AlarmEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let alarmToEdit: Alarm?

    @State private var time: Date = Date()
    @State private var label: String = "Wake Up!"
    @State private var repeatDays: Set<RepeatDay> = []
    @State private var sound: AlarmSound = .radar
    @State private var volume: Double = 1.0
    @State private var isVibrationEnabled: Bool = true
    @State private var isSnoozeEnabled: Bool = true
    @State private var snoozeDurationMinutes: Int = 5

    @State private var missionType: MissionType = .math
    @State private var missionDifficulty: MissionDifficulty = .medium
    @State private var missionTargetCount: Int = 3

    @State private var showMissionPicker: Bool = false
    @State private var showSoundPicker: Bool = false

    public init(alarmToEdit: Alarm? = nil) {
        self.alarmToEdit = alarmToEdit
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Date/Time Wheel Picker
                        GlassCard(cornerRadius: 24, borderColor: .cyan.opacity(0.3)) {
                            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        .padding(.horizontal)

                        // Alarm Label & Repeat Days
                        GlassCard(cornerRadius: 20, borderColor: .white.opacity(0.1)) {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Label")
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(.gray)

                                    TextField("Alarm Name", text: $label)
                                        .multilineTextAlignment(.trailing)
                                        .font(.body)
                                        .bold()
                                        .foregroundColor(.white)
                                }

                                Divider().background(Color.white.opacity(0.1))

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("REPEAT")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.gray)

                                    HStack(spacing: 8) {
                                        ForEach(RepeatDay.allCases) { day in
                                            Button(action: {
                                                if repeatDays.contains(day) {
                                                    repeatDays.remove(day)
                                                } else {
                                                    repeatDays.insert(day)
                                                }
                                                HapticService.shared.lightImpact()
                                            }) {
                                                Text(day.shortName)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(repeatDays.contains(day) ? .black : .white)
                                                    .frame(maxWidth: .infinity)
                                                    .frame(height: 38)
                                                    .background(
                                                        repeatDays.contains(day) ? Color.cyan : Color.white.opacity(0.1)
                                                    )
                                                    .cornerRadius(10)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Wake-Up Mission Selector Button
                        Button(action: {
                            showMissionPicker = true
                        }) {
                            GlassCard(cornerRadius: 20, borderColor: .cyan.opacity(0.4)) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color.cyan)
                                            .frame(width: 40, height: 40)
                                        Image(systemName: missionType.iconName)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.black)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Wake-Up Mission")
                                            .font(.caption)
                                            .foregroundColor(.gray)

                                        Text(missionType.title)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Sound Selector Button
                        Button(action: {
                            showSoundPicker = true
                        }) {
                            GlassCard(cornerRadius: 20, borderColor: .white.opacity(0.1)) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color.yellow)
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "speaker.wave.3.fill")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.black)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Sound & Volume (\(Int(volume * 100))%)")
                                            .font(.caption)
                                            .foregroundColor(.gray)

                                        Text(sound.displayName)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Snooze & Vibration Options
                        GlassCard(cornerRadius: 20, borderColor: .white.opacity(0.1)) {
                            VStack(spacing: 16) {
                                Toggle("Vibration Pattern", isOn: $isVibrationEnabled)
                                    .tint(.cyan)
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.white)

                                Divider().background(Color.white.opacity(0.1))

                                Toggle("Enable Snooze", isOn: $isSnoozeEnabled)
                                    .tint(.cyan)
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.white)

                                if isSnoozeEnabled {
                                    Stepper("Snooze Duration: \(snoozeDurationMinutes) min", value: $snoozeDurationMinutes, in: 1...30)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Delete button if editing
                        if let alarm = alarmToEdit {
                            Button(action: {
                                AlarmScheduler.shared.deleteAlarm(alarm, modelContext: modelContext)
                                dismiss()
                            }) {
                                Text("Delete Alarm")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.red)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red.opacity(0.15))
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(alarmToEdit == nil ? "New Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveAlarm()
                    }
                    .bold()
                    .foregroundColor(.cyan)
                }
            }
            .sheet(isPresented: $showMissionPicker) {
                MissionPickerView(
                    selectedMissionType: $missionType,
                    difficulty: $missionDifficulty,
                    targetCount: $missionTargetCount
                )
            }
            .sheet(isPresented: $showSoundPicker) {
                SoundPickerView(
                    selectedSound: $sound,
                    volume: $volume
                )
            }
            .onAppear {
                if let alarm = alarmToEdit {
                    time = alarm.time
                    label = alarm.label
                    repeatDays = alarm.repeatDays
                    sound = alarm.sound
                    volume = alarm.volume
                    isVibrationEnabled = alarm.isVibrationEnabled
                    isSnoozeEnabled = alarm.isSnoozeEnabled
                    snoozeDurationMinutes = alarm.snoozeDurationMinutes
                    missionType = alarm.missionType
                    missionDifficulty = alarm.missionDifficulty
                    missionTargetCount = alarm.missionTargetCount
                }
            }
        }
    }

    private func saveAlarm() {
        let alarm = alarmToEdit ?? Alarm()
        alarm.time = time
        alarm.label = label
        alarm.repeatDays = repeatDays
        alarm.sound = sound
        alarm.volume = volume
        alarm.isVibrationEnabled = isVibrationEnabled
        alarm.isSnoozeEnabled = isSnoozeEnabled
        alarm.snoozeDurationMinutes = snoozeDurationMinutes
        alarm.missionType = missionType
        alarm.missionDifficulty = missionDifficulty
        alarm.missionTargetCount = missionTargetCount
        alarm.isEnabled = true

        AlarmScheduler.shared.saveAndSchedule(alarm: alarm, modelContext: modelContext)
        dismiss()
    }
}
