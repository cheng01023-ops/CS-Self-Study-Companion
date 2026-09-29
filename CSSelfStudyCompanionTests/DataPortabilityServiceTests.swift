import XCTest
@testable import CSSelfStudyCompanion

@MainActor
final class DataPortabilityServiceTests: XCTestCase {
    func testBackupAndRestorePreserveLearningData() throws {
        let sourceContainer = try AppTestSupport.makeContainer()
        let source = sourceContainer.mainContext
        let date = AppTestSupport.fixedDate

        source.insert(Progress(
            itemID: "tutorial:backup",
            isCompleted: true,
            score: 0.95,
            lastStudiedAt: date,
            completedAt: date
        ))
        source.insert(Bookmark(
            id: "bookmark:backup",
            targetID: "tutorial:backup:step:2",
            targetType: "tutorialStep",
            title: "收藏标题",
            subtitle: "收藏副标题",
            createdAt: date
        ))
        source.insert(LearningNote(
            id: "note:backup",
            targetID: "tutorial:backup:step:2",
            title: "笔记标题",
            body: "需要复习指针和内存布局。",
            createdAt: date,
            updatedAt: date
        ))
        source.insert(ReviewItem(
            id: "review:backup",
            sourceType: "test",
            sourceID: "source:backup",
            title: "复习标题",
            question: "问题",
            referenceAnswer: "答案",
            explanation: "解释",
            dueAt: date,
            intervalIndex: 3,
            correctStreak: 3,
            lapseCount: 1,
            createdAt: date,
            lastReviewedAt: date,
            isArchived: false,
            easeFactor: 2.7,
            stabilityDays: 18,
            lastResponseSeconds: 6
        ))
        source.insert(CodeDraft(
            exerciseID: "exercise:backup",
            sourceCode: "int main(void) { return 0; }",
            input: "输入",
            lastOutput: "完成",
            passed: true,
            updatedAt: date,
            lastRunAt: date
        ))
        source.insert(MasteryRecord(
            conceptID: "pointer",
            score: 0.82,
            attempts: 5,
            correctCount: 4,
            wrongCount: 1,
            lastReason: "主动回忆通过",
            lastPracticedAt: date
        ))
        try source.save()

        let data = try DataPortabilityService.data(from: source)
        let destinationContainer = try AppTestSupport.makeContainer()
        let destination = destinationContainer.mainContext
        try DataPortabilityService.restore(from: data, into: destination)

        let progress = try AppTestSupport.fetch(Progress.self, in: destination)
        let bookmarks = try AppTestSupport.fetch(Bookmark.self, in: destination)
        let notes = try AppTestSupport.fetch(LearningNote.self, in: destination)
        let reviews = try AppTestSupport.fetch(ReviewItem.self, in: destination)
        let drafts = try AppTestSupport.fetch(CodeDraft.self, in: destination)
        let mastery = try AppTestSupport.fetch(MasteryRecord.self, in: destination)

        XCTAssertEqual(progress.first?.isCompleted, true)
        XCTAssertEqual(progress.first?.score, 0.95)
        XCTAssertEqual(bookmarks.first?.title, "收藏标题")
        XCTAssertEqual(notes.first?.body, "需要复习指针和内存布局。")
        XCTAssertEqual(reviews.first?.dueAt, date)
        XCTAssertEqual(reviews.first?.intervalIndex, 3)
        XCTAssertEqual(reviews.first?.easeFactor ?? 0, 2.7, accuracy: 0.0001)
        XCTAssertEqual(reviews.first?.stabilityDays ?? 0, 18, accuracy: 0.0001)
        XCTAssertEqual(drafts.first?.sourceCode, "int main(void) { return 0; }")
        XCTAssertEqual(mastery.first?.score ?? 0, 0.82, accuracy: 0.0001)
    }

    func testRestoreKeepsNewerLocalRecord() throws {
        let sourceContainer = try AppTestSupport.makeContainer()
        let source = sourceContainer.mainContext
        let older = AppTestSupport.fixedDate
        let newer = older.addingTimeInterval(3600)

        source.insert(Progress(
            itemID: "conflict",
            isCompleted: true,
            score: 1,
            lastStudiedAt: older,
            completedAt: older
        ))
        let backup = try DataPortabilityService.data(from: source)

        let destinationContainer = try AppTestSupport.makeContainer()
        let destination = destinationContainer.mainContext
        destination.insert(Progress(
            itemID: "conflict",
            isCompleted: false,
            score: 0.25,
            lastStudiedAt: newer
        ))
        try destination.save()

        try DataPortabilityService.restore(from: backup, into: destination)
        let result = try AppTestSupport.fetch(Progress.self, in: destination)

        XCTAssertEqual(result.first?.isCompleted, false)
        XCTAssertEqual(result.first?.score, 0.25)
        XCTAssertEqual(result.first?.lastStudiedAt, newer)
    }

    func testEncryptedBackupRequiresCorrectPassword() throws {
        let sourceContainer = try AppTestSupport.makeContainer()
        let source = sourceContainer.mainContext
        source.insert(Progress(
            itemID: "encrypted",
            isCompleted: true,
            score: 1,
            lastStudiedAt: AppTestSupport.fixedDate,
            completedAt: AppTestSupport.fixedDate
        ))
        try source.save()

        let encrypted = try DataPortabilityService.encryptedData(
            from: source,
            password: "correct-password"
        )

        let wrongContainer = try AppTestSupport.makeContainer()
        let wrongDestination = wrongContainer.mainContext
        do {
            try DataPortabilityService.restore(
                from: encrypted,
                password: "wrong-password",
                into: wrongDestination
            )
            XCTFail("错误密码不应恢复成功")
        } catch {
            XCTAssertTrue(try AppTestSupport.fetch(Progress.self, in: wrongDestination).isEmpty)
        }

        let correctContainer = try AppTestSupport.makeContainer()
        let correctDestination = correctContainer.mainContext
        try DataPortabilityService.restore(
            from: encrypted,
            password: "correct-password",
            into: correctDestination
        )
        XCTAssertEqual(
            try AppTestSupport.fetch(Progress.self, in: correctDestination).first?.isCompleted,
            true
        )
    }
}
