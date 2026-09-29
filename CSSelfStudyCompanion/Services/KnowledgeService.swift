import Foundation
import SwiftData

@MainActor
enum KnowledgeService {
    static func toggleBookmark(
        targetID: String,
        targetType: String,
        parentTutorialID: String?,
        stepIndex: Int?,
        title: String,
        subtitle: String,
        in context: ModelContext
    ) {
        if let existing = bookmark(for: targetID, in: context) {
            context.delete(existing)
        } else {
            context.insert(
                Bookmark(
                    id: "bookmark:\(targetID)",
                    targetID: targetID,
                    targetType: targetType,
                    parentTutorialID: parentTutorialID,
                    stepIndex: stepIndex,
                    title: title,
                    subtitle: subtitle
                )
            )
        }
        try? context.save()
    }

    static func bookmark(for targetID: String, in context: ModelContext) -> Bookmark? {
        let descriptor = FetchDescriptor<Bookmark>(
            predicate: #Predicate<Bookmark> { bookmark in
                bookmark.targetID == targetID
            }
        )
        return try? context.fetch(descriptor).first
    }

    static func saveNote(
        targetID: String,
        parentTutorialID: String?,
        stepIndex: Int?,
        title: String,
        body: String,
        in context: ModelContext
    ) {
        let note = note(for: targetID, in: context) ?? {
            let newNote = LearningNote(
                id: "note:\(targetID)",
                targetID: targetID,
                parentTutorialID: parentTutorialID,
                stepIndex: stepIndex,
                title: title
            )
            context.insert(newNote)
            return newNote
        }()

        note.parentTutorialID = parentTutorialID
        note.stepIndex = stepIndex
        note.title = title
        note.body = body
        note.updatedAt = .now
        try? context.save()
    }

    static func note(for targetID: String, in context: ModelContext) -> LearningNote? {
        let descriptor = FetchDescriptor<LearningNote>(
            predicate: #Predicate<LearningNote> { note in
                note.targetID == targetID
            }
        )
        return try? context.fetch(descriptor).first
    }

    static func deleteNote(_ note: LearningNote, in context: ModelContext) {
        context.delete(note)
        try? context.save()
    }
}
