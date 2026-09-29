import SwiftData
import XCTest
@testable import CSSelfStudyCompanion

@MainActor
final class ContentIntegrityTests: XCTestCase {
    func testLearningCatalogHasCompleteUniqueStructure() {
        let stages = LearningCatalog.stages
        XCTAssertEqual(stages.count, 11)
        XCTAssertEqual(Set(stages.map(\.id)).count, stages.count)
        XCTAssertEqual(stages.map(\.order), Array(0..<stages.count))

        let topics = stages.flatMap(\.topics)
        let tutorials = topics.flatMap(\.tutorials)
        XCTAssertFalse(topics.isEmpty)
        XCTAssertEqual(tutorials.count, 19)
        XCTAssertEqual(Set(topics.map(\.id)).count, topics.count)
        XCTAssertEqual(Set(tutorials.map(\.id)).count, tutorials.count)
        XCTAssertTrue(topics.allSatisfy { !$0.title.isEmpty && !$0.summary.isEmpty })
        XCTAssertTrue(tutorials.allSatisfy { !$0.title.isEmpty && !$0.summary.isEmpty })
    }

    func testEveryTutorialHasRelevantResources() {
        let tutorials = LearningCatalog.stages
            .flatMap(\.topics)
            .flatMap(\.tutorials)
        let tutorialIDs = Set(tutorials.map(\.id))
        let resources = LearningResourceCatalog.all
        let counts = Dictionary(grouping: resources, by: \.tutorialID).mapValues(\.count)

        XCTAssertEqual(resources.count, 62)
        XCTAssertEqual(Set(resources.map(\.id)).count, resources.count)
        XCTAssertEqual(Set(resources.map(\.tutorialID)), tutorialIDs)
        XCTAssertTrue(resources.allSatisfy { resource in
            guard let url = URL(string: resource.urlString) else { return false }
            return url.scheme == "https"
                && !resource.title.isEmpty
                && !resource.provider.isEmpty
                && resource.explanation.count >= 20
        })

        for tutorial in tutorials {
            XCTAssertGreaterThanOrEqual(
                counts[tutorial.id, default: 0],
                3,
                "教程 \(tutorial.id) 至少需要 3 条配套资源"
            )
        }
    }

    func testCommandCatalogIsSearchableAndComplete() {
        let commands = CommandCatalog.all
        XCTAssertEqual(commands.count, 52)
        XCTAssertEqual(Set(commands.map(\.id)).count, commands.count)
        XCTAssertTrue(commands.allSatisfy { command in
            !command.name.isEmpty
                && !command.syntax.isEmpty
                && !command.explanation.isEmpty
                && !command.example.isEmpty
                && !command.platform.isEmpty
        })
    }

    func testConceptDependenciesOnlyReferenceKnownConcepts() {
        let concepts = ConceptCatalog.all
        let conceptIDs = Set(concepts.map(\.id))
        XCTAssertEqual(concepts.count, conceptIDs.count)

        for concept in concepts {
            for prerequisite in ConceptDependencyCatalog.prerequisites(for: concept.id) {
                XCTAssertTrue(
                    conceptIDs.contains(prerequisite),
                    "\(concept.id) 引用了不存在的概念 \(prerequisite)"
                )
            }
        }
    }

    func testSeedServicePopulatesCoreDatabase() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext
        SeedService.seedIfNeeded(in: context)

        XCTAssertEqual(try AppTestSupport.fetch(Stage.self, in: context).count, 11)
        XCTAssertEqual(try AppTestSupport.fetch(Tutorial.self, in: context).count, 19)
        XCTAssertEqual(try AppTestSupport.fetch(LearningResource.self, in: context).count, 62)
        XCTAssertEqual(try AppTestSupport.fetch(Command.self, in: context).count, 52)
        XCTAssertGreaterThanOrEqual(try AppTestSupport.fetch(Exercise.self, in: context).count, 19)
    }
}
