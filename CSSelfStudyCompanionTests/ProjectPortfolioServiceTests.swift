import XCTest
@testable import CSSelfStudyCompanion

final class ProjectPortfolioServiceTests: XCTestCase {
    func testPortfolioCalculatesMilestoneProgress() {
        let project = ProjectCatalog.projects[0]
        let milestone = project.milestones[0]
        let record = Progress(
            itemID: "project:\(project.id):milestone:\(milestone.id)",
            isCompleted: true,
            completedAt: .now
        )

        let items = ProjectPortfolioService.items(progressRecords: [record])
        let item = items.first { $0.project.id == project.id }

        XCTAssertEqual(item?.completedMilestones, 1)
        XCTAssertEqual(item?.totalMilestones, project.milestones.count)
        XCTAssertFalse(item?.isCompleted ?? true)
    }

    func testProjectLadderHasEngineeringProfilesAndReadingLinks() {
        let projects = ProjectCatalog.projects
        let readingIDs = Set(OpenSourceReadingCatalog.missions.map(\.id))

        XCTAssertGreaterThanOrEqual(projects.count, 10)
        XCTAssertEqual(Set(projects.map(\.id)).count, projects.count)
        XCTAssertEqual(Set(projects.map(\.order)), Set(1...projects.count))
        XCTAssertEqual(Set(projects.map(\.track)), Set(ProjectTrack.allCases))

        for project in projects {
            XCTAssertGreaterThanOrEqual(project.estimatedHours, 10)
            XCTAssertGreaterThanOrEqual(project.prerequisites.count, 2)
            XCTAssertGreaterThanOrEqual(project.repository.count, 4)
            XCTAssertGreaterThanOrEqual(project.qualityGates.count, 3)
            XCTAssertGreaterThanOrEqual(project.releaseChecklist.count, 3)
            XCTAssertGreaterThanOrEqual(project.milestones.count, 4)
            XCTAssertFalse(project.readingMissionIDs.isEmpty)
            XCTAssertTrue(project.readingMissionIDs.allSatisfy { readingIDs.contains($0) })
            XCTAssertTrue(project.milestones.allSatisfy {
                !$0.title.isEmpty && !$0.outputs.isEmpty && !$0.checks.isEmpty
            })
        }
    }

    func testRecommendedNextIgnoresCompletedProjects() {
        let first = ProjectCatalog.projects[0]
        let firstProgress = first.milestones.map {
            Progress(itemID: "project:\(first.id):milestone:\($0.id)", isCompleted: true)
        }

        let next = ProjectPortfolioService.recommendedNext(progressRecords: firstProgress)
        XCTAssertNotEqual(next?.project.id, first.id)
        XCTAssertEqual(next?.project.id, ProjectCatalog.projects[1].id)
    }

    func testMarkdownContainsCompletionAndDeliverables() {
        let project = ProjectCatalog.projects[0]
        let progress = project.milestones.map {
            Progress(
                itemID: "project:\(project.id):milestone:\($0.id)",
                isCompleted: true,
                completedAt: .now
            )
        }

        let markdown = ProjectPortfolioService.markdown(progressRecords: progress)
        XCTAssertTrue(markdown.contains("# CS 自学项目作品集"))
        XCTAssertTrue(markdown.contains(project.title))
        XCTAssertTrue(markdown.contains("- [x]"))
        XCTAssertTrue(markdown.contains("交付物"))
        XCTAssertTrue(markdown.contains("仓库地图"))
        XCTAssertTrue(markdown.contains("质量门禁"))
    }
}
