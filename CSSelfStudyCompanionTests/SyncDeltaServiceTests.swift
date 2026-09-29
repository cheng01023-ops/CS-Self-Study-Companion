import SwiftData
import XCTest
@testable import CSSelfStudyCompanion

@MainActor
final class SyncDeltaServiceTests: XCTestCase {
    private let oldDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let newDate = Date(timeIntervalSince1970: 1_700_003_600)

    func testFirstSyncIsFullSnapshot() {
        let backup = makeBackup(
            progress: [
                ProgressBackup(
                    itemID: "tutorial:one",
                    isCompleted: true,
                    score: 1,
                    lastStudiedAt: oldDate,
                    completedAt: oldDate
                )
            ]
        )

        let delta = SyncDeltaService.makeDelta(from: backup, baseline: nil)

        XCTAssertTrue(delta.isFullSnapshot)
        XCTAssertEqual(delta.progress.count, 1)
        XCTAssertEqual(delta.deletedProgress.count, 0)
    }

    func testDeltaContainsChangedAndDeletedRecords() {
        let baseline = makeBackup(
            progress: [
                ProgressBackup(
                    itemID: "one",
                    isCompleted: false,
                    score: 0,
                    lastStudiedAt: oldDate,
                    completedAt: nil
                ),
                ProgressBackup(
                    itemID: "deleted",
                    isCompleted: true,
                    score: 1,
                    lastStudiedAt: oldDate,
                    completedAt: oldDate
                )
            ],
            notes: [
                NoteBackup(
                    id: "note:same",
                    targetID: "same",
                    title: "同一条",
                    body: "旧内容",
                    createdAt: oldDate,
                    updatedAt: oldDate
                )
            ]
        )
        let current = makeBackup(
            progress: [
                ProgressBackup(
                    itemID: "one",
                    isCompleted: true,
                    score: 1,
                    lastStudiedAt: newDate,
                    completedAt: newDate
                )
            ],
            notes: [
                NoteBackup(
                    id: "note:same",
                    targetID: "same",
                    title: "同一条",
                    body: "新内容",
                    createdAt: oldDate,
                    updatedAt: newDate
                )
            ]
        )

        let delta = SyncDeltaService.makeDelta(from: current, baseline: baseline)

        XCTAssertFalse(delta.isFullSnapshot)
        XCTAssertEqual(delta.progress.map(\.itemID), ["one"])
        XCTAssertEqual(delta.notes.map(\.targetID), ["same"])
        XCTAssertEqual(delta.deletedProgress.map(\.key), ["deleted"])
        XCTAssertTrue(delta.deletedNotes.isEmpty)
    }

    func testApplyDeltaMergesChangesAndDeletesStaleBookmark() throws {
        let container = try AppTestSupport.makeContainer()
        let context = container.mainContext

        context.insert(
            Bookmark(
                id: "bookmark:one",
                targetID: "target:one",
                targetType: "tutorialStep",
                title: "旧收藏",
                subtitle: "旧",
                createdAt: oldDate
            )
        )
        context.insert(
            LearningNote(
                id: "note:one",
                targetID: "target:one",
                title: "旧笔记",
                body: "旧内容",
                createdAt: oldDate,
                updatedAt: oldDate
            )
        )
        try context.save()

        let delta = SyncDelta(
            generatedAt: newDate,
            isFullSnapshot: false,
            progress: [],
            bookmarks: [],
            notes: [
                NoteBackup(
                    id: "note:one",
                    targetID: "target:one",
                    title: "新笔记",
                    body: "新内容",
                    createdAt: oldDate,
                    updatedAt: newDate
                )
            ],
            reviewItems: [],
            codeDrafts: [],
            masteryRecords: [],
            deletedProgress: [],
            deletedBookmarks: [SyncDeletion(key: "target:one", deletedAt: newDate)],
            deletedNotes: [],
            deletedReviews: [],
            deletedDrafts: [],
            deletedMastery: []
        )

        try SyncDeltaService.apply(delta, into: context)

        XCTAssertTrue(try AppTestSupport.fetch(Bookmark.self, in: context).isEmpty)
        let notes = try AppTestSupport.fetch(LearningNote.self, in: context)
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.body, "新内容")
    }

    private func makeBackup(
        progress: [ProgressBackup] = [],
        bookmarks: [BookmarkBackup] = [],
        notes: [NoteBackup] = [],
        reviewItems: [ReviewBackup] = [],
        codeDrafts: [CodeDraftBackup] = [],
        masteryRecords: [MasteryBackup] = []
    ) -> AppBackup {
        AppBackup(
            exportedAt: newDate,
            progress: progress,
            bookmarks: bookmarks,
            notes: notes,
            reviewItems: reviewItems,
            codeDrafts: codeDrafts,
            masteryRecords: masteryRecords
        )
    }
}
