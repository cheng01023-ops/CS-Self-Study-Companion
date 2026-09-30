import XCTest
@testable import CSSelfStudyCompanion

final class CodeExecutionServiceTests: XCTestCase {
    func testRequestSizeValidation() {
        XCTAssertNotNil(
            CodeExecutionService.validationError(
                code: String(repeating: "x", count: 200_001),
                input: "",
                arguments: []
            )
        )
        XCTAssertNotNil(
            CodeExecutionService.validationError(
                code: "int main(void) { return 0; }",
                input: String(repeating: "x", count: 64_001),
                arguments: []
            )
        )
        XCTAssertNotNil(
            CodeExecutionService.validationError(
                code: "int main(void) { return 0; }",
                input: "",
                arguments: Array(repeating: "arg", count: 17)
            )
        )
        XCTAssertNil(
            CodeExecutionService.validationError(
                code: "int main(void) { return 0; }",
                input: "ok",
                arguments: ["one"]
            )
        )
    }

    #if os(macOS)
    func testCProgramRunsAndPassesExpectedOutput() async {
        let result = await CodeExecutionService.run(
            code: """
            #include <stdio.h>
            int main(void) {
                printf("42\\n");
                return 0;
            }
            """,
            language: "c",
            input: "",
            expectedOutput: "42"
        )

        XCTAssertTrue(result.succeeded, result.message)
        XCTAssertTrue(result.passed, result.stderr)
        XCTAssertEqual(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines), "42")
    }

    func testTheoryPrimaryExamplesCompileAndRun() async {
        let ids: Set<String> = [
            "tutorial-math-discrete",
            "tutorial-math-proof",
            "tutorial-math-linear",
            "tutorial-math-probability",
            "tutorial-math-information",
            "tutorial-theory-automata",
            "tutorial-theory-computability",
            "tutorial-theory-algorithms",
            "tutorial-theory-semantics"
        ]
        let tutorials = LearningCatalog.stages
            .flatMap(\.topics)
            .flatMap(\.tutorials)
            .filter { ids.contains($0.id) }

        XCTAssertEqual(tutorials.count, ids.count)
        for tutorial in tutorials {
            let samples = [
                ("主示例", tutorial.code, tutorial.codeLanguage),
                ("补充示例", tutorial.secondCode, tutorial.secondCodeLanguage)
            ]
            for (label, code, language) in samples {
                let result = await CodeExecutionService.run(
                    code: code,
                    language: language,
                    input: "",
                    expectedOutput: ""
                )
                XCTAssertTrue(
                    result.succeeded,
                    "\(tutorial.id) \(label) 运行失败：\(result.stderr)\n\(result.message)"
                )
            }
        }
    }

    func testCCompilationFailureReturnsCompilerDiagnostics() async {
        let result = await CodeExecutionService.run(
            code: "int main(void) { this is not C }",
            language: "c",
            input: "",
            expectedOutput: ""
        )

        XCTAssertFalse(result.succeeded)
        XCTAssertFalse(result.stderr.isEmpty)
        XCTAssertEqual(result.exitCode != 0, true)
    }

    func testWrongProgramOutputFailsJudging() async {
        let result = await CodeExecutionService.run(
            code: """
            #include <stdio.h>
            int main(void) {
                printf("wrong\\n");
                return 0;
            }
            """,
            language: "c",
            input: "",
            expectedOutput: "expected"
        )

        XCTAssertTrue(result.succeeded)
        XCTAssertFalse(result.passed)
    }
    #else
    func testCodeExecutionIsUnavailableOnIOS() async {
        let result = await CodeExecutionService.run(
            code: "int main(void) { return 0; }",
            language: "c",
            input: "",
            expectedOutput: ""
        )
        XCTAssertFalse(result.succeeded)
        XCTAssertTrue(result.message.contains("同步服务") || result.message.contains("Mac"))
    }
    #endif
}
