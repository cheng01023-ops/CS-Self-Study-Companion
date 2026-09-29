import Foundation

struct LearningStageSeed {
    let id: String
    let order: Int
    let title: String
    let subtitle: String
    let icon: String
    let themeHex: String
    let topics: [LearningTopicSeed]
}

struct LearningTopicSeed {
    let id: String
    let order: Int
    let title: String
    let summary: String
    let estimatedMinutes: Int
    let tutorials: [LearningTutorialSeed]
    let exercises: [LearningExerciseSeed]
}

struct LearningTutorialSeed {
    let id: String
    let order: Int
    let title: String
    let summary: String
    let markdown: String
    let codeLanguage: String
    let code: String
    let secondCodeLanguage: String
    let secondCode: String
    let commonMistakes: String

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

struct LearningExerciseSeed {
    let id: String
    let order: Int
    let title: String
    let kind: ExerciseKind
    let question: String
    let options: [String]
    let answer: String
    let explanation: String
    let starterCode: String
    let codeLanguage: String

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
        self.kind = kind
        self.question = question
        self.options = options
        self.answer = answer
        self.explanation = explanation
        self.starterCode = starterCode
        self.codeLanguage = codeLanguage
    }
}

struct CommandSeed {
    let id: String
    let category: String
    let name: String
    let syntax: String
    let explanation: String
    let example: String
    let platform: String
    let tags: [String]
}

struct LearningResourceSeed {
    let id: String
    let tutorialID: String
    let title: String
    let provider: String
    let urlString: String
    let explanation: String
    let language: String
    let difficulty: String
    let order: Int
}
