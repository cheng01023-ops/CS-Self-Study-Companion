import Foundation

struct StudyPlanItem: Identifiable {
    enum Kind {
        case review
        case concept(String)
        case tutorial(String)
        case project(String)
    }

    let id: String
    let kind: Kind
    let title: String
    let detail: String
    let minutes: Int
    let icon: String

    var route: AppRoute? {
        switch kind {
        case .review:
            return nil
        case let .concept(id):
            return .concept(id)
        case let .tutorial(id):
            return .tutorial(id)
        case let .project(id):
            return .project(id)
        }
    }
}

enum StudyPlanService {
    static func makePlan(
        dueReviewCount: Int,
        weakConcept: WeakConcept?,
        tutorials: [Tutorial],
        completedTutorialIDs: Set<String>,
        preferredTutorialID: String? = nil,
        dailyMinutes: Int = 60
    ) -> [StudyPlanItem] {
        var items: [StudyPlanItem] = []

        if dueReviewCount > 0 {
            items.append(
                StudyPlanItem(
                    id: "review",
                    kind: .review,
                    title: "完成到期复习",
                    detail: "\(dueReviewCount) 项内容需要巩固，优先完成再继续新知识。",
                    minutes: min(30, max(5, dueReviewCount * 5)),
                    icon: "brain.head.profile"
                )
            )
        }

        if let weakConcept {
            items.append(
                StudyPlanItem(
                    id: "concept:\(weakConcept.concept.id)",
                    kind: .concept(weakConcept.concept.id),
                    title: "加强概念：\(weakConcept.concept.name)",
                    detail: "当前掌握度 \(Int(weakConcept.record.score * 100))%，先看定义，再做一次练习或主动回忆。",
                    minutes: 20,
                    icon: "target"
                )
            )
        }

        let orderedTutorials = tutorials
            .sorted(by: AdaptiveLearningService.tutorialOrder)
        let preferredTutorial = preferredTutorialID.flatMap { identifier in
            orderedTutorials.first { $0.id == identifier && !completedTutorialIDs.contains($0.id) }
        }
        let nextTutorial = preferredTutorial ?? orderedTutorials.first {
            !completedTutorialIDs.contains($0.id)
        }

        if let tutorial = nextTutorial {
            items.append(
                StudyPlanItem(
                    id: "tutorial:\(tutorial.id)",
                    kind: .tutorial(tutorial.id),
                    title: "继续教程：\(tutorial.title)",
                    detail: "按步骤完成一小节，并运行一个与正文相关的实验。",
                    minutes: min(45, max(15, tutorial.topic?.estimatedMinutes ?? 30)),
                    icon: "book.pages.fill"
                )
            )
        }

        if items.isEmpty {
            items.append(
                StudyPlanItem(
                    id: "review-all",
                    kind: .review,
                    title: "回顾并整理学习成果",
                    detail: "当前主线已经完成，可以整理项目作品、补充笔记或挑战一个综合项目。",
                    minutes: 30,
                    icon: "shippingbox.fill"
                )
            )
        }

        var remaining = max(15, dailyMinutes)
        return items.prefix(3).map { item in
            let allotted = min(item.minutes, remaining)
            remaining = max(0, remaining - allotted)
            return StudyPlanItem(
                id: item.id,
                kind: item.kind,
                title: item.title,
                detail: item.detail,
                minutes: max(5, allotted),
                icon: item.icon
            )
        }
    }

    static func recommendedStageOrder(for score: Int) -> Int {
        switch score {
        case ..<3: 0
        case 3..<5: 1
        case 5..<7: 2
        case 7..<9: 3
        default: 4
        }
    }
}
