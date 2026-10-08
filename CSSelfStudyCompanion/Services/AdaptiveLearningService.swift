import Foundation

enum AdaptiveReadinessLevel: String {
    case completed
    case ready
    case nearlyReady
    case needsBridge

    var title: String {
        switch self {
        case .completed: "已完成"
        case .ready: "可开始"
        case .nearlyReady: "建议复习"
        case .needsBridge: "需要补桥"
        }
    }

    var icon: String {
        switch self {
        case .completed: "checkmark.circle.fill"
        case .ready: "play.circle.fill"
        case .nearlyReady: "exclamationmark.circle.fill"
        case .needsBridge: "arrow.triangle.branch"
        }
    }
}

enum AdaptiveConceptEvidence: String {
    case mastery
    case completedTutorial
    case partialTutorial
    case unverified

    var title: String {
        switch self {
        case .mastery: "练习与复习记录"
        case .completedTutorial: "相关教程已完成"
        case .partialTutorial: "相关教程部分完成"
        case .unverified: "缺少掌握数据"
        }
    }
}

struct AdaptiveConceptReadiness: Identifiable {
    let concept: Concept
    let score: Double
    let evidence: AdaptiveConceptEvidence

    var id: String { concept.id }
    var isMastered: Bool { score >= AdaptiveLearningService.readyThreshold }
}

struct AdaptiveTutorialReadiness: Identifiable {
    let tutorial: Tutorial
    let score: Double
    let level: AdaptiveReadinessLevel
    let prerequisiteConcepts: [AdaptiveConceptReadiness]
    let remediationTutorials: [Tutorial]
    let reason: String

    var id: String { tutorial.id }

    var missingConcepts: [AdaptiveConceptReadiness] {
        prerequisiteConcepts.filter { $0.score < AdaptiveLearningService.readyThreshold }
    }

    var recommendedTutorial: Tutorial {
        remediationTutorials.first ?? tutorial
    }
}

struct AdaptiveLearningSnapshot {
    let items: [AdaptiveTutorialReadiness]
    let completedCount: Int
    let readyCount: Int
    let bridgeCount: Int
    let overallReadiness: Double
    let nextItem: AdaptiveTutorialReadiness?

    var incompleteItems: [AdaptiveTutorialReadiness] {
        items.filter { $0.level != .completed }
    }

    var readyItems: [AdaptiveTutorialReadiness] {
        items.filter { $0.level == .ready }
    }

    var bridgeItems: [AdaptiveTutorialReadiness] {
        items.filter { $0.level == .nearlyReady || $0.level == .needsBridge }
    }
}

enum AdaptiveLearningService {
    static let readyThreshold = 0.72
    static let bridgeThreshold = 0.55

    static func snapshot(
        tutorials: [Tutorial],
        concepts: [Concept],
        masteryRecords: [MasteryRecord],
        progressRecords: [Progress]
    ) -> AdaptiveLearningSnapshot {
        let orderedTutorials = tutorials.sorted(by: tutorialOrder)
        let tutorialMap = Dictionary(uniqueKeysWithValues: orderedTutorials.map { ($0.id, $0) })
        let masteryMap = Dictionary(uniqueKeysWithValues: masteryRecords.map { ($0.conceptID, $0) })
        let completedTutorialIDs = Set(
            orderedTutorials
                .filter { tutorial in
                    progressRecords.contains {
                        $0.itemID == .tutorialProgressID(tutorial.id) && $0.isCompleted
                    }
                }
                .map(\.id)
        )

        let items = orderedTutorials.map { tutorial in
            readiness(
                for: tutorial,
                concepts: concepts,
                tutorialMap: tutorialMap,
                masteryMap: masteryMap,
                completedTutorialIDs: completedTutorialIDs
            )
        }

        let completedCount = items.filter { $0.level == .completed }.count
        let readyCount = items.filter { $0.level == .ready }.count
        let bridgeCount = items.filter { $0.level == .nearlyReady || $0.level == .needsBridge }.count
        let overall = items.isEmpty
            ? 0
            : items.reduce(0) { partial, item in
                partial + (item.level == .completed ? 1 : item.score)
            } / Double(items.count)

        return AdaptiveLearningSnapshot(
            items: items,
            completedCount: completedCount,
            readyCount: readyCount,
            bridgeCount: bridgeCount,
            overallReadiness: overall,
            nextItem: items.first { $0.level != .completed }
        )
    }

    static func readiness(
        for tutorial: Tutorial,
        concepts: [Concept],
        tutorialMap: [String: Tutorial],
        masteryMap: [String: MasteryRecord],
        completedTutorialIDs: Set<String>
    ) -> AdaptiveTutorialReadiness {
        let isCompleted = completedTutorialIDs.contains(tutorial.id)
        let relatedConcepts = concepts.filter { $0.relatedTutorialIDs.contains(tutorial.id) }
        let prerequisiteIDs = Set(
            relatedConcepts.flatMap { ConceptDependencyCatalog.prerequisites(for: $0.id) }
        )

        let prerequisites = prerequisiteIDs.compactMap { conceptID -> AdaptiveConceptReadiness? in
            guard let concept = concepts.first(where: { $0.id == conceptID }) else { return nil }
            let result = conceptReadiness(
                concept: concept,
                tutorialMap: tutorialMap,
                mastery: masteryMap[conceptID],
                completedTutorialIDs: completedTutorialIDs
            )
            return AdaptiveConceptReadiness(
                concept: concept,
                score: result.score,
                evidence: result.evidence
            )
        }
        .sorted { $0.score < $1.score }

        let rawScore: Double
        if prerequisites.isEmpty {
            rawScore = 1
        } else {
            rawScore = prerequisites.reduce(0) { $0 + $1.score } / Double(prerequisites.count)
        }

        let level: AdaptiveReadinessLevel
        if isCompleted {
            level = .completed
        } else if rawScore >= readyThreshold {
            level = .ready
        } else if rawScore >= bridgeThreshold {
            level = .nearlyReady
        } else {
            level = .needsBridge
        }

        let missing = prerequisites.filter { $0.score < readyThreshold }
        let remediation = remediationTutorials(
            for: missing,
            tutorialMap: tutorialMap,
            completedTutorialIDs: completedTutorialIDs
        )

        let reason: String
        if isCompleted {
            reason = "教程已完成，可以继续巩固练习或进入下一项。"
        } else if prerequisites.isEmpty {
            reason = "当前教程没有已知前置概念，可以开始学习。"
        } else if level == .ready {
            reason = "前置概念已达到 \(Int(rawScore * 100))%，可以进入本教程。"
        } else if let first = missing.first {
            reason = "建议先补强“\(first.concept.name)”，当前估计 \(Int(first.score * 100))%。"
        } else {
            reason = "接近可以开始，建议先完成一次快速复习。"
        }

        return AdaptiveTutorialReadiness(
            tutorial: tutorial,
            score: min(1, max(0, rawScore)),
            level: level,
            prerequisiteConcepts: prerequisites,
            remediationTutorials: remediation,
            reason: reason
        )
    }

    static func inferredConceptScore(
        _ concept: Concept,
        mastery: MasteryRecord?,
        tutorialMap: [String: Tutorial],
        completedTutorialIDs: Set<String>
    ) -> Double {
        conceptReadiness(
            concept: concept,
            tutorialMap: tutorialMap,
            mastery: mastery,
            completedTutorialIDs: completedTutorialIDs
        ).score
    }

    static func tutorialOrder(_ lhs: Tutorial, _ rhs: Tutorial) -> Bool {
        let lhsKey = orderKey(lhs)
        let rhsKey = orderKey(rhs)
        if lhsKey.stage != rhsKey.stage { return lhsKey.stage < rhsKey.stage }
        if lhsKey.topic != rhsKey.topic { return lhsKey.topic < rhsKey.topic }
        if lhsKey.tutorial != rhsKey.tutorial { return lhsKey.tutorial < rhsKey.tutorial }
        return lhs.id < rhs.id
    }

    private static func conceptReadiness(
        concept: Concept,
        tutorialMap: [String: Tutorial],
        mastery: MasteryRecord?,
        completedTutorialIDs: Set<String>
    ) -> (score: Double, evidence: AdaptiveConceptEvidence) {
        if let mastery, mastery.attempts > 0 {
            return (min(1, max(0, mastery.score)), .mastery)
        }

        let related = concept.relatedTutorialIDs
            .compactMap { tutorialMap[$0] }
            .sorted(by: tutorialOrder)
        guard !related.isEmpty else {
            return (0.5, .unverified)
        }

        let completed = related.filter { completedTutorialIDs.contains($0.id) }.count
        let ratio = Double(completed) / Double(related.count)
        if completed == related.count {
            return (0.85, .completedTutorial)
        }
        if completed == 0 {
            return (0.3, .partialTutorial)
        }
        return (0.3 + ratio * 0.55, .partialTutorial)
    }

    private static func remediationTutorials(
        for concepts: [AdaptiveConceptReadiness],
        tutorialMap: [String: Tutorial],
        completedTutorialIDs: Set<String>
    ) -> [Tutorial] {
        let tutorialIDs = Set(concepts.flatMap { $0.concept.relatedTutorialIDs })
        return tutorialIDs
            .compactMap { tutorialMap[$0] }
            .filter { !completedTutorialIDs.contains($0.id) }
            .sorted(by: tutorialOrder)
    }

    private static func orderKey(_ tutorial: Tutorial) -> (stage: Int, topic: Int, tutorial: Int) {
        (
            tutorial.topic?.stage?.order ?? Int.max,
            tutorial.topic?.order ?? Int.max,
            tutorial.order
        )
    }
}
