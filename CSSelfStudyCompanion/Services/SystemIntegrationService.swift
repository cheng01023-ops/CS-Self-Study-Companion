import CoreSpotlight
import Foundation
import SwiftData

@MainActor
enum SystemIntegrationService {
    static let bundleDomain = "com.example.CSXuexi"
    static let tutorialActivityType = "com.example.CSXuexi.tutorial"

    static func indexSearchableContent(
        tutorials: [Tutorial],
        commands: [Command]
    ) async {
        var items: [CSSearchableItem] = tutorials.map { tutorial in
            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title = tutorial.title
            attributes.contentDescription = tutorial.summary
            attributes.keywords = ["CS", "教程", tutorial.topic?.title ?? "", tutorial.topic?.stage?.title ?? ""]
            attributes.contentURL = URL(string: "csxuexi://tutorial/\(tutorial.id)")
            return CSSearchableItem(
                uniqueIdentifier: "tutorial:\(tutorial.id)",
                domainIdentifier: bundleDomain,
                attributeSet: attributes
            )
        }

        items += commands.map { command in
            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title = "\(command.name) - \(command.category)"
            attributes.contentDescription = command.explanation
            attributes.keywords = [command.platform, command.category] + command.tags
            attributes.contentURL = URL(string: "csxuexi://command/\(command.id)")
            return CSSearchableItem(
                uniqueIdentifier: "command:\(command.id)",
                domainIdentifier: bundleDomain,
                attributeSet: attributes
            )
        }

        try? await CSSearchableIndex.default().indexSearchableItems(items)
    }

    nonisolated static func route(for url: URL) -> AppRoute? {
        guard url.scheme == "csxuexi" else { return nil }
        let components = url.pathComponents.filter { $0 != "/" }
        guard let type = url.host ?? components.first else { return nil }
        if type == "code-reading" { return .codeReading }
        if type == "portfolio" { return .portfolio }

        let identifier = url.host == nil ? components.dropFirst().first : components.first
        guard let identifier, !identifier.isEmpty else { return nil }

        switch type {
        case "tutorial": return .tutorial(identifier)
        case "stage": return .stage(identifier)
        case "project": return .project(identifier)
        case "lab": return .lab(identifier)
        case "code-reading": return .codeReading
        default: return nil
        }
    }
}
