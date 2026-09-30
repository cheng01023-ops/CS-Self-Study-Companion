import SwiftData
import XCTest
@testable import CSSelfStudyCompanion

@MainActor
final class ContentIntegrityTests: XCTestCase {
    func testLearningCatalogHasCompleteUniqueStructure() {
        let stages = LearningCatalog.stages
        XCTAssertEqual(stages.count, 13)
        XCTAssertEqual(Set(stages.map(\.id)).count, stages.count)
        XCTAssertEqual(stages.map(\.order), Array(0..<stages.count))

        let topics = stages.flatMap(\.topics)
        let tutorials = topics.flatMap(\.tutorials)
        XCTAssertFalse(topics.isEmpty)
        XCTAssertEqual(tutorials.count, 28)
        XCTAssertEqual(Set(topics.map(\.id)).count, topics.count)
        XCTAssertEqual(Set(tutorials.map(\.id)).count, tutorials.count)
        XCTAssertTrue(topics.allSatisfy { !$0.title.isEmpty && !$0.summary.isEmpty })
        XCTAssertTrue(tutorials.allSatisfy { !$0.title.isEmpty && !$0.summary.isEmpty })
    }

    func testMathAndTheoryMainlineIsComplete() {
        let stages = LearningCatalog.stages
        let math = stages.first { $0.id == "stage-math" }
        let theory = stages.first { $0.id == "stage-theory" }

        XCTAssertEqual(math?.order, 4)
        XCTAssertEqual(theory?.order, 5)
        XCTAssertEqual(math?.topics.count, 3)
        XCTAssertEqual(theory?.topics.count, 4)

        let expectedTutorialIDs: Set<String> = [
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
        let theoryTutorials = ((math?.topics ?? []) + (theory?.topics ?? []))
            .flatMap(\.tutorials)
        XCTAssertEqual(Set(theoryTutorials.map(\.id)), expectedTutorialIDs)
        XCTAssertTrue(theoryTutorials.allSatisfy {
            !$0.markdown.isEmpty
                && !$0.code.isEmpty
                && !$0.secondCode.isEmpty
                && !$0.summary.isEmpty
        })
        XCTAssertTrue(((math?.topics ?? []) + (theory?.topics ?? [])).allSatisfy {
            $0.exercises.count >= 2
        })

        let labs = LabCatalog.labs
        XCTAssertEqual(Set(labs.map(\.id)).count, labs.count)
        XCTAssertTrue([
            "logic",
            "automata",
            "probability",
            "growth"
        ].allSatisfy { id in labs.contains { $0.id == id } })
    }

    func testEveryTutorialHasRelevantResources() {
        let tutorials = LearningCatalog.stages
            .flatMap(\.topics)
            .flatMap(\.tutorials)
        let tutorialIDs = Set(tutorials.map(\.id))
        let resources = LearningResourceCatalog.all
        let counts = Dictionary(grouping: resources, by: \.tutorialID).mapValues(\.count)

        XCTAssertEqual(resources.count, 89)
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

    func testEveryTutorialHasVerifiableLabBlueprint() {
        let tutorials = LearningCatalog.stages
            .flatMap(\.topics)
            .flatMap(\.tutorials)

        for tutorial in tutorials {
            let lab = TutorialLabCatalog.blueprint(
                tutorialID: tutorial.id,
                title: tutorial.title,
                summary: tutorial.summary,
                codeLanguage: tutorial.codeLanguage,
                code: tutorial.code
            )

            XCTAssertEqual(lab.tutorialID, tutorial.id)
            XCTAssertFalse(lab.objective.isEmpty, "\(tutorial.id) 缺少实验目标")
            XCTAssertFalse(lab.scenario.isEmpty, "\(tutorial.id) 缺少实验场景")
            XCTAssertGreaterThanOrEqual(lab.prerequisites.count, 2, "\(tutorial.id) 前置条件不足")
            XCTAssertGreaterThanOrEqual(lab.expectedSignals.count, 3, "\(tutorial.id) 可验证信号不足")
            XCTAssertGreaterThanOrEqual(lab.checkpoints.count, 3, "\(tutorial.id) 验收清单不足")
            XCTAssertTrue(lab.checkpoints.allSatisfy { !$0.title.isEmpty && !$0.successCriterion.isEmpty })

            let markdown = TutorialLabCatalog.markdownSection(
                tutorialID: tutorial.id,
                title: tutorial.title,
                summary: tutorial.summary,
                codeLanguage: tutorial.codeLanguage,
                code: tutorial.code
            )
            XCTAssertTrue(markdown.contains("可验证实验课"))
            XCTAssertTrue(markdown.contains("第四步：验证结果"))
            XCTAssertTrue(markdown.contains("第五步：故意制造一次失败"))
        }
    }

    func testLabEvidenceCodecRoundTripsAllFields() {
        let original = TutorialLabEvidence(
            prediction: "输出 5",
            preparationConfirmed: true,
            rollbackPlan: "删除 /tmp/cs-lab",
            commandUsed: "./program",
            observedOutput: "flags = 5",
            exitCode: "0",
            anomaly: "无",
            rootCause: "位移范围正确",
            insight: "先检查类型宽度"
        )

        let decoded = TutorialLabEvidenceCodec.decode(TutorialLabEvidenceCodec.encode(original))
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(TutorialLabEvidenceCodec.decode("普通笔记"), .empty)
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

    func testSeedServiceAddsTheoryStagesToExistingDatabase() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext
        context.insert(
            Stage(
                id: "stage-0",
                order: 0,
                title: "旧标题",
                subtitle: "旧摘要",
                icon: "book",
                themeHex: "000000"
            )
        )
        try context.save()

        SeedService.seedIfNeeded(in: context)

        let stages = try AppTestSupport.fetch(Stage.self, in: context)
        XCTAssertEqual(stages.count, 13)
        XCTAssertEqual(stages.first { $0.id == "stage-math" }?.order, 4)
        XCTAssertEqual(stages.first { $0.id == "stage-theory" }?.order, 5)
        XCTAssertEqual(try AppTestSupport.fetch(Tutorial.self, in: context).count, 28)
        XCTAssertEqual(try AppTestSupport.fetch(LearningResource.self, in: context).count, 89)
    }

    func testSeedServicePopulatesCoreDatabase() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext
        SeedService.seedIfNeeded(in: context)

        XCTAssertEqual(try AppTestSupport.fetch(Stage.self, in: context).count, 13)
        XCTAssertEqual(try AppTestSupport.fetch(Tutorial.self, in: context).count, 28)
        XCTAssertEqual(try AppTestSupport.fetch(LearningResource.self, in: context).count, 89)
        XCTAssertEqual(try AppTestSupport.fetch(Command.self, in: context).count, 52)
        XCTAssertGreaterThanOrEqual(try AppTestSupport.fetch(Exercise.self, in: context).count, 19)
    }
}
