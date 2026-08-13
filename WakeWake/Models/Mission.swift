//
//  Mission.swift
//  WakeWake
//
//  Created in 2026 for iOS 17/18+
//

import Foundation

public enum MissionType: String, Codable, CaseIterable, Identifiable {
    case math = "math"
    case shake = "shake"
    case stepsSquats = "stepsSquats"
    case memory = "memory"
    case typing = "typing"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .math: return "Math Problem"
        case .shake: return "Shake Phone"
        case .stepsSquats: return "Steps & Squats"
        case .memory: return "Memory Puzzle"
        case .typing: return "Motivational Typing"
        }
    }

    public var iconName: String {
        switch self {
        case .math: return "function"
        case .shake: return "iphone.radiowaves.left.and.right"
        case .stepsSquats: return "figure.walk"
        case .memory: return "square.grid.3x3.fill"
        case .typing: return "textformat"
        }
    }

    public var subtitle: String {
        switch self {
        case .math: return "Solve equations to prove you're awake"
        case .shake: return "Shake your device continuously"
        case .stepsSquats: return "Get out of bed and walk/squat"
        case .memory: return "Memorize and match glowing tile sequences"
        case .typing: return "Type inspirational morning declarations"
        }
    }

    public var defaultTargetCount: Int {
        switch self {
        case .math: return 3
        case .shake: return 30
        case .stepsSquats: return 15
        case .memory: return 4
        case .typing: return 1
        }
    }
}

public enum MissionDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case extreme = "extreme"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .extreme: return "Extreme ⚡️"
        }
    }
}

// MARK: - Math Mission Generator Helper
public struct MathProblem: Identifiable, Hashable {
    public let id = UUID()
    public let expression: String
    public let answer: Int

    public static func generate(difficulty: MissionDifficulty) -> MathProblem {
        let op = ["+", "-", "×"].randomElement()!
        var a: Int = 0
        var b: Int = 0
        var c: Int = 0

        switch difficulty {
        case .easy:
            a = Int.random(in: 5...25)
            b = Int.random(in: 5...25)
            if op == "+" {
                return MathProblem(expression: "\(a) + \(b)", answer: a + b)
            } else if op == "-" {
                a = max(a, b) + Int.random(in: 1...10)
                return MathProblem(expression: "\(a) - \(b)", answer: a - b)
            } else {
                a = Int.random(in: 2...9)
                b = Int.random(in: 2...9)
                return MathProblem(expression: "\(a) × \(b)", answer: a * b)
            }
        case .medium:
            a = Int.random(in: 20...70)
            b = Int.random(in: 15...50)
            c = Int.random(in: 5...20)
            if Bool.random() {
                return MathProblem(expression: "\(a) + \(b) - \(c)", answer: a + b - c)
            } else {
                a = Int.random(in: 6...14)
                b = Int.random(in: 6...14)
                return MathProblem(expression: "\(a) × \(b) + \(c)", answer: (a * b) + c)
            }
        case .hard:
            a = Int.random(in: 35...99)
            b = Int.random(in: 25...85)
            c = Int.random(in: 12...35)
            return MathProblem(expression: "(\(a) + \(b)) × \(c)", answer: (a + b) * c)
        case .extreme:
            a = Int.random(in: 110...450)
            b = Int.random(in: 80...320)
            c = Int.random(in: 15...45)
            return MathProblem(expression: "\(a) + \(b) × \(c)", answer: a + (b * c))
        }
    }
}
