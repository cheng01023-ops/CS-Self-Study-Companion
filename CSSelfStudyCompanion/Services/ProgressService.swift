import Foundation
import SwiftData

@MainActor
enum ProgressService {
    static func isCompleted(_ itemID: String, in context: ModelContext) -> Bool {
        record(for: itemID, in: context)?.isCompleted ?? false
    }

    static func setCompleted(
        _ completed: Bool,
        itemID: String,
        score: Double? = nil,
        in context: ModelContext
    ) {
        let record = record(for: itemID, in: context) ?? {
            let newRecord = Progress(itemID: itemID)
            context.insert(newRecord)
            return newRecord
        }()

        record.isCompleted = completed
        record.score = score
        record.lastStudiedAt = .now
        record.completedAt = completed ? .now : nil
        try? context.save()
    }

    static func savePosition(tutorialID: String, stepIndex: Int, in context: ModelContext) {
        let itemID = String.tutorialLastStepID(tutorialID)
        let record = record(for: itemID, in: context) ?? {
            let newRecord = Progress(itemID: itemID)
            context.insert(newRecord)
            return newRecord
        }()

        record.score = Double(stepIndex)
        record.lastStudiedAt = .now
        try? context.save()
    }

    static func savedPosition(tutorialID: String, in context: ModelContext) -> Int? {
        record(for: .tutorialLastStepID(tutorialID), in: context)
            .flatMap(\.score)
            .map { Int($0) }
    }

    static func markStudied(itemID: String, in context: ModelContext) {
        let record = record(for: itemID, in: context) ?? {
            let newRecord = Progress(itemID: itemID)
            context.insert(newRecord)
            return newRecord
        }()

        record.lastStudiedAt = .now
        try? context.save()
    }

    static func resetAll(in context: ModelContext) {
        let descriptor = FetchDescriptor<Progress>()
        guard let records = try? context.fetch(descriptor) else { return }
        records.forEach(context.delete)
        try? context.save()
    }

    private static func record(for itemID: String, in context: ModelContext) -> Progress? {
        let descriptor = FetchDescriptor<Progress>(
            predicate: #Predicate<Progress> { progress in
                progress.itemID == itemID
            }
        )
        return try? context.fetch(descriptor).first
    }
}

extension String {
    static func tutorialProgressID(_ tutorialID: String) -> String {
        "tutorial:\(tutorialID)"
    }

    static func exerciseProgressID(_ exerciseID: String) -> String {
        "exercise:\(exerciseID)"
    }

    static func tutorialStepProgressID(_ tutorialID: String, stepIndex: Int) -> String {
        "tutorial:\(tutorialID):step:\(stepIndex)"
    }

    static func tutorialLastStepID(_ tutorialID: String) -> String {
        "tutorial:\(tutorialID):last-step"
    }

    static func resourceProgressID(_ resourceID: String) -> String {
        "resource:\(resourceID)"
    }

    static func resourceLaterProgressID(_ resourceID: String) -> String {
        "resource:\(resourceID):later"
    }

    static func resourceBookmarkTargetID(_ resourceID: String) -> String {
        "resource:\(resourceID):bookmark"
    }

    static func resourceNoteTargetID(_ resourceID: String) -> String {
        "resource:\(resourceID):note"
    }

    static func tutorialLabStageProgressID(_ tutorialID: String, stage: Int) -> String {
        TutorialLabCatalog.stageProgressID(tutorialID, stage: stage)
    }

    static func tutorialLabCheckpointProgressID(_ tutorialID: String, checkpointID: String) -> String {
        TutorialLabCatalog.checkpointProgressID(tutorialID, checkpointID: checkpointID)
    }
}
