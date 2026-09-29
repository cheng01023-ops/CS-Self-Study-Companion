import Foundation
import SwiftData
@testable import CSSelfStudyCompanion

enum AppTestSupport {
    static let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    @MainActor
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Stage.self,
            Topic.self,
            Tutorial.self,
            Exercise.self,
            Progress.self,
            Command.self,
            LearningResource.self,
            Concept.self,
            Bookmark.self,
            LearningNote.self,
            ReviewItem.self,
            CodeDraft.self,
            MasteryRecord.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    @MainActor
    static func fetch<T: PersistentModel>(
        _ type: T.Type,
        in context: ModelContext
    ) throws -> [T] {
        try context.fetch(FetchDescriptor<T>())
    }

    @MainActor
    static func makeReviewItem(
        id: String = "review-test",
        sourceID: String = "source-test",
        dueAt: Date = fixedDate,
        intervalIndex: Int = 0,
        easeFactor: Double = 2.3,
        stabilityDays: Double = 1
    ) -> ReviewItem {
        ReviewItem(
            id: id,
            sourceType: "test",
            sourceID: sourceID,
            title: "测试复习项",
            question: "测试问题",
            referenceAnswer: "测试答案",
            explanation: "测试解释",
            dueAt: dueAt,
            intervalIndex: intervalIndex,
            easeFactor: easeFactor,
            stabilityDays: stabilityDays
        )
    }
}
