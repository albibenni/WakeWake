//
//  MathMissionView.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import SwiftUI

public struct MathMissionView: View {
    let difficulty: MissionDifficulty
    let targetCount: Int
    let onCompleted: () -> Void

    @State private var currentProblemIndex: Int = 1
    @State private var currentProblem: MathProblem
    @State private var userInput: String = ""
    @State private var shakeOffset: CGFloat = 0

    public init(difficulty: MissionDifficulty, targetCount: Int, onCompleted: @escaping () -> Void) {
        self.difficulty = difficulty
        self.targetCount = targetCount
        self.onCompleted = onCompleted
        _currentProblem = State(initialValue: MathProblem.generate(difficulty: difficulty))
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Header Progress
            HStack {
                Text("Math Mission")
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(currentProblemIndex) / \(targetCount)")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal)

            // Problem Display Card
            GlassCard(cornerRadius: 24, borderColor: .cyan.opacity(0.3)) {
                VStack(spacing: 16) {
                    Text("Solve to turn off alarm")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(currentProblem.expression)
                        .font(.system(size: 44, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.6)

                    // Answer Input box
                    HStack {
                        Text(userInput.isEmpty ? "?" : userInput)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(userInput.isEmpty ? .gray.opacity(0.5) : .cyan)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(userInput.isEmpty ? Color.white.opacity(0.1) : Color.cyan, lineWidth: 2)
                    )
                }
                .padding(.vertical, 12)
            }
            .offset(x: shakeOffset)

            Spacer()

            // Custom Keypad
            VStack(spacing: 12) {
                ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { digit in
                            keypadButton("\(digit)") {
                                appendDigit("\(digit)")
                            }
                        }
                    }
                }
                HStack(spacing: 12) {
                    keypadButton("C", color: .red.opacity(0.8)) {
                        userInput = ""
                    }
                    keypadButton("0") {
                        appendDigit("0")
                    }
                    keypadButton("↵", color: .green) {
                        checkAnswer()
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }

    private func keypadButton(_ text: String, color: Color = Color.white.opacity(0.15), action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticService.shared.lightImpact()
            action()
        }) {
            Text(text)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 65)
                .background(color)
                .cornerRadius(18)
        }
    }

    private func appendDigit(_ digit: String) {
        if userInput.count < 6 {
            userInput += digit
        }
    }

    private func checkAnswer() {
        guard let value = Int(userInput) else { return }

        if value == currentProblem.answer {
            HapticService.shared.successNotification()
            if currentProblemIndex >= targetCount {
                onCompleted()
            } else {
                currentProblemIndex += 1
                userInput = ""
                currentProblem = MathProblem.generate(difficulty: difficulty)
            }
        } else {
            HapticService.shared.errorNotification()
            withAnimation(.default) {
                shakeOffset = 15
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.default) {
                    shakeOffset = -15
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.default) {
                    shakeOffset = 0
                }
            }
            userInput = ""
        }
    }
}
