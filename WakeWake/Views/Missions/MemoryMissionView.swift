//
//  MemoryMissionView.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import SwiftUI

public struct MemoryMissionView: View {
    let targetRounds: Int
    let onCompleted: () -> Void

    @State private var currentRound: Int = 1
    @State private var sequence: [Int] = []
    @State private var userSequence: [Int] = []
    @State private var activeGlowingTile: Int? = nil
    @State private var isPlayingPattern: Bool = false
    @State private var statusMessage: String = "Watch the pattern..."

    private let gridItems = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    private let tileColors: [Color] = [.cyan, .purple, .orange, .green, .pink, .yellow, .blue, .mint, .indigo]

    public init(targetRounds: Int, onCompleted: @escaping () -> Void) {
        self.targetRounds = targetRounds
        self.onCompleted = onCompleted
    }

    public var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Memory Pattern Mission")
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
                Text("Round \(currentRound) / \(targetRounds)")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.purple)
            }

            Text(statusMessage)
                .font(.title3)
                .bold()
                .foregroundColor(isPlayingPattern ? .yellow : .cyan)
                .padding(.vertical, 8)

            Spacer()

            // 3x3 Grid
            LazyVGrid(columns: gridItems, spacing: 16) {
                ForEach(0..<9, id: \.self) { index in
                    Button(action: {
                        handleTileTap(index)
                    }) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                activeGlowingTile == index ?
                                tileColors[index] : Color.white.opacity(0.1)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(tileColors[index].opacity(0.4), lineWidth: 2)
                            )
                            .shadow(
                                color: activeGlowingTile == index ? tileColors[index].opacity(0.8) : Color.clear,
                                radius: 16
                            )
                            .aspectRatio(1.0, contentMode: .fit)
                    }
                    .disabled(isPlayingPattern)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            startRound()
        }
    }

    private func startRound() {
        userSequence = []
        statusMessage = "Memorize pattern..."
        isPlayingPattern = true

        // Build sequence of length = currentRound + 2
        let length = currentRound + 2
        var newSeq: [Int] = []
        for _ in 0..<length {
            newSeq.append(Int.random(in: 0..<9))
        }
        self.sequence = newSeq

        // Play sequence animations step by step
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            playSequenceStep(at: 0)
        }
    }

    private func playSequenceStep(at index: Int) {
        guard index < sequence.count else {
            activeGlowingTile = nil
            isPlayingPattern = false
            statusMessage = "Repeat the pattern!"
            return
        }

        let tile = sequence[index]
        activeGlowingTile = tile
        HapticService.shared.lightImpact()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            activeGlowingTile = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                playSequenceStep(at: index + 1)
            }
        }
    }

    private func handleTileTap(_ tileIndex: Int) {
        guard !isPlayingPattern else { return }

        activeGlowingTile = tileIndex
        HapticService.shared.lightImpact()
        userSequence.append(tileIndex)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            activeGlowingTile = nil
        }

        let currentStep = userSequence.count - 1
        if userSequence[currentStep] != sequence[currentStep] {
            // Error! Restart round
            HapticService.shared.errorNotification()
            statusMessage = "❌ Wrong tile! Try again."
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                startRound()
            }
            return
        }

        if userSequence.count == sequence.count {
            // Round success!
            HapticService.shared.successNotification()
            if currentRound >= targetRounds {
                onCompleted()
            } else {
                currentRound += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    startRound()
                }
            }
        }
    }
}
