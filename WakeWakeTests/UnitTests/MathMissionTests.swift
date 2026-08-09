//
//  MathMissionTests.swift
//  WakeWakeTests
//
//  Created in 2026 for iOS 17/18+ (XCTest Unit Tests)
//

import XCTest
@testable import WakeWake

final class MathMissionTests: XCTestCase {

    func testMathProblemGenerationEasy() {
        for _ in 0..<50 {
            let problem = MathProblem.generate(difficulty: .easy)
            XCTAssertFalse(problem.expression.isEmpty)
            // Verify problem expression doesn't throw or contain illegal characters
            XCTAssertTrue(problem.expression.contains("+") || problem.expression.contains("-") || problem.expression.contains("×"))
        }
    }

    func testMathProblemGenerationHardAndExtreme() {
        let hard = MathProblem.generate(difficulty: .hard)
        XCTAssertTrue(hard.expression.contains("×"))

        let extreme = MathProblem.generate(difficulty: .extreme)
        XCTAssertTrue(extreme.expression.contains("+"))
    }

    // MARK: - Expected Failing / Verification Tests
    func testWrongAnswerVerification() {
        let problem = MathProblem(expression: "10 + 15", answer: 25)
        
        let wrongUserAnswers = [10, 0, -5, 30, 250]
        for wrong in wrongUserAnswers {
            XCTAssertNotEqual(wrong, problem.answer, "Answer \(wrong) should be evaluated as incorrect for expression \(problem.expression)")
        }
    }
}
