import Foundation
import SwiftData

struct SyncDeletion: Codable {
    let key: String
    let deletedAt: Date
}

struct SyncDelta: Codable {
    var generatedAt: Date
    var isFullSnapshot: Bool
    var progress: [ProgressBackup]
    var bookmarks: [BookmarkBackup]
    var notes: [NoteBackup]
    var reviewItems: [ReviewBackup]
    var codeDrafts: [CodeDraftBackup]
    var masteryRecords: [MasteryBackup]
    var deletedProgress: [SyncDeletion]
    var deletedBookmarks: [SyncDeletion]
    var deletedNotes: [SyncDeletion]
    var deletedReviews: [SyncDeletion]
    var deletedDrafts: [SyncDeletion]
    var deletedMastery: [SyncDeletion]

    var isEmpty: Bool {
        progress.isEmpty
            && bookmarks.isEmpty
            && notes.isEmpty
            && reviewItems.isEmpty
            && codeDrafts.isEmpty
            && masteryRecords.isEmpty
            && deletedProgress.isEmpty
            && deletedBookmarks.isEmpty
            && deletedNotes.isEmpty
            && deletedReviews.isEmpty
            && deletedDrafts.isEmpty
            && deletedMastery.isEmpty
    }
}

enum SyncDeltaService {
    static func makeDelta(
        from current: AppBackup,
        baseline: AppBackup?
    ) -> SyncDelta {
        guard let baseline else {
            return SyncDelta(
                generatedAt: current.exportedAt,
                isFullSnapshot: true,
                progress: current.progress,
                bookmarks: current.bookmarks,
                notes: current.notes,
                reviewItems: current.reviewItems,
                codeDrafts: current.codeDrafts,
                masteryRecords: current.masteryRecords,
                deletedProgress: [],
                deletedBookmarks: [],
                deletedNotes: [],
                deletedReviews: [],
                deletedDrafts: [],
                deletedMastery: []
            )
        }

        let progress = changed(current.progress, baseline: baseline.progress, key: \.itemID)
        let bookmarks = changed(current.bookmarks, baseline: baseline.bookmarks, key: \.targetID)
        let notes = changed(current.notes, baseline: baseline.notes, key: \.targetID)
        let reviewItems = changed(current.reviewItems, baseline: baseline.reviewItems, key: \.sourceID)
        let codeDrafts = changed(current.codeDrafts, baseline: baseline.codeDrafts, key: \.exerciseID)
        let masteryRecords = changed(current.masteryRecords, baseline: baseline.masteryRecords, key: \.conceptID)

        return SyncDelta(
            generatedAt: current.exportedAt,
            isFullSnapshot: false,
            progress: progress,
            bookmarks: bookmarks,
            notes: notes,
            reviewItems: reviewItems,
            codeDrafts: codeDrafts,
            masteryRecords: masteryRecords,
            deletedProgress: deletions(current.progress, baseline: baseline.progress, key: \.itemID),
            deletedBookmarks: deletions(current.bookmarks, baseline: baseline.bookmarks, key: \.targetID),
            deletedNotes: deletions(current.notes, baseline: baseline.notes, key: \.targetID),
            deletedReviews: deletions(current.reviewItems, baseline: baseline.reviewItems, key: \.sourceID),
            deletedDrafts: deletions(current.codeDrafts, baseline: baseline.codeDrafts, key: \.exerciseID),
            deletedMastery: deletions(current.masteryRecords, baseline: baseline.masteryRecords, key: \.conceptID)
        )
    }

    @MainActor
    static func apply(_ delta: SyncDelta, into context: ModelContext) throws {
        let backup = AppBackup(
            exportedAt: delta.generatedAt,
            progress: delta.progress,
            bookmarks: delta.bookmarks,
            notes: delta.notes,
            reviewItems: delta.reviewItems,
            codeDrafts: delta.codeDrafts,
            masteryRecords: delta.masteryRecords
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try DataPortabilityService.restore(from: encoder.encode(backup), into: context)

        let progress = try context.fetch(FetchDescriptor<Progress>())
        for deletion in delta.deletedProgress {
            if let record = progress.first(where: { $0.itemID == deletion.key }),
               record.lastStudiedAt <= deletion.deletedAt {
                context.delete(record)
            }
        }

        let bookmarks = try context.fetch(FetchDescriptor<Bookmark>())
        for deletion in delta.deletedBookmarks {
            if let record = bookmarks.first(where: { $0.targetID == deletion.key }) {
                context.delete(record)
            }
        }

        let notes = try context.fetch(FetchDescriptor<LearningNote>())
        for deletion in delta.deletedNotes {
            if let record = notes.first(where: { $0.targetID == deletion.key }),
               record.updatedAt <= deletion.deletedAt {
                context.delete(record)
            }
        }

        let reviews = try context.fetch(FetchDescriptor<ReviewItem>())
        for deletion in delta.deletedReviews {
            if let record = reviews.first(where: { $0.sourceID == deletion.key }) {
                let recordDate = record.lastReviewedAt ?? record.createdAt
                if recordDate <= deletion.deletedAt {
                    context.delete(record)
                }
            }
        }

        let drafts = try context.fetch(FetchDescriptor<CodeDraft>())
        for deletion in delta.deletedDrafts {
            if let record = drafts.first(where: { $0.exerciseID == deletion.key }),
               record.updatedAt <= deletion.deletedAt {
                context.delete(record)
            }
        }

        let mastery = try context.fetch(FetchDescriptor<MasteryRecord>())
        for deletion in delta.deletedMastery {
            if let record = mastery.first(where: { $0.conceptID == deletion.key }),
               record.lastPracticedAt <= deletion.deletedAt {
                context.delete(record)
            }
        }

        try context.save()
    }

    private static func changed<Value: Encodable>(
        _ current: [Value],
        baseline: [Value],
        key: KeyPath<Value, String>
    ) -> [Value] {
        let previous = Dictionary(uniqueKeysWithValues: baseline.map { ($0[keyPath: key], $0) })
        return current.filter { value in
            guard let old = previous[value[keyPath: key]] else { return true }
            return fingerprint(old) != fingerprint(value)
        }
    }

    private static func deletions<Value: Encodable>(
        _ current: [Value],
        baseline: [Value],
        key: KeyPath<Value, String>
    ) -> [SyncDeletion] {
        let currentKeys = Set(current.map { $0[keyPath: key] })
        return baseline
            .filter { !currentKeys.contains($0[keyPath: key]) }
            .map { SyncDeletion(key: $0[keyPath: key], deletedAt: .now) }
    }

    private static func fingerprint<Value: Encodable>(_ value: Value) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return (try? encoder.encode(value)) ?? Data()
    }
}
