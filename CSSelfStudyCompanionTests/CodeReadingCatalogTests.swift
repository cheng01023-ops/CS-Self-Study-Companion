import XCTest
@testable import CSSelfStudyCompanion

final class CodeReadingCatalogTests: XCTestCase {
    func testCatalogHasUniqueAndValidExercises() {
        let exercises = CodeReadingCatalog.exercises
        XCTAssertGreaterThanOrEqual(exercises.count, 10)
        XCTAssertEqual(Set(exercises.map(\.id)).count, exercises.count)
        XCTAssertTrue(exercises.allSatisfy { exercise in
            !exercise.title.isEmpty
                && !exercise.code.isEmpty
                && !exercise.prompt.isEmpty
                && exercise.options.indices.contains(exercise.correctIndex)
                && !exercise.explanation.isEmpty
        })
        XCTAssertGreaterThanOrEqual(Set(exercises.map(\.focus)).count, 6)
    }
}
