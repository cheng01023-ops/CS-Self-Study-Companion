import CryptoKit
import Foundation
import SwiftData

struct CoursePack: Codable {
    var formatVersion: Int
    var contentVersion: String
    var updatedAt: Date
    var minimumAppVersion: String?
    var stages: [CoursePackStage]
}

struct CoursePackStage: Codable {
    var id: String
    var order: Int
    var title: String
    var subtitle: String
    var icon: String
    var themeHex: String
    var topics: [CoursePackTopic]
}

struct CoursePackTopic: Codable {
    var id: String
    var order: Int
    var title: String
    var summary: String
    var estimatedMinutes: Int
    var tutorials: [CoursePackTutorial]
    var exercises: [CoursePackExercise]
}

struct CoursePackTutorial: Codable {
    var id: String
    var order: Int
    var title: String
    var summary: String
    var markdown: String
    var codeLanguage: String
    var code: String
    var secondCodeLanguage: String
    var secondCode: String
    var commonMistakes: String
    var resources: [CoursePackResource]
}

struct CoursePackExercise: Codable {
    var id: String
    var order: Int
    var title: String
    var kind: String
    var question: String
    var options: [String]
    var answer: String
    var explanation: String
    var starterCode: String
    var codeLanguage: String
}

struct CoursePackResource: Codable {
    var id: String
    var title: String
    var provider: String
    var urlString: String
    var explanation: String
    var language: String
    var difficulty: String
    var isFree: Bool
    var order: Int
}

struct CoursePackImportReport {
    var addedStages = 0
    var addedTopics = 0
    var addedTutorials = 0
    var addedExercises = 0
    var addedResources = 0
    var updatedItems = 0

    var summary: String {
        "新增阶段 \(addedStages)、主题 \(addedTopics)、教程 \(addedTutorials)、练习 \(addedExercises)、资源 \(addedResources)；更新 \(updatedItems) 项。"
    }
}

enum CoursePackError: LocalizedError {
    case invalidFormat
    case duplicateID(String)
    case invalidURL
    case checksumMismatch

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            "课程包格式版本不受支持。"
        case let .duplicateID(id):
            "课程包存在重复 ID：\(id)"
        case .invalidURL:
            "课程包地址必须是 HTTPS 地址。"
        case .checksumMismatch:
            "课程包 SHA-256 校验失败，已拒绝导入。"
        }
    }
}

@MainActor
enum CoursePackService {
    static let currentFormatVersion = 1
    static let versionKey = "coursePackVersion"
    static let updatedAtKey = "coursePackUpdatedAt"

    static func exportPack(from context: ModelContext) throws -> CoursePack {
        let stages = try context.fetch(FetchDescriptor<Stage>()).sorted { $0.order < $1.order }
        let packStages = stages.map { stage in
            CoursePackStage(
                id: stage.id,
                order: stage.order,
                title: stage.title,
                subtitle: stage.subtitle,
                icon: stage.icon,
                themeHex: stage.themeHex,
                topics: stage.topics.sorted { $0.order < $1.order }.map { topic in
                    CoursePackTopic(
                        id: topic.id,
                        order: topic.order,
                        title: topic.title,
                        summary: topic.summary,
                        estimatedMinutes: topic.estimatedMinutes,
                        tutorials: topic.tutorials.sorted { $0.order < $1.order }.map { tutorial in
                            CoursePackTutorial(
                                id: tutorial.id,
                                order: tutorial.order,
                                title: tutorial.title,
                                summary: tutorial.summary,
                                markdown: tutorial.markdown,
                                codeLanguage: tutorial.codeLanguage,
                                code: tutorial.code,
                                secondCodeLanguage: tutorial.secondCodeLanguage,
                                secondCode: tutorial.secondCode,
                                commonMistakes: tutorial.commonMistakes,
                                resources: tutorial.resources.sorted { $0.order < $1.order }.map { resource in
                                    CoursePackResource(
                                        id: resource.id,
                                        title: resource.title,
                                        provider: resource.provider,
                                        urlString: resource.urlString,
                                        explanation: resource.explanation,
                                        language: resource.language,
                                        difficulty: resource.difficulty,
                                        isFree: resource.isFree,
                                        order: resource.order
                                    )
                                }
                            )
                        },
                        exercises: topic.exercises.sorted { $0.order < $1.order }.map { exercise in
                            CoursePackExercise(
                                id: exercise.id,
                                order: exercise.order,
                                title: exercise.title,
                                kind: exercise.kindRawValue,
                                question: exercise.question,
                                options: exercise.options,
                                answer: exercise.answer,
                                explanation: exercise.explanation,
                                starterCode: exercise.starterCode,
                                codeLanguage: exercise.codeLanguage
                            )
                        }
                    )
                }
            )
        }

        return CoursePack(
            formatVersion: currentFormatVersion,
            contentVersion: UserDefaults.standard.string(forKey: versionKey) ?? "1.0",
            updatedAt: .now,
            minimumAppVersion: nil,
            stages: packStages
        )
    }

    static func data(from context: ModelContext) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(exportPack(from: context))
    }

    static func decode(_ data: Data) throws -> CoursePack {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pack = try decoder.decode(CoursePack.self, from: data)
        try validate(pack)
        return pack
    }

    static func importPack(_ data: Data, into context: ModelContext) throws -> CoursePackImportReport {
        try importPack(try decode(data), into: context)
    }

    static func importPack(_ pack: CoursePack, into context: ModelContext) throws -> CoursePackImportReport {
        try validate(pack)

        let existingStages = try context.fetch(FetchDescriptor<Stage>())
        let existingTopics = try context.fetch(FetchDescriptor<Topic>())
        let existingTutorials = try context.fetch(FetchDescriptor<Tutorial>())
        let existingExercises = try context.fetch(FetchDescriptor<Exercise>())
        let existingResources = try context.fetch(FetchDescriptor<LearningResource>())

        let stageMap = Dictionary(uniqueKeysWithValues: existingStages.map { ($0.id, $0) })
        let topicMap = Dictionary(uniqueKeysWithValues: existingTopics.map { ($0.id, $0) })
        let tutorialMap = Dictionary(uniqueKeysWithValues: existingTutorials.map { ($0.id, $0) })
        let exerciseMap = Dictionary(uniqueKeysWithValues: existingExercises.map { ($0.id, $0) })
        let resourceMap = Dictionary(uniqueKeysWithValues: existingResources.map { ($0.id, $0) })

        var report = CoursePackImportReport()

        for stageSeed in pack.stages {
            let stage: Stage
            if let existing = stageMap[stageSeed.id] {
                stage = existing
                report.updatedItems += 1
            } else {
                stage = Stage(
                    id: stageSeed.id,
                    order: stageSeed.order,
                    title: stageSeed.title,
                    subtitle: stageSeed.subtitle,
                    icon: stageSeed.icon,
                    themeHex: stageSeed.themeHex
                )
                context.insert(stage)
                report.addedStages += 1
            }
            stage.order = stageSeed.order
            stage.title = stageSeed.title
            stage.subtitle = stageSeed.subtitle
            stage.icon = stageSeed.icon
            stage.themeHex = stageSeed.themeHex

            for topicSeed in stageSeed.topics {
                let topic: Topic
                if let existing = topicMap[topicSeed.id] {
                    topic = existing
                    report.updatedItems += 1
                } else {
                    topic = Topic(
                        id: topicSeed.id,
                        order: topicSeed.order,
                        title: topicSeed.title,
                        summary: topicSeed.summary,
                        estimatedMinutes: topicSeed.estimatedMinutes
                    )
                    context.insert(topic)
                    report.addedTopics += 1
                }
                topic.order = topicSeed.order
                topic.title = topicSeed.title
                topic.summary = topicSeed.summary
                topic.estimatedMinutes = topicSeed.estimatedMinutes
                topic.stage = stage
                if !stage.topics.contains(where: { $0.id == topic.id }) {
                    stage.topics.append(topic)
                }

                for tutorialSeed in topicSeed.tutorials {
                    let tutorial: Tutorial
                    if let existing = tutorialMap[tutorialSeed.id] {
                        tutorial = existing
                        report.updatedItems += 1
                    } else {
                        tutorial = Tutorial(
                            id: tutorialSeed.id,
                            order: tutorialSeed.order,
                            title: tutorialSeed.title,
                            summary: tutorialSeed.summary,
                            markdown: tutorialSeed.markdown
                        )
                        context.insert(tutorial)
                        report.addedTutorials += 1
                    }
                    tutorial.order = tutorialSeed.order
                    tutorial.title = tutorialSeed.title
                    tutorial.summary = tutorialSeed.summary
                    tutorial.markdown = tutorialSeed.markdown
                    tutorial.codeLanguage = tutorialSeed.codeLanguage
                    tutorial.code = tutorialSeed.code
                    tutorial.secondCodeLanguage = tutorialSeed.secondCodeLanguage
                    tutorial.secondCode = tutorialSeed.secondCode
                    tutorial.commonMistakes = tutorialSeed.commonMistakes
                    tutorial.topic = topic
                    if !topic.tutorials.contains(where: { $0.id == tutorial.id }) {
                        topic.tutorials.append(tutorial)
                    }

                    for resourceSeed in tutorialSeed.resources {
                        let resource: LearningResource
                        if let existing = resourceMap[resourceSeed.id] {
                            resource = existing
                            report.updatedItems += 1
                        } else {
                            resource = LearningResource(
                                id: resourceSeed.id,
                                title: resourceSeed.title,
                                provider: resourceSeed.provider,
                                urlString: resourceSeed.urlString,
                                explanation: resourceSeed.explanation
                            )
                            context.insert(resource)
                            report.addedResources += 1
                        }
                        resource.title = resourceSeed.title
                        resource.provider = resourceSeed.provider
                        resource.urlString = resourceSeed.urlString
                        resource.explanation = resourceSeed.explanation
                        resource.language = resourceSeed.language
                        resource.difficulty = resourceSeed.difficulty
                        resource.isFree = resourceSeed.isFree
                        resource.order = resourceSeed.order
                        resource.tutorial = tutorial
                        if !tutorial.resources.contains(where: { $0.id == resource.id }) {
                            tutorial.resources.append(resource)
                        }
                    }
                }

                for exerciseSeed in topicSeed.exercises {
                    let exercise: Exercise
                    if let existing = exerciseMap[exerciseSeed.id] {
                        exercise = existing
                        report.updatedItems += 1
                    } else {
                        exercise = Exercise(
                            id: exerciseSeed.id,
                            order: exerciseSeed.order,
                            title: exerciseSeed.title,
                            kind: ExerciseKind(rawValue: exerciseSeed.kind) ?? .multipleChoice,
                            question: exerciseSeed.question,
                            answer: exerciseSeed.answer,
                            explanation: exerciseSeed.explanation
                        )
                        context.insert(exercise)
                        report.addedExercises += 1
                    }
                    exercise.order = exerciseSeed.order
                    exercise.title = exerciseSeed.title
                    exercise.kindRawValue = exerciseSeed.kind
                    exercise.question = exerciseSeed.question
                    exercise.options = exerciseSeed.options
                    exercise.answer = exerciseSeed.answer
                    exercise.explanation = exerciseSeed.explanation
                    exercise.starterCode = exerciseSeed.starterCode
                    exercise.codeLanguage = exerciseSeed.codeLanguage
                    exercise.topic = topic
                    if !topic.exercises.contains(where: { $0.id == exercise.id }) {
                        topic.exercises.append(exercise)
                    }
                }
            }
        }

        try context.save()
        UserDefaults.standard.set(pack.contentVersion, forKey: versionKey)
        UserDefaults.standard.set(ISO8601DateFormatter().string(from: pack.updatedAt), forKey: updatedAtKey)
        return report
    }

    static func download(
        from url: URL,
        expectedSHA256: String?,
        into context: ModelContext
    ) async throws -> CoursePackImportReport {
        guard url.scheme == "https" else { throw CoursePackError.invalidURL }
        let (data, _) = try await URLSession.shared.data(from: url)
        if let expectedSHA256, !expectedSHA256.isEmpty {
            let actual = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            guard actual.lowercased() == expectedSHA256.lowercased() else {
                throw CoursePackError.checksumMismatch
            }
        }
        return try importPack(data, into: context)
    }

    static func validate(_ pack: CoursePack) throws {
        guard pack.formatVersion == currentFormatVersion else {
            throw CoursePackError.invalidFormat
        }

        var ids = Set<String>()
        for stage in pack.stages {
            try insertUnique(stage.id, into: &ids)
            for topic in stage.topics {
                try insertUnique(topic.id, into: &ids)
                for tutorial in topic.tutorials {
                    try insertUnique(tutorial.id, into: &ids)
                    for resource in tutorial.resources {
                        try insertUnique(resource.id, into: &ids)
                    }
                }
                for exercise in topic.exercises {
                    try insertUnique(exercise.id, into: &ids)
                }
            }
        }
    }

    private static func insertUnique(_ id: String, into ids: inout Set<String>) throws {
        guard !id.isEmpty, !ids.contains(id) else {
            throw CoursePackError.duplicateID(id)
        }
        ids.insert(id)
    }
}
