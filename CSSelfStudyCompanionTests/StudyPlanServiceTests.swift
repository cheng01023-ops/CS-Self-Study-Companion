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

    func testAdaptivePathUsesDependenciesCompletionAndMastery() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext

        let stage = Stage(id: "adaptive-stage", order: 0, title: "路线", subtitle: "", icon: "map", themeHex: "4F7CFF")
        let topic = Topic(id: "adaptive-topic", order: 1, title: "依赖", summary: "", estimatedMinutes: 30)
        let hashTutorial = Tutorial(id: "tutorial-hash", order: 1, title: "哈希表", summary: "", markdown: "")
        let treeTutorial = Tutorial(id: "tutorial-tree", order: 2, title: "树", summary: "", markdown: "")
        let hashConcept = Concept(
            id: "hash-table",
            name: "哈希表",
            category: "算法",
            summary: "",
            details: "",
            relatedTutorialIDs: ["tutorial-hash"]
        )
        let treeConcept = Concept(
            id: "tree",
            name: "树",
            category: "算法",
            summary: "",
            details: "",
            relatedTutorialIDs: ["tutorial-tree"]
        )

        context.insert(stage)
        context.insert(topic)
        context.insert(hashTutorial)
        context.insert(treeTutorial)
        context.insert(hashConcept)
        context.insert(treeConcept)
        stage.topics.append(topic)
        topic.stage = stage
        topic.tutorials.append(hashTutorial)
        topic.tutorials.append(treeTutorial)
        hashTutorial.topic = topic
        treeTutorial.topic = topic

        var snapshot = AdaptiveLearningService.snapshot(
            tutorials: [hashTutorial, treeTutorial],
            concepts: [hashConcept, treeConcept],
            masteryRecords: [],
            progressRecords: []
        )
        XCTAssertEqual(snapshot.nextItem?.tutorial.id, "tutorial-hash")
        XCTAssertEqual(snapshot.items.first { $0.tutorial.id == "tutorial-tree" }?.level, .needsBridge)

        let hashProgress = Progress(
            itemID: .tutorialProgressID("tutorial-hash"),
            isCompleted: true,
            completedAt: .now
        )
        context.insert(hashProgress)
        snapshot = AdaptiveLearningService.snapshot(
            tutorials: [hashTutorial, treeTutorial],
            concepts: [hashConcept, treeConcept],
            masteryRecords: [],
            progressRecords: [hashProgress]
        )
        XCTAssertEqual(snapshot.items.first { $0.tutorial.id == "tutorial-tree" }?.level, .ready)

        let lowMastery = MasteryRecord(conceptID: "hash-table", score: 0.4, attempts: 3)
        context.insert(lowMastery)
        snapshot = AdaptiveLearningService.snapshot(
            tutorials: [hashTutorial, treeTutorial],
            concepts: [hashConcept, treeConcept],
            masteryRecords: [lowMastery],
            progressRecords: [hashProgress]
        )
        XCTAssertEqual(snapshot.items.first { $0.tutorial.id == "tutorial-tree" }?.level, .needsBridge)

        let preferredPlan = StudyPlanService.makePlan(
            dueReviewCount: 0,
            weakConcept: nil,
            tutorials: [hashTutorial, treeTutorial],
            completedTutorialIDs: ["tutorial-hash"],
            preferredTutorialID: "tutorial-tree"
        )
        XCTAssertTrue(preferredPlan.contains { $0.id == "tutorial:tutorial-tree" })
    }

    func testDynamicPracticePrioritizesWeakConceptsAndKeepsAnswerValid() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext
        let weak = Concept(id: "set", name: "集合", category: "数学", summary: "集合描述元素整体", details: "")
        let strong = Concept(id: "pointer", name: "指针", category: "C", summary: "指针保存地址", details: "")
        context.insert(weak)
        context.insert(strong)

        let weakRecord = MasteryRecord(conceptID: "set", score: 0.2, attempts: 3)
        let strongRecord = MasteryRecord(conceptID: "pointer", score: 0.9, attempts: 3)
        context.insert(weakRecord)
        context.insert(strongRecord)

        let questions = AdaptivePracticeService.generateSession(
            concepts: [strong, weak],
            masteryRecords: [strongRecord, weakRecord],
            count: 2,
            seed: 42
        )

        XCTAssertEqual(questions.count, 2)
        XCTAssertEqual(questions.first?.conceptID, "set")
        XCTAssertTrue(questions.allSatisfy { question in
            question.options.indices.contains(question.correctIndex)
                && !question.options[question.correctIndex].isEmpty
                && !question.explanation.isEmpty
        })
    }

    func testConceptPracticeReviewItemIsStable() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext

        ReviewService.scheduleConceptPractice(
            conceptID: "set",
            title: "集合",
            question: "集合的并集是什么？",
            referenceAnswer: "包含两个集合所有元素",
            needsReview: true,
            in: context
        )
        ReviewService.scheduleConceptPractice(
            conceptID: "set",
            title: "集合",
            question: "集合的交集是什么？",
            referenceAnswer: "只包含共同元素",
            needsReview: true,
            in: context
        )

        let items = try AppTestSupport.fetch(ReviewItem.self, in: context)
        XCTAssertEqual(items.filter { $0.sourceID == "practice:set" }.count, 1)
        XCTAssertEqual(items.first { $0.sourceID == "practice:set" }?.question, "集合的交集是什么？")
    }

    func testRecommendedStageMapping() {
        XCTAssertEqual(StudyPlanService.recommendedStageOrder(for: 0), 0)
        XCTAssertEqual(StudyPlanService.recommendedStageOrder(for: 3), 1)
        XCTAssertEqual(StudyPlanService.recommendedStageOrder(for: 5), 2)
        XCTAssertEqual(StudyPlanService.recommendedStageOrder(for: 8), 3)
        XCTAssertEqual(StudyPlanService.recommendedStageOrder(for: 10), 4)
    }
}
