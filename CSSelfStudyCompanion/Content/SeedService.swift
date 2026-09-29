import Foundation
import SwiftData

@MainActor
enum SeedService {
    private static let tutorialContentVersion = 6
    private static let tutorialContentVersionKey = "tutorialContentVersion"

    static func seedIfNeeded(in context: ModelContext) {
        seedStagesIfNeeded(in: context)
        seedCommandsIfNeeded(in: context)
        seedConceptsIfNeeded(in: context)
        upgradeTutorialContentIfNeeded(in: context)
        seedResourcesIfNeeded(in: context)
    }

    private static func seedStagesIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<Stage>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }

        for stageSeed in LearningCatalog.stages {
            let stage = Stage(
                id: stageSeed.id,
                order: stageSeed.order,
                title: stageSeed.title,
                subtitle: stageSeed.subtitle,
                icon: stageSeed.icon,
                themeHex: stageSeed.themeHex
            )
            context.insert(stage)

            for topicSeed in stageSeed.topics {
                let topic = Topic(
                    id: topicSeed.id,
                    order: topicSeed.order,
                    title: topicSeed.title,
                    summary: topicSeed.summary,
                    estimatedMinutes: topicSeed.estimatedMinutes
                )
                context.insert(topic)
                topic.stage = stage
                stage.topics.append(topic)

                for tutorialSeed in topicSeed.tutorials {
                    let tutorial = Tutorial(
                        id: tutorialSeed.id,
                        order: tutorialSeed.order,
                        title: tutorialSeed.title,
                        summary: tutorialSeed.summary,
                        markdown: TutorialContentComposer.expandedMarkdown(
                            tutorial: tutorialSeed,
                            topic: topicSeed,
                            stage: stageSeed
                        ),
                        codeLanguage: tutorialSeed.codeLanguage,
                        code: tutorialSeed.code,
                        secondCodeLanguage: tutorialSeed.secondCodeLanguage,
                        secondCode: tutorialSeed.secondCode,
                        commonMistakes: tutorialSeed.commonMistakes
                    )
                    context.insert(tutorial)
                    tutorial.topic = topic
                    topic.tutorials.append(tutorial)
                }

                for exerciseSeed in topicSeed.exercises {
                    let exercise = Exercise(
                        id: exerciseSeed.id,
                        order: exerciseSeed.order,
                        title: exerciseSeed.title,
                        kind: exerciseSeed.kind,
                        question: exerciseSeed.question,
                        options: exerciseSeed.options,
                        answer: exerciseSeed.answer,
                        explanation: exerciseSeed.explanation,
                        starterCode: exerciseSeed.starterCode,
                        codeLanguage: exerciseSeed.codeLanguage
                    )
                    context.insert(exercise)
                    exercise.topic = topic
                    topic.exercises.append(exercise)
                }
            }
        }

        try? context.save()
    }


    private static func seedConceptsIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<Concept>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }

        ConceptCatalog.all.forEach(context.insert)
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
