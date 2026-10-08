import Foundation
import SwiftData

struct WeakConcept: Identifiable {
    let concept: Concept
    let record: MasteryRecord

    var id: String { concept.id }
}

@MainActor
enum MasteryService {
    static func recordStep(
        stepIndex: Int,
        title: String,
        text: String,
        remembered: Bool,
        in context: ModelContext
    ) {
        recordText(
            "\(title) \(text)",
            positive: remembered,
            reason: remembered ? "主动回忆通过" : "主动回忆需要复习",
            in: context
        )
    }

    static func recordExercise(_ exercise: Exercise, correct: Bool, in context: ModelContext) {
        let text = [
            exercise.title,
            exercise.question,
            exercise.explanation,
            exercise.starterCode,
            exercise.topic?.title ?? ""
        ].joined(separator: " ")
        recordText(
            text,
            positive: correct,
            reason: correct ? "练习回答正确" : "练习回答错误",
            in: context
        )
    }

    static func recordCodeResult(_ exercise: Exercise, passed: Bool, in context: ModelContext) {
        let text = [
            exercise.title,
            exercise.question,
            exercise.explanation,
            exercise.topic?.title ?? ""
        ].joined(separator: " ")
        recordText(
            text,
            positive: passed,
            reason: passed ? "代码通过测试" : "代码未通过测试",
            in: context
        )
    }

    static func recordReviewItem(_ item: ReviewItem, remembered: Bool, in context: ModelContext) {
        recordText(
            "\(item.title) \(item.question) \(item.referenceAnswer)",
            positive: remembered,
            reason: remembered ? "间隔复习通过" : "间隔复习未通过",
            in: context
        )
    }

    static func recordConceptPractice(
        conceptID: String,
        positive: Bool,
        reason: String,
        in context: ModelContext
    ) {
        let record = record(for: conceptID, in: context) ?? {
            let newRecord = MasteryRecord(conceptID: conceptID)
            context.insert(newRecord)
            return newRecord
        }()

        let delta = positive ? 0.12 : -0.18
        record.score = min(1, max(0, record.score + delta))
        record.attempts += 1
        if positive {
            record.correctCount += 1
        } else {
            record.wrongCount += 1
        }
        record.lastReason = reason
        record.lastPracticedAt = .now
        try? context.save()
    }

    static func recordText(
        _ text: String,
        positive: Bool,
        reason: String,
        in context: ModelContext
    ) {
        let concepts = (try? context.fetch(FetchDescriptor<Concept>())) ?? []
        let searchable = text.lowercased()
        let matches = concepts.filter { concept in
            ([concept.name] + concept.aliases).contains { name in
                !name.isEmpty && searchable.contains(name.lowercased())
            }
        }

        guard !matches.isEmpty else { return }

        for concept in matches {
            let record = record(for: concept.id, in: context) ?? {
                let newRecord = MasteryRecord(conceptID: concept.id)
                context.insert(newRecord)
                return newRecord
            }()

            let delta = positive ? 0.12 : -0.18
            record.score = min(1, max(0, record.score + delta))
            record.attempts += 1
            if positive {
                record.correctCount += 1
            } else {
                record.wrongCount += 1
            }
            record.lastReason = reason
            record.lastPracticedAt = .now
        }

        try? context.save()
    }

    static func record(for conceptID: String, in context: ModelContext) -> MasteryRecord? {
        let descriptor = FetchDescriptor<MasteryRecord>(
            predicate: #Predicate<MasteryRecord> { record in
                record.conceptID == conceptID
            }
        )
        return try? context.fetch(descriptor).first
    }

    static func weakConcepts(
        concepts: [Concept],
        records: [MasteryRecord],
        limit: Int = 5
    ) -> [WeakConcept] {
        records
            .filter { $0.attempts > 0 && $0.score < 0.72 }
            .compactMap { record in
                concepts.first { $0.id == record.conceptID }.map {
                    WeakConcept(concept: $0, record: record)
                }
            }
            .sorted { $0.record.score < $1.record.score }
            .prefix(limit)
            .map { $0 }
    }

    static func averageMastery(records: [MasteryRecord], conceptIDs: [String]? = nil) -> Double {
        let filtered = records.filter { record in
            conceptIDs.map { $0.contains(record.conceptID) } ?? true
        }
        guard !filtered.isEmpty else { return 0 }
        return filtered.reduce(0) { $0 + $1.score } / Double(filtered.count)
    }

    static func masteryLabel(_ score: Double) -> String {
        switch score {
        case 0.85...: "熟练"
        case 0.65..<0.85: "理解"
        case 0.4..<0.65: "学习中"
        default: "待加强"
        }
    }
}
