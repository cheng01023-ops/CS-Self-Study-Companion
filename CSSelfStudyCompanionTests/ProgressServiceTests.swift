import SwiftData
import XCTest
@testable import CSSelfStudyCompanion

@MainActor
final class ProgressServiceTests: XCTestCase {
    func testSetCompletedCreatesUpdatesAndClearsRecord() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext
        let itemID = String.tutorialProgressID("tutorial-test")

        ProgressService.setCompleted(true, itemID: itemID, score: 0.9, in: context)
        var records = try AppTestSupport.fetch(Progress.self, in: context)

        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.itemID, itemID)
        XCTAssertEqual(records.first?.isCompleted, true)
        XCTAssertEqual(records.first?.score, 0.9)
        XCTAssertNotNil(records.first?.completedAt)

        ProgressService.setCompleted(false, itemID: itemID, in: context)
        records = try AppTestSupport.fetch(Progress.self, in: context)

        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.isCompleted, false)
        XCTAssertNil(records.first?.completedAt)
    }

    func testSavedPositionRoundTrips() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext

        XCTAssertNil(ProgressService.savedPosition(tutorialID: "tutorial-position", in: context))
        ProgressService.savePosition(tutorialID: "tutorial-position", stepIndex: 7, in: context)
        XCTAssertEqual(ProgressService.savedPosition(tutorialID: "tutorial-position", in: context), 7)

        let records = try AppTestSupport.fetch(Progress.self, in: context)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.score, 7)
    }

    func testMarkStudiedDoesNotMarkItemCompleted() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext
        let itemID = "exercise:test"

        ProgressService.markStudied(itemID: itemID, in: context)
        XCTAssertFalse(ProgressService.isCompleted(itemID, in: context))

        let records = try AppTestSupport.fetch(Progress.self, in: context)
        XCTAssertEqual(records.first?.lastStudiedAt.timeIntervalSince1970 ?? 0,
                       Date.now.timeIntervalSince1970,
                       accuracy: 2)
    }

    func testResetAllRemovesEveryProgressRecord() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext

        ProgressService.setCompleted(true, itemID: "one", in: context)
        ProgressService.setCompleted(true, itemID: "two", in: context)
        XCTAssertEqual(try AppTestSupport.fetch(Progress.self, in: context).count, 2)

        ProgressService.resetAll(in: context)
        XCTAssertTrue(try AppTestSupport.fetch(Progress.self, in: context).isEmpty)
    }
}
