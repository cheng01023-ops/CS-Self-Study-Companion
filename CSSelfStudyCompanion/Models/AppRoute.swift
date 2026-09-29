import Foundation

enum AppRoute: Hashable {
    case stage(String)
    case topic(String)
    case tutorial(String)
    case tutorialStep(tutorialID: String, stepIndex: Int)
    case exercise(String)
    case concept(String)
    case project(String)
    case lab(String)
    case codeReading
    case portfolio
    case performance
    case releaseReadiness
}
