import Foundation

struct CodeExerciseSpec {
    let exerciseID: String
    let language: String
    let testCases: [CodeTestCase]

    var primaryTestCase: CodeTestCase? {
        testCases.first
    }
}

enum CodeExerciseCatalog {
    static func spec(for exerciseID: String) -> CodeExerciseSpec? {
        specs[exerciseID]
    }

    private static let specs: [String: CodeExerciseSpec] = [
        "exercise-first-c": CodeExerciseSpec(
            exerciseID: "exercise-first-c",
            language: "c",
            testCases: [
                CodeTestCase(
                    id: "basic",
                    name: "基本问候",
                    input: "",
                    expectedOutput: "你好，Ada！",
                    arguments: ["Ada"]
                )
            ]
        ),
        "exercise-bit-flags": CodeExerciseSpec(
            exerciseID: "exercise-bit-flags",
            language: "c",
            testCases: [
                CodeTestCase(
                    id: "flags-5",
                    name: "flags = 5",
                    input: "5\n",
                    expectedOutput: "read=yes\nwrite=no\nexecute=yes"
                )
            ]
        ),
        "exercise-c-average": CodeExerciseSpec(
            exerciseID: "exercise-c-average",
            language: "c",
            testCases: [
                CodeTestCase(
                    id: "three-scores",
                    name: "三个分数",
                    input: "3 80 90 100\n",
                    expectedOutput: "90.00"
                )
            ]
        ),
        "exercise-architecture-code": CodeExerciseSpec(
            exerciseID: "exercise-architecture-code",
            language: "c",
            testCases: [
                CodeTestCase(
                    id: "layout",
                    name: "结构体布局",
                    input: "",
                    expectedOutput: "size=16\ntag=0 count=4 value=8"
                )
            ]
        ),
        "exercise-os-code": CodeExerciseSpec(
            exerciseID: "exercise-os-code",
            language: "c",
            testCases: [
                CodeTestCase(
                    id: "threads",
                    name: "四线程累加",
                    input: "",
                    expectedOutput: "400000"
                )
            ]
        )
    ]
}
