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
    }
}
