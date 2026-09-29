import Foundation
import SwiftData

@MainActor
enum CodeDraftService {
    static func draft(for exerciseID: String, in context: ModelContext) -> CodeDraft? {
        let descriptor = FetchDescriptor<CodeDraft>(
            predicate: #Predicate<CodeDraft> { draft in
                draft.exerciseID == exerciseID
            }
        )
        return try? context.fetch(descriptor).first
    }

    static func save(
        exerciseID: String,
        sourceCode: String,
        input: String,
        output: String,
        error: String,
        passed: Bool,
        in context: ModelContext
    ) {
        let draft = draft(for: exerciseID, in: context) ?? {
            let newDraft = CodeDraft(exerciseID: exerciseID, sourceCode: sourceCode)
            context.insert(newDraft)
            return newDraft
        }()

        draft.sourceCode = sourceCode
        draft.input = input
        draft.lastOutput = output
        draft.lastError = error
        draft.passed = passed
        draft.updatedAt = .now
        draft.lastRunAt = output.isEmpty && error.isEmpty ? draft.lastRunAt : .now
        try? context.save()
    }
}
