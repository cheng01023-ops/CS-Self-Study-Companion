import XCTest
@testable import CSSelfStudyCompanion

final class CodeReadingCatalogTests: XCTestCase {
    func testOpenSourceReadingLadderIsCompleteAndLinked() {
        let missions = OpenSourceReadingCatalog.missions
        let projectIDs = Set(ProjectCatalog.projects.map(\.id))

        XCTAssertGreaterThanOrEqual(missions.count, 10)
        XCTAssertEqual(Set(missions.map(\.id)).count, missions.count)
        XCTAssertEqual(Set(missions.map(\.level)), Set(OpenSourceReadingLevel.allCases))

        for mission in missions {
            XCTAssertNotNil(URL(string: mission.repositoryURL))
            XCTAssertTrue(mission.repositoryURL.hasPrefix("https://"))
            XCTAssertGreaterThanOrEqual(mission.entryPoints.count, 3)
            XCTAssertGreaterThanOrEqual(mission.searchSymbols.count, 3)
            XCTAssertGreaterThanOrEqual(mission.tasks.count, 4)
            XCTAssertGreaterThanOrEqual(mission.evidence.count, 3)
            XCTAssertEqual(mission.checkpoints.count, mission.tasks.count)
            XCTAssertGreaterThanOrEqual(mission.pitfalls.count, 3)
            XCTAssertFalse(mission.reflectionQuestion.isEmpty)
            XCTAssertTrue(mission.relatedProjectIDs.allSatisfy { projectIDs.contains($0) })
        }
    }

    func testOpenSourceEvidenceCodecRoundTrips() {
        let original = OpenSourceReadingEvidence(
            repositorySnapshot: "src/ 与 lib/",
            entryPointNotes: "main -> run",
            callChain: "A -> B -> C",
            rawEvidence: "line 42",
            unresolvedQuestions: "错误恢复未追完",
            reflection: "先找入口，再追数据流"
        )

        let decoded = OpenSourceReadingEvidenceCodec.decode(
            OpenSourceReadingEvidenceCodec.encode(original)
        )
        XCTAssertEqual(decoded, original)
    }

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
