import XCTest
@testable import CSSelfStudyCompanion

@MainActor
final class ReviewServiceTests: XCTestCase {
    func testDueItemsFiltersArchivedAndFutureItemsAndSortsByDate() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext
        let now = AppTestSupport.fixedDate

        let overdue = AppTestSupport.makeReviewItem(
            id: "overdue",
            sourceID: "overdue-source",
            dueAt: now.addingTimeInterval(-3600)
        )
        let dueNow = AppTestSupport.makeReviewItem(
            id: "due-now",
            sourceID: "due-now-source",
            dueAt: now
        )
        let future = AppTestSupport.makeReviewItem(
            id: "future",
            sourceID: "future-source",
            dueAt: now.addingTimeInterval(3600)
        )
        let archived = AppTestSupport.makeReviewItem(
            id: "archived",
            sourceID: "archived-source",
            dueAt: now.addingTimeInterval(-7200)
        )
        archived.isArchived = true

        [overdue, dueNow, future, archived].forEach(context.insert)
        let due = ReviewService.dueItems(from: [future, dueNow, archived, overdue], now: now)

        XCTAssertEqual(due.map(\.id), ["overdue", "due-now"])
        XCTAssertEqual(
            ReviewService.upcomingItems(from: [future, dueNow, overdue], now: now).map(\.id),
            ["future"]
        )
    }

    func testRememberedReviewAdvancesScheduleDeterministically() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext
        let now = AppTestSupport.fixedDate
        let item = AppTestSupport.makeReviewItem(dueAt: now)
        context.insert(item)

        ReviewService.review(
            item,
            remembered: true,
            responseSeconds: 4,
            now: now,
            schedulesNotification: false,
            in: context
        )

        XCTAssertEqual(item.intervalIndex, 1)
        XCTAssertEqual(item.correctStreak, 1)
        XCTAssertEqual(item.easeFactor, 2.42, accuracy: 0.0001)
        XCTAssertEqual(item.stabilityDays, 2.42, accuracy: 0.0001)
        XCTAssertEqual(
            item.dueAt.timeIntervalSince(now),
            3 * 24 * 60 * 60,
            accuracy: 1
        )
        XCTAssertEqual(item.lastReviewedAt, now)
    }

    func testForgottenReviewResetsScheduleAndLowersEase() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext
        let now = AppTestSupport.fixedDate
        let item = AppTestSupport.makeReviewItem(
            intervalIndex: 2,
            easeFactor: 2.3,
            stabilityDays: 8
        )
        context.insert(item)

        ReviewService.review(
            item,
            remembered: false,
            now: now,
            schedulesNotification: false,
            in: context
        )

        XCTAssertEqual(item.intervalIndex, 0)
        XCTAssertEqual(item.correctStreak, 0)
        XCTAssertEqual(item.lapseCount, 1)
        XCTAssertEqual(item.easeFactor, 2.05, accuracy: 0.0001)
        XCTAssertEqual(item.stabilityDays, 3.6, accuracy: 0.0001)
        XCTAssertEqual(item.dueAt.timeIntervalSince(now), 24 * 60 * 60, accuracy: 1)
        XCTAssertFalse(item.isArchived)
    }

    func testAddRecallDeduplicatesAndImmediateReviewOverridesSchedule() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext

        ReviewService.addRecall(
            tutorialID: "tutorial-recall",
            stepIndex: 2,
            title: "回忆测试",
            question: "问题",
            referenceAnswer: "答案",
            needsReview: false,
            in: context
        )
        ReviewService.addRecall(
            tutorialID: "tutorial-recall",
            stepIndex: 2,
            title: "回忆测试",
            question: "问题",
            referenceAnswer: "答案",
            needsReview: true,
            in: context
        )

        let items = try AppTestSupport.fetch(ReviewItem.self, in: context)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.sourceID, String.tutorialStepProgressID("tutorial-recall", stepIndex: 2))
        XCTAssertEqual(items.first?.dueAt.timeIntervalSinceNow ?? 0, 0, accuracy: 2)
    }

    func testArchiveRemovesItemFromFutureReview() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext
        let item = AppTestSupport.makeReviewItem()
        context.insert(item)

        ReviewService.archive(item, in: context)

        XCTAssertTrue(item.isArchived)
        XCTAssertEqual(item.dueAt, .distantFuture)
    }
}
