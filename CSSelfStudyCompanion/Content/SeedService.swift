import Foundation
import SwiftData

@MainActor
enum SeedService {
    private static let tutorialContentVersion = 8
    private static let tutorialContentVersionKey = "tutorialContentVersion"

    static func seedIfNeeded(in context: ModelContext) {
        seedStagesIfNeeded(in: context)
        seedCommandsIfNeeded(in: context)
        seedConceptsIfNeeded(in: context)
        upgradeTutorialContentIfNeeded(in: context)
        seedResourcesIfNeeded(in: context)
    }

    private static func seedStagesIfNeeded(in context: ModelContext) {
        let existingStages = (try? context.fetch(FetchDescriptor<Stage>())) ?? []
        let wasInitialSeed = existingStages.isEmpty
        let existingTopics = existingStages.flatMap(\.topics)
        let existingTutorials = existingTopics.flatMap(\.tutorials)
        let existingExercises = existingTopics.flatMap(\.exercises)

        var stageMap = Dictionary(uniqueKeysWithValues: existingStages.map { ($0.id, $0) })
        var topicMap = Dictionary(uniqueKeysWithValues: existingTopics.map { ($0.id, $0) })
        var tutorialMap = Dictionary(uniqueKeysWithValues: existingTutorials.map { ($0.id, $0) })
        var exerciseMap = Dictionary(uniqueKeysWithValues: existingExercises.map { ($0.id, $0) })

        for stageSeed in LearningCatalog.stages {
            let stage = stageMap[stageSeed.id] ?? {
                let record = Stage(
                    id: stageSeed.id,
                    order: stageSeed.order,
                    title: stageSeed.title,
                    subtitle: stageSeed.subtitle,
                    icon: stageSeed.icon,
                    themeHex: stageSeed.themeHex
                )
                context.insert(record)
                stageMap[stageSeed.id] = record
                return record
            }()

            stage.order = stageSeed.order
            stage.title = stageSeed.title
            stage.subtitle = stageSeed.subtitle
            stage.icon = stageSeed.icon
            stage.themeHex = stageSeed.themeHex

            for topicSeed in stageSeed.topics {
                let topic = topicMap[topicSeed.id] ?? {
                    let record = Topic(
                        id: topicSeed.id,
                        order: topicSeed.order,
                        title: topicSeed.title,
                        summary: topicSeed.summary,
                        estimatedMinutes: topicSeed.estimatedMinutes
                    )
                    context.insert(record)
                    topicMap[topicSeed.id] = record
                    return record
                }()

                topic.order = topicSeed.order
                topic.title = topicSeed.title
                topic.summary = topicSeed.summary
                topic.estimatedMinutes = topicSeed.estimatedMinutes
                topic.stage = stage
                if !stage.topics.contains(where: { $0.id == topic.id }) {
                    stage.topics.append(topic)
                }

                for tutorialSeed in topicSeed.tutorials {
                    let tutorial = tutorialMap[tutorialSeed.id] ?? {
                        let record = Tutorial(
                            id: tutorialSeed.id,
                            order: tutorialSeed.order,
                            title: tutorialSeed.title,
                            summary: tutorialSeed.summary,
                            markdown: "",
                            commonMistakes: tutorialSeed.commonMistakes
                        )
                        context.insert(record)
                        tutorialMap[tutorialSeed.id] = record
                        return record
                    }()

                    tutorial.order = tutorialSeed.order
                    tutorial.title = tutorialSeed.title
                    tutorial.summary = tutorialSeed.summary
                    tutorial.codeLanguage = tutorialSeed.codeLanguage
                    tutorial.code = tutorialSeed.code
                    tutorial.secondCodeLanguage = tutorialSeed.secondCodeLanguage
                    tutorial.secondCode = tutorialSeed.secondCode
                    tutorial.commonMistakes = tutorialSeed.commonMistakes
                    if tutorial.markdown.isEmpty {
                        tutorial.markdown = TutorialContentComposer.expandedMarkdown(
                            tutorial: tutorialSeed,
                            topic: topicSeed,
                            stage: stageSeed
                        )
                    }
                    tutorial.topic = topic
                    if !topic.tutorials.contains(where: { $0.id == tutorial.id }) {
                        topic.tutorials.append(tutorial)
                    }
                }

                for exerciseSeed in topicSeed.exercises {
                    let exercise = exerciseMap[exerciseSeed.id] ?? {
                        let record = Exercise(
                            id: exerciseSeed.id,
                            order: exerciseSeed.order,
                            title: exerciseSeed.title,
                            kind: exerciseSeed.kind,
                            question: exerciseSeed.question,
                            answer: exerciseSeed.answer,
                            explanation: exerciseSeed.explanation
                        )
                        context.insert(record)
                        exerciseMap[exerciseSeed.id] = record
                        return record
                    }()

                    exercise.order = exerciseSeed.order
                    exercise.title = exerciseSeed.title
                    exercise.kindRawValue = exerciseSeed.kind.rawValue
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

        do {
            try context.save()
            if wasInitialSeed {
                UserDefaults.standard.set(tutorialContentVersion, forKey: tutorialContentVersionKey)
            }
        } catch {
            // 保留旧版本号，下次启动会继续补齐，避免把不完整内容标记为完成。
        }
    }


    private static func seedConceptsIfNeeded(in context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Concept>())) ?? []
        var conceptMap = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        for seed in ConceptCatalog.all {
            let concept = conceptMap[seed.id] ?? {
                let record = Concept(
                    id: seed.id,
                    name: seed.name,
                    aliases: seed.aliases,
                    category: seed.category,
                    summary: seed.summary,
                    details: seed.details,
                    relatedTutorialIDs: seed.relatedTutorialIDs
                )
                context.insert(record)
                conceptMap[seed.id] = record
                return record
            }()

            concept.name = seed.name
            concept.aliases = seed.aliases
            concept.category = seed.category
            concept.summary = seed.summary
            concept.details = seed.details
            concept.relatedTutorialIDs = seed.relatedTutorialIDs
        }

        try? context.save()
    }


    private static func seedResourcesIfNeeded(in context: ModelContext) {
        let tutorials = (try? context.fetch(FetchDescriptor<Tutorial>())) ?? []
        let tutorialMap = Dictionary(uniqueKeysWithValues: tutorials.map { ($0.id, $0) })
        let existing = (try? context.fetch(FetchDescriptor<LearningResource>())) ?? []
        let existingMap = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        for (index, seed) in LearningResourceCatalog.all.enumerated() {
            let resource = existingMap[seed.id] ?? LearningResource(
                id: seed.id,
                title: seed.title,
                provider: seed.provider,
                urlString: seed.urlString,
                explanation: seed.explanation,
                language: seed.language,
                difficulty: seed.difficulty,
                order: index
            )
            if existingMap[seed.id] == nil {
                context.insert(resource)
            }
            resource.title = seed.title
            resource.provider = seed.provider
            resource.urlString = seed.urlString
            resource.explanation = seed.explanation
            resource.language = seed.language
            resource.difficulty = seed.difficulty
            resource.order = index
            resource.tutorial = tutorialMap[seed.tutorialID]
        }

        try? context.save()
    }

    private static func upgradeTutorialContentIfNeeded(in context: ModelContext) {
        let currentVersion = UserDefaults.standard.integer(forKey: tutorialContentVersionKey)
        guard currentVersion < tutorialContentVersion else { return }

        let descriptor = FetchDescriptor<Tutorial>()
        guard let storedTutorials = try? context.fetch(descriptor) else { return }
        let seeds = tutorialSeedIndex()

        for stored in storedTutorials {
            guard let item = seeds[stored.id] else { continue }
            stored.markdown = TutorialContentComposer.expandedMarkdown(
                tutorial: item.tutorial,
                topic: item.topic,
                stage: item.stage
            )
            stored.codeLanguage = item.tutorial.codeLanguage
            stored.code = item.tutorial.code
            stored.secondCodeLanguage = item.tutorial.secondCodeLanguage
            stored.secondCode = item.tutorial.secondCode
            stored.commonMistakes = item.tutorial.commonMistakes
        }

        do {
            try context.save()
            UserDefaults.standard.set(tutorialContentVersion, forKey: tutorialContentVersionKey)
        } catch {
            // 保存失败时保留旧版本号，下次启动会再次迁移，避免内容版本被错误标记为完成。
            return
        }
    }

    private static func tutorialSeedIndex() -> [String: (
        stage: LearningStageSeed,
        topic: LearningTopicSeed,
        tutorial: LearningTutorialSeed
    )] {
        var result: [String: (
            stage: LearningStageSeed,
            topic: LearningTopicSeed,
            tutorial: LearningTutorialSeed
        )] = [:]

        for stage in LearningCatalog.stages {
            for topic in stage.topics {
                for tutorial in topic.tutorials {
                    result[tutorial.id] = (stage, topic, tutorial)
                }
            }
        }
        return result
    }

    private static func seedCommandsIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<Command>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }

        for seed in CommandCatalog.all {
            context.insert(
                Command(
                    id: seed.id,
                    category: seed.category,
                    name: seed.name,
                    syntax: seed.syntax,
                    explanation: seed.explanation,
                    example: seed.example,
                    platform: seed.platform,
                    tags: seed.tags
                )
            )
        }

        try? context.save()
    }
}
