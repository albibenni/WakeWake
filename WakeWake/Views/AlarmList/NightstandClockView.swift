//
//  NightstandClockView.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import SwiftUI

public struct NightstandClockView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentTime: Date = Date()
    @State private var brightness: Double = 0.3

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(.yellow)
                    Text("Nightstand Mode")
                        .font(.headline)
                        .foregroundColor(.gray)

                    Spacer()

                    Image(systemName: "xmark.circle.fill")
                        .opacity(0)
                }
                .padding()

                Spacer()

                // Giant Digital Clock
                VStack(spacing: 8) {
                    Text(formattedTime(currentTime))
                        .font(.system(size: 90, weight: .thin, design: .monospaced))
                        .foregroundColor(.cyan.opacity(brightness + 0.3))
                        .shadow(color: .cyan.opacity(brightness), radius: 20)

                    Text(formattedDate(currentTime))
                        .font(.title3)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Dimmer control slider
                HStack(spacing: 16) {
                    Image(systemName: "sun.min.fill")
                        .foregroundColor(.gray)

                    Slider(value: $brightness, in: 0.05...1.0)
                        .tint(.cyan)

                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            }
        }
        .onReceive(timer) { input in
            currentTime = input
        }
        .persistentSystemOverlays(.hidden)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}
