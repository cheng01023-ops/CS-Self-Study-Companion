import Foundation

enum LearningCatalog {
    static let stages: [LearningStageSeed] = {
        let linuxStage = LearningStageSeed(
            id: "stage-3",
            order: 3,
            title: "Linux 基础与 Shell",
            subtitle: "从 Ubuntu 环境、Shell 自动化到系统管理、系统编程、网络、内核、容器和安全。",
            icon: "terminal.fill",
            themeHex: "E67E22",
            topics: CatalogLinuxBasics.topics + CatalogLinuxAdvanced.topics
        )

        return CatalogFoundation.stages + [linuxStage] + CatalogSystems.stages + CatalogAdvanced.stages
    }()
}
