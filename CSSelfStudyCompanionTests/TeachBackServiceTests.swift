import XCTest
@testable import CSSelfStudyCompanion

final class TeachBackServiceTests: XCTestCase {
    private let concept = Concept(
        id: "pointer",
        name: "指针",
        aliases: ["地址", "内存地址"],
        category: "C",
        summary: "保存地址的变量",
        details: "指针保存地址，解引用访问目标。"
    )

    func testDetailedExplanationScoresHigherThanShortAnswer() {
        let detailed = TeachBackService.evaluate(
            answer: "指针本质上是一个保存内存地址的变量。因为地址指向对象，所以可以通过解引用访问目标。例如 int 变量和对应指针可以写成代码演示。首先说明地址，然后说明类型，边界是空指针不能直接解引用。",
            stepTitle: "指针与地址",
            reference: "指针保存地址，并通过解引用访问目标。",
            concepts: [concept]
        )
        let short = TeachBackService.evaluate(
            answer: "指针就是地址。",
            stepTitle: "指针与地址",
            reference: "指针保存地址，并通过解引用访问目标。",
            concepts: [concept]
        )

        XCTAssertGreaterThan(detailed.score, short.score)
        XCTAssertTrue(detailed.passed)
        XCTAssertFalse(short.passed)
    }

    func testEvaluationProducesActionableGaps() {
        let evaluation = TeachBackService.evaluate(
            answer: "指针是一个变量。",
            stepTitle: "指针",
            reference: "指针保存地址，并通过解引用访问目标。",
            concepts: [concept]
        )

        XCTAssertFalse(evaluation.gaps.isEmpty)
        XCTAssertTrue(evaluation.noteBody.contains("维度反馈"))
    }
}
