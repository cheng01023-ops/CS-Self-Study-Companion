import Foundation
import SwiftData

@Model
final class Stage {
    @Attribute(.unique) var id: String
    var order: Int
    var title: String
    var subtitle: String
    var icon: String
    var themeHex: String

    @Relationship(deleteRule: .cascade, inverse: \Topic.stage)
    var topics: [Topic] = []

    init(
        id: String,
        order: Int,
        title: String,
        subtitle: String,
        icon: String,
        themeHex: String
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.themeHex = themeHex
    }
}

@Model
final class Topic {
    @Attribute(.unique) var id: String
    var order: Int
    var title: String
    var summary: String
    var estimatedMinutes: Int

    var stage: Stage?

    @Relationship(deleteRule: .cascade, inverse: \Tutorial.topic)
    var tutorials: [Tutorial] = []

    @Relationship(deleteRule: .cascade, inverse: \Exercise.topic)
    var exercises: [Exercise] = []

    init(
        id: String,
        order: Int,
        title: String,
        summary: String,
        estimatedMinutes: Int
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.summary = summary
        self.estimatedMinutes = estimatedMinutes
    }
}

@Model
final class Tutorial {
    @Attribute(.unique) var id: String
    var order: Int
    var title: String
    var summary: String
    var markdown: String
    var codeLanguage: String
    var code: String
    var secondCodeLanguage: String
    var secondCode: String
    var commonMistakes: String

    @Relationship(deleteRule: .cascade, inverse: \LearningResource.tutorial)
    var resources: [LearningResource] = []

    var topic: Topic?

    init(
        id: String,
        order: Int,
        title: String,
        summary: String,
        markdown: String,
        codeLanguage: String = "c",
        code: String = "",
        secondCodeLanguage: String = "",
        secondCode: String = "",
        commonMistakes: String = ""
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.summary = summary
        self.markdown = markdown
        self.codeLanguage = codeLanguage
        self.code = code
        self.secondCodeLanguage = secondCodeLanguage
        self.secondCode = secondCode
        self.commonMistakes = commonMistakes
    }
}

@Model
final class Exercise {
    @Attribute(.unique) var id: String
    var order: Int
    var title: String
    var kindRawValue: String
    var question: String
    var options: [String]
    var answer: String
    var explanation: String
    var starterCode: String
    var codeLanguage: String

    var topic: Topic?

    var kind: ExerciseKind {
        ExerciseKind(rawValue: kindRawValue) ?? .multipleChoice
    }

    init(
        id: String,
        order: Int,
        title: String,
        kind: ExerciseKind,
        question: String,
        options: [String] = [],
        answer: String,
        explanation: String,
        starterCode: String = "",
        codeLanguage: String = "c"
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.kindRawValue = kind.rawValue
        self.question = question
        self.options = options
        self.answer = answer
        self.explanation = explanation
        self.starterCode = starterCode
        self.codeLanguage = codeLanguage
    }
}

enum ExerciseKind: String, Codable {
    case multipleChoice
    case coding

    var title: String {
        switch self {
        case .multipleChoice: "选择题"
        case .coding: "编程题"
        }
    }
}

@Model
final class Progress {
    @Attribute(.unique) var itemID: String
    var isCompleted: Bool
    var score: Double?
    var lastStudiedAt: Date
    var completedAt: Date?

    init(
        itemID: String,
        isCompleted: Bool = false,
        score: Double? = nil,
        lastStudiedAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.itemID = itemID
        self.isCompleted = isCompleted
        self.score = score
        self.lastStudiedAt = lastStudiedAt
        self.completedAt = completedAt
    }
}

@Model
final class Command {
    @Attribute(.unique) var id: String
    var category: String
    var name: String
    var syntax: String
    var explanation: String
    var example: String
    var platform: String
    var tags: [String]

    init(
        id: String,
        category: String,
        name: String,
        syntax: String,
        explanation: String,
        example: String,
        platform: String,
        tags: [String] = []
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.syntax = syntax
        self.explanation = explanation
        self.example = example
        self.platform = platform
        self.tags = tags
    }
}

@Model
final class Concept {
    @Attribute(.unique) var id: String
    var name: String
    var aliases: [String]
    var category: String
    var summary: String
    var details: String
    var relatedTutorialIDs: [String]

    init(
        id: String,
        name: String,
        aliases: [String] = [],
        category: String,
        summary: String,
        details: String,
        relatedTutorialIDs: [String] = []
    ) {
        self.id = id
        self.name = name
        self.aliases = aliases
        self.category = category
        self.summary = summary
        self.details = details
        self.relatedTutorialIDs = relatedTutorialIDs
    }
}

@Model
final class Bookmark {
    @Attribute(.unique) var id: String
    var targetID: String
    var targetType: String
    var parentTutorialID: String?
    var stepIndex: Int?
    var title: String
    var subtitle: String
    var createdAt: Date

    init(
        id: String,
        targetID: String,
        targetType: String,
        parentTutorialID: String? = nil,
        stepIndex: Int? = nil,
        title: String,
        subtitle: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.targetID = targetID
        self.targetType = targetType
        self.parentTutorialID = parentTutorialID
        self.stepIndex = stepIndex
        self.title = title
        self.subtitle = subtitle
        self.createdAt = createdAt
    }
}

@Model
final class LearningNote {
    @Attribute(.unique) var id: String
    var targetID: String
    var parentTutorialID: String?
    var stepIndex: Int?
    var title: String
    var body: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        targetID: String,
        parentTutorialID: String? = nil,
        stepIndex: Int? = nil,
        title: String,
        body: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.targetID = targetID
        self.parentTutorialID = parentTutorialID
        self.stepIndex = stepIndex
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class ReviewItem {
    @Attribute(.unique) var id: String
    var sourceType: String
    var sourceID: String
    var title: String
    var question: String
    var referenceAnswer: String
    var explanation: String
    var userAnswer: String?
    var parentTutorialID: String?
    var stepIndex: Int?
    var dueAt: Date
    var intervalIndex: Int
    var correctStreak: Int
    var lapseCount: Int
    var createdAt: Date
    var lastReviewedAt: Date?
    var isArchived: Bool
    var easeFactor: Double
    var stabilityDays: Double
    var lastResponseSeconds: Double

    init(
        id: String,
        sourceType: String,
        sourceID: String,
        title: String,
        question: String,
        referenceAnswer: String,
        explanation: String,
        userAnswer: String? = nil,
        parentTutorialID: String? = nil,
        stepIndex: Int? = nil,
        dueAt: Date,
        intervalIndex: Int = 0,
        correctStreak: Int = 0,
        lapseCount: Int = 0,
        createdAt: Date = .now,
        lastReviewedAt: Date? = nil,
        isArchived: Bool = false,
        easeFactor: Double = 2.3,
        stabilityDays: Double = 1,
        lastResponseSeconds: Double = 0
    ) {
        self.id = id
        self.sourceType = sourceType
        self.sourceID = sourceID
        self.title = title
        self.question = question
        self.referenceAnswer = referenceAnswer
        self.explanation = explanation
        self.userAnswer = userAnswer
        self.parentTutorialID = parentTutorialID
        self.stepIndex = stepIndex
        self.dueAt = dueAt
        self.intervalIndex = intervalIndex
        self.correctStreak = correctStreak
        self.lapseCount = lapseCount
        self.createdAt = createdAt
        self.lastReviewedAt = lastReviewedAt
        self.isArchived = isArchived
        self.easeFactor = easeFactor
        self.stabilityDays = stabilityDays
        self.lastResponseSeconds = lastResponseSeconds
    }
}

@Model
final class CodeDraft {
    @Attribute(.unique) var exerciseID: String
    var sourceCode: String
    var input: String
    var lastOutput: String
    var lastError: String
    var passed: Bool
    var updatedAt: Date
    var lastRunAt: Date?

    init(
        exerciseID: String,
        sourceCode: String,
        input: String = "",
        lastOutput: String = "",
        lastError: String = "",
        passed: Bool = false,
        updatedAt: Date = .now,
        lastRunAt: Date? = nil
    ) {
        self.exerciseID = exerciseID
        self.sourceCode = sourceCode
        self.input = input
        self.lastOutput = lastOutput
        self.lastError = lastError
        self.passed = passed
        self.updatedAt = updatedAt
        self.lastRunAt = lastRunAt
    }
}

@Model
final class MasteryRecord {
    @Attribute(.unique) var conceptID: String
    var score: Double
    var attempts: Int
    var correctCount: Int
    var wrongCount: Int
    var lastReason: String
    var lastPracticedAt: Date

    init(
        conceptID: String,
        score: Double = 0.35,
        attempts: Int = 0,
        correctCount: Int = 0,
        wrongCount: Int = 0,
        lastReason: String = "尚未练习",
        lastPracticedAt: Date = .now
    ) {
        self.conceptID = conceptID
        self.score = score
        self.attempts = attempts
        self.correctCount = correctCount
        self.wrongCount = wrongCount
        self.lastReason = lastReason
        self.lastPracticedAt = lastPracticedAt
    }
}


@Model
final class LearningResource {
    @Attribute(.unique) var id: String
    var title: String
    var provider: String
    var urlString: String
    var explanation: String
    var language: String
    var difficulty: String
    var isFree: Bool
    var order: Int
    var tutorial: Tutorial?

    init(
        id: String,
        title: String,
        provider: String,
        urlString: String,
        explanation: String,
        language: String = "中文/English",
        difficulty: String = "通用",
        isFree: Bool = true,
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.provider = provider
        self.urlString = urlString
        self.explanation = explanation
        self.language = language
        self.difficulty = difficulty
        self.isFree = isFree
        self.order = order
    }
}
