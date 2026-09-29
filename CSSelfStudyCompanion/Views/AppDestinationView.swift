import SwiftUI

struct AppDestinationView: View {
    let route: AppRoute

    var body: some View {
        switch route {
        case let .stage(id):
            StageDetailView(stageID: id)
        case let .topic(id):
            TopicDetailView(topicID: id)
        case let .tutorial(id):
            TutorialDetailView(tutorialID: id)
        case let .tutorialStep(tutorialID, stepIndex):
            TutorialDetailView(tutorialID: tutorialID, initialStepIndex: stepIndex)
        case let .exercise(id):
            ExerciseDetailView(exerciseID: id)
        case let .concept(id):
            ConceptDetailView(conceptID: id)
        case let .project(id):
            ProjectDetailView(projectID: id)
        case let .lab(id):
            InteractiveLabView(labID: id)
        case .codeReading:
            CodeReadingCenterView()
        case .portfolio:
            ProjectPortfolioView()
        case .performance:
            PerformanceDashboardView()
        case .releaseReadiness:
            ReleaseReadinessView()
        }
    }
}
