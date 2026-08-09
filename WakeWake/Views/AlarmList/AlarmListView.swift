//
//  AlarmListView.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+ (SwiftData Dashboard)
//

import SwiftUI
import SwiftData

public struct AlarmListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Alarm.time, order: .forward) private var alarms: [Alarm]

    @StateObject private var notificationService = NotificationService.shared

    @State private var showingAddAlarm: Bool = false
    @State private var alarmToEdit: Alarm? = nil
    @State private var showingNightstandMode: Bool = false
    @State private var showingSettings: Bool = false
    @State private var activeRingingAlarm: Alarm? = nil

    @State private var countdownString: String = "No upcoming alarms"
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Next Alarm Countdown Header Card
                    GlassCard(cornerRadius: 24, borderColor: .cyan.opacity(0.3)) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 48, height: 48)

                                Image(systemName: "alarm.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("NEXT ALARM")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.gray)

                                Text(countdownString)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundColor(.cyan)
                            }

                            Spacer()

                            Button(action: {
                                showingNightstandMode = true
                            }) {
                                Image(systemName: "moon.stars.fill")
                                    .font(.title3)
                                    .foregroundColor(.yellow)
                                    .padding(10)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                    // Alarms List
                    if alarms.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "alarm.waves.left.and.right")
                                .font(.system(size: 64))
                                .foregroundColor(.gray.opacity(0.5))

                            Text("No Alarms Set")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)

                            Text("Tap the '+' button above to create your first action alarm with wake-up missions.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(alarms) { alarm in
                                    AlarmRowView(
                                        alarm: alarm,
                                        onToggle: { isEnabled in
                                            alarm.isEnabled = isEnabled
                                            AlarmScheduler.shared.saveAndSchedule(alarm: alarm, modelContext: modelContext)
                                            updateCountdown()
                                        },
                                        onTap: {
                                            alarmToEdit = alarm
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationTitle("WakeWake")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.gray)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddAlarm = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.cyan)
                    }
                }
            }
            .sheet(isPresented: $showingAddAlarm) {
                AlarmEditView()
            }
            .sheet(item: $alarmToEdit) { alarm in
                AlarmEditView(alarmToEdit: alarm)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView { demoAlarm in
                    self.activeRingingAlarm = demoAlarm
                }
            }
            .fullScreenCover(isPresented: $showingNightstandMode) {
                NightstandClockView()
            }
            .fullScreenCover(item: $activeRingingAlarm) { alarm in
                AlarmRingingView(alarm: alarm) {
                    activeRingingAlarm = nil
                    notificationService.currentRingingAlarmID = nil
                }
            }
            .onAppear {
                updateCountdown()
                Task {
                    await notificationService.checkSettings()
                }
                checkRingingTrigger()
            }
            .onReceive(timer) { _ in
                updateCountdown()
                checkScheduledAlarmsToRing()
            }
            .onChange(of: alarms) { _, newAlarms in
                if activeRingingAlarm == nil, let currentID = notificationService.currentRingingAlarmID {
                    if let alarm = newAlarms.first(where: { $0.id == currentID }) {
                        triggerRinging(for: alarm)
                    }
                }
            }
            .onReceive(notificationService.$currentRingingAlarmID) { alarmID in
                if let alarmID = alarmID {
                    if let alarm = alarms.first(where: { $0.id == alarmID }) {
                        triggerRinging(for: alarm)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .startAlarmMissionTriggered)) { note in
                if let alarmID = note.object as? UUID, let alarm = alarms.first(where: { $0.id == alarmID }) {
                    triggerRinging(for: alarm)
                }
            }
        }
    }

    @State private var lastTriggeredAlarmID: UUID? = nil
    @State private var lastTriggeredMinute: Int = -1

    private func triggerRinging(for alarm: Alarm) {
        let calendar = Calendar.current
        let currentMinute = calendar.component(.minute, from: Date())

        // Prevent re-triggering the same alarm within the same minute
        if lastTriggeredAlarmID == alarm.id && lastTriggeredMinute == currentMinute {
            return
        }

        guard activeRingingAlarm?.id != alarm.id else { return }

        lastTriggeredAlarmID = alarm.id
        lastTriggeredMinute = currentMinute

        DispatchQueue.main.async {
            self.showingSettings = false
            self.showingAddAlarm = false
            self.alarmToEdit = nil
            self.showingNightstandMode = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.activeRingingAlarm = alarm
                AudioService.shared.startAlarmSound(sound: alarm.sound, volume: alarm.volume)
                if alarm.isVibrationEnabled {
                    HapticService.shared.startContinuousVibration()
                }
            }
        }
    }

    private func checkScheduledAlarmsToRing() {
        guard activeRingingAlarm == nil else { return }
        let now = Date()
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute], from: now)
        let currentSecond = calendar.component(.second, from: now)

        guard currentSecond <= 10 else { return }

        for alarm in alarms where alarm.isEnabled {
            let alarmComponents = calendar.dateComponents([.hour, .minute], from: alarm.time)
            if alarmComponents.hour == currentComponents.hour &&
               alarmComponents.minute == currentComponents.minute {
                triggerRinging(for: alarm)
                break
            }
        }
    }

    private func updateCountdown() {
        let activeAlarms = alarms.filter { $0.isEnabled }
        let now = Date()

        let nextDates = activeAlarms.compactMap { alarm in
            alarm.nextTriggerDate(from: now)
        }.sorted()

        guard let nearestDate = nextDates.first else {
            if countdownString != "No upcoming alarms active" {
                countdownString = "No upcoming alarms active"
            }
            return
        }

        let diff = nearestDate.timeIntervalSince(now)
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60

        let newString: String
        if hours > 0 {
            newString = "Ringing in \(hours)h \(minutes)m"
        } else if minutes > 0 {
            newString = "Ringing in \(minutes) minutes"
        } else {
            newString = "Ringing in under a minute"
        }

        if countdownString != newString {
            countdownString = newString
        }
    }

    private func checkRingingTrigger() {
        if let currentID = notificationService.currentRingingAlarmID {
            if let alarm = alarms.first(where: { $0.id == currentID }) {
                triggerRinging(for: alarm)
            }
        }
    }
}
