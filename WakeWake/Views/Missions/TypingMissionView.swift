//
//  TypingMissionView.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import SwiftUI

public struct TypingMissionView: View {
    let onCompleted: () -> Void

    private let quotes: [String] = [
        "I am fully awake and ready to conquer the day!",
        "No snooze button will hold me back today.",
        "Early morning energy brings focus and determination.",
        "Action destroys procrastination right now."
    ]

    @State private var targetQuote: String = ""
    @State private var userTypedText: String = ""
    @FocusState private var isFieldFocused: Bool

    public init(onCompleted: @escaping () -> Void) {
        self.onCompleted = onCompleted
    }

    public var body: some View {
        VStack(spacing: 24) {
            Text("Typing Declaration Mission")
                .font(.headline)
                .foregroundColor(.gray)

            Spacer()

            GlassCard(cornerRadius: 24, borderColor: .cyan.opacity(0.3)) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("TYPE ACCURATELY:")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.gray)

                    Text(targetQuote)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
            }

            // Interactive TextEditor / TextField
            ZStack(alignment: .topLeading) {
                if userTypedText.isEmpty {
                    Text("Type the sentence exactly above...")
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                }

                TextEditor(text: $userTypedText)
                    .focused($isFieldFocused)
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.cyan)
                    .font(.system(size: 20, weight: .bold))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                userTypedText == targetQuote ? Color.green : Color.cyan,
                                lineWidth: 2
                            )
                    )
                    .frame(height: 140)
                    .onChange(of: userTypedText) { _, newValue in
                        if newValue == targetQuote {
                            HapticService.shared.successNotification()
                            onCompleted()
                        }
                    }
            }

            NeonButton(
                title: "Complete Declaration",
                iconName: "checkmark.circle.fill",
                color: userTypedText == targetQuote ? .green : .cyan
            ) {
                if userTypedText.trimmingCharacters(in: .whitespacesAndNewlines) == targetQuote.trimmingCharacters(in: .whitespacesAndNewlines) {
                    onCompleted()
                } else {
                    HapticService.shared.errorNotification()
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            targetQuote = quotes.randomElement() ?? quotes[0]
            isFieldFocused = true
        }
    }
}
