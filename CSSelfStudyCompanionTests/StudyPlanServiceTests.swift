import SwiftData
import XCTest
@testable import CSSelfStudyCompanion

@MainActor
final class StudyPlanServiceTests: XCTestCase {
    func testPlanPrioritizesReviewWeakConceptAndNextTutorial() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext
        let concept = Concept(
            id: "pointer",
            name: "指针",
            category: "C",
            summary: "指针",
            details: "指针"
        )
        let tutorial = Tutorial(
            id: "tutorial-next",
            order: 2,
            title: "下一课",
            summary: "摘要",
            markdown: "正文"
        )
        let topic = Topic(
            id: "topic",
            order: 0,
            title: "主题",
            summary: "摘要",
            estimatedMinutes: 40
        )
        context.insert(concept)
        context.insert(topic)
        context.insert(tutorial)
        tutorial.topic = topic

        let record = MasteryRecord(conceptID: "pointer", score: 0.5, attempts: 2)
        let weak = WeakConcept(concept: concept, record: record)
        let plan = StudyPlanService.makePlan(
            dueReviewCount: 4,
            weakConcept: weak,
            tutorials: [tutorial],
            completedTutorialIDs: []
        )

        XCTAssertEqual(plan.map(\.title), ["完成到期复习", "加强概念：指针", "继续教程：下一课"])
        XCTAssertEqual(plan.reduce(0) { $0 + $1.minutes }, 60)
    }

    func testRecommendedStageMapping() {
        XCTAssertEqual(StudyPlanService.recommendedStageOrder(for: 0), 0)
        XCTAssertEqual(StudyPlanService.recommendedStageOrder(for: 3), 1)
        XCTAssertEqual(StudyPlanService.recommendedStageOrder(for: 5), 2)
        XCTAssertEqual(StudyPlanService.recommendedStageOrder(for: 8), 3)
    }
}
