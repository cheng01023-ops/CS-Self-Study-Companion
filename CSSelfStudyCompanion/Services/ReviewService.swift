import Foundation
import SwiftData
import UserNotifications

@MainActor
enum ReviewService {
    static let intervals = [1, 3, 7, 30]

    static func dueItems(from items: [ReviewItem], now: Date = .now) -> [ReviewItem] {
        items
            .filter { !$0.isArchived && $0.dueAt <= now }
            .sorted { $0.dueAt < $1.dueAt }
    }

    static func upcomingItems(from items: [ReviewItem], now: Date = .now) -> [ReviewItem] {
        items
            .filter { !$0.isArchived && $0.dueAt > now }
            .sorted { $0.dueAt < $1.dueAt }
    }

    static func addRecall(
        tutorialID: String,
        stepIndex: Int,
        title: String,
        question: String,
        referenceAnswer: String,
        needsReview: Bool,
        in context: ModelContext
    ) {
        let sourceID = String.tutorialStepProgressID(tutorialID, stepIndex: stepIndex)
        let existing = item(forSourceID: sourceID, in: context)
        if let existing {
            existing.parentTutorialID = tutorialID
            existing.stepIndex = stepIndex
            if existing.isArchived {
                resetSchedule(existing, dueImmediately: needsReview)
            } else {
                existing.isArchived = false
                if needsReview {
                    resetSchedule(existing, dueImmediately: true)
                }
            }
        } else {
            let dueAt = needsReview ? Date.now : dateAdding(days: intervals[0])
            context.insert(
                ReviewItem(
                    id: "review:\(sourceID)",
                    sourceType: "recall",
                    sourceID: sourceID,
                    title: title,
                    question: question,
                    referenceAnswer: referenceAnswer,
                    explanation: "尝试不看正文复述核心概念，再用相关教程和实验验证。",
                    parentTutorialID: tutorialID,
                    stepIndex: stepIndex,
                    dueAt: dueAt
                )
            )
        }
        try? context.save()
    }

    static func addLabFailure(
        tutorialID: String,
        title: String,
        question: String,
        referenceAnswer: String,
        in context: ModelContext
    ) {
        let sourceID = "lab:\(tutorialID):review"
        if let existing = item(forSourceID: sourceID, in: context) {
            existing.title = title
            existing.question = question
            existing.referenceAnswer = referenceAnswer
            existing.isArchived = false
            resetSchedule(existing, dueImmediately: true)
        } else {
            context.insert(
                ReviewItem(
                    id: "review:\(sourceID)",
                    sourceType: "lab",
                    sourceID: sourceID,
                    title: title,
                    question: question,
                    referenceAnswer: referenceAnswer,
                    explanation: "实验未通过时进入复习。先重新复现最小错误，再用输出、退出码或系统状态证明修复。",
                    parentTutorialID: tutorialID,
                    dueAt: .now
                )
            )
        }
        try? context.save()
    }

    static func addOpenSourceReading(
        missionID: String,
        title: String,
        question: String,
        referenceAnswer: String,
        in context: ModelContext
    ) {
        let sourceID = "open-source:\(missionID):review"
        if let existing = item(forSourceID: sourceID, in: context) {
            existing.title = title
            existing.question = question
            existing.referenceAnswer = referenceAnswer
            existing.isArchived = false
            resetSchedule(existing, dueImmediately: true)
        } else {
            context.insert(
                ReviewItem(
                    id: "review:\(sourceID)",
                    sourceType: "open-source",
                    sourceID: sourceID,
                    title: title,
                    question: question,
                    referenceAnswer: referenceAnswer,
                    explanation: "重新回到真实仓库，先画调用链，再用源码位置和运行证据回答。不要只记结论。",
                    dueAt: .now
                )
            )
        }
        try? context.save()
    }

    static func recordWrongExercise(exercise: Exercise, userAnswer: String, in context: ModelContext) {
        let sourceID = String.exerciseProgressID(exercise.id)
        if let existing = item(forSourceID: sourceID, in: context) {
            existing.userAnswer = userAnswer
            existing.isArchived = false
            resetSchedule(existing, dueImmediately: true)
        } else {
            context.insert(
                ReviewItem(
                    id: "review:\(sourceID)",
                    sourceType: "exercise",
                    sourceID: sourceID,
                    title: exercise.title,
                    question: exercise.question,
                    referenceAnswer: exercise.answer,
                    explanation: exercise.explanation,
                    userAnswer: userAnswer,
                    parentTutorialID: exercise.topic?.tutorials.first?.id,
                    dueAt: Date.now
                )
            )
        }
        try? context.save()
    }

    static func addCodingExercise(exercise: Exercise, in context: ModelContext) {
        let sourceID = String.exerciseProgressID(exercise.id)
        guard item(forSourceID: sourceID, in: context) == nil else { return }
        context.insert(
            ReviewItem(
                id: "review:\(sourceID)",
                sourceType: "coding",
                sourceID: sourceID,
                title: exercise.title,
                question: exercise.question,
                referenceAnswer: exercise.answer,
                explanation: exercise.explanation,
                parentTutorialID: exercise.topic?.tutorials.first?.id,
                dueAt: Date.now
            )
        )
        try? context.save()
    }

    static func review(
        _ item: ReviewItem,
        remembered: Bool,
        responseSeconds: Double = 0,
        now: Date = .now,
        schedulesNotification: Bool = true,
        in context: ModelContext
    ) {
        item.lastReviewedAt = now
        item.lastResponseSeconds = responseSeconds

        if remembered {
            item.correctStreak += 1
            let speedBonus = responseSeconds <= 8 ? 0.12 : responseSeconds <= 20 ? 0.05 : -0.05
            item.easeFactor = min(3.0, max(1.3, item.easeFactor + speedBonus))
            item.stabilityDays = min(180, max(1, item.stabilityDays * item.easeFactor))

            let nextIndex = item.intervalIndex + 1
            if nextIndex >= intervals.count {
                item.intervalIndex = intervals.count
                item.isArchived = true
                item.dueAt = .distantFuture
            } else {
                item.intervalIndex = nextIndex
                let scheduledDays = max(intervals[nextIndex], Int(item.stabilityDays.rounded()))
                item.dueAt = dateAdding(days: min(180, scheduledDays), from: now)
            }
        } else {
            item.lapseCount += 1
            item.easeFactor = max(1.3, item.easeFactor - 0.25)
            item.stabilityDays = max(1, item.stabilityDays * 0.45)
            resetSchedule(item, dueImmediately: false, now: now)
        }

        if schedulesNotification {
            scheduleNotification(for: item)
        }
        try? context.save()
    }

    static func archive(_ item: ReviewItem, in context: ModelContext) {
        item.isArchived = true
        item.dueAt = .distantFuture
        try? context.save()
    }

    static func scheduleNotification(for item: ReviewItem) {
        guard !item.isArchived, item.dueAt > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = "该复习了"
        content.body = item.title
        content.sound = .default

        let interval = max(60, item.dueAt.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "review-\(item.id)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func item(forSourceID sourceID: String, in context: ModelContext) -> ReviewItem? {
        let descriptor = FetchDescriptor<ReviewItem>(
            predicate: #Predicate<ReviewItem> { item in
                item.sourceID == sourceID && item.isArchived == false
            }
        )
        return try? context.fetch(descriptor).first
    }

    static func stageDescription(_ item: ReviewItem) -> String {
        if item.isArchived { return "已完成 30 天复习" }
        if item.lapseCount >= 4 { return "重点卡点" }
        guard intervals.indices.contains(item.intervalIndex) else { return "长期复习" }
        return "\(intervals[item.intervalIndex]) 天复习"
    }

    static func nextReviewText(_ item: ReviewItem, now: Date = .now) -> String {
        if item.isArchived { return "已完成" }
        if item.dueAt <= now { return "现在复习" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        return formatter.localizedString(for: item.dueAt, relativeTo: now)
    }

    private static func resetSchedule(
        _ item: ReviewItem,
        dueImmediately: Bool,
        now: Date = .now
    ) {
        item.intervalIndex = 0
        item.correctStreak = 0
        item.isArchived = false
        item.dueAt = dueImmediately ? now : dateAdding(days: intervals[0], from: now)
    }

    private static func dateAdding(days: Int, from date: Date = .now) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }
}
