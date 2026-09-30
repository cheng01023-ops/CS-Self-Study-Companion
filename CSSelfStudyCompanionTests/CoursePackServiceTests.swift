import SwiftData
import XCTest
@testable import CSSelfStudyCompanion

@MainActor
final class CoursePackServiceTests: XCTestCase {
    func testExportContainsCompleteBuiltInCourse() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext
        SeedService.seedIfNeeded(in: context)

        let pack = try CoursePackService.exportPack(from: context)
        XCTAssertEqual(pack.formatVersion, CoursePackService.currentFormatVersion)
        XCTAssertEqual(pack.stages.count, 13)
        XCTAssertEqual(pack.stages.flatMap(\.topics).flatMap(\.tutorials).count, 28)
        XCTAssertEqual(pack.stages.flatMap(\.topics).flatMap(\.tutorials).flatMap(\.resources).count, 89)
    }

    func testImportIntoEmptyDatabaseRestoresCourse() throws {
        let sourceContainer = try AppTestSupport.makeContainer()
        SeedService.seedIfNeeded(in: sourceContainer.mainContext)
        let pack = try CoursePackService.exportPack(from: sourceContainer.mainContext)

        let targetContainer = try AppTestSupport.makeContainer()
        let report = try CoursePackService.importPack(pack, into: targetContainer.mainContext)

        XCTAssertEqual(report.addedStages, 13)
        XCTAssertEqual(report.addedTutorials, 28)
        XCTAssertEqual(report.addedResources, 89)
        XCTAssertEqual(try AppTestSupport.fetch(Stage.self, in: targetContainer.mainContext).count, 13)
        XCTAssertEqual(try AppTestSupport.fetch(Tutorial.self, in: targetContainer.mainContext).count, 28)
        XCTAssertEqual(try AppTestSupport.fetch(LearningResource.self, in: targetContainer.mainContext).count, 89)
    }

    func testCourseUpdatePreservesUserProgress() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext
        SeedService.seedIfNeeded(in: context)

        let firstTutorialID = try XCTUnwrap(try AppTestSupport.fetch(Tutorial.self, in: context).sorted { $0.order < $1.order }.first?.id)
        ProgressService.setCompleted(
            true,
            itemID: .tutorialProgressID(firstTutorialID),
            in: context
        )

        var pack = try CoursePackService.exportPack(from: context)
        pack.contentVersion = "test-update"
        for stageIndex in pack.stages.indices {
            for topicIndex in pack.stages[stageIndex].topics.indices {
                for tutorialIndex in pack.stages[stageIndex].topics[topicIndex].tutorials.indices {
                    if pack.stages[stageIndex].topics[topicIndex].tutorials[tutorialIndex].id == firstTutorialID {
                        pack.stages[stageIndex].topics[topicIndex].tutorials[tutorialIndex].title = "更新后的教程标题"
                    }
                }
            }
        }
        _ = try CoursePackService.importPack(pack, into: context)

        let progress = try AppTestSupport.fetch(Progress.self, in: context)
        XCTAssertTrue(progress.contains { $0.itemID == .tutorialProgressID(firstTutorialID) && $0.isCompleted })
        let tutorial = try AppTestSupport.fetch(Tutorial.self, in: context).first { $0.id == firstTutorialID }
        XCTAssertEqual(tutorial?.title, "更新后的教程标题")
    }

    func testDuplicateIDsAreRejected() {
        let duplicateStage = CoursePackStage(
            id: "same",
            order: 0,
            title: "A",
            subtitle: "",
            icon: "book",
            themeHex: "000000",
            topics: []
        )
        let pack = CoursePack(
            formatVersion: 1,
            contentVersion: "bad",
            updatedAt: .now,
            minimumAppVersion: nil,
            stages: [duplicateStage, duplicateStage]
        )

        XCTAssertThrowsError(try CoursePackService.validate(pack))
    }
}
