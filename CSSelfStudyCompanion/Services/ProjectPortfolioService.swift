import Foundation

struct ProjectPortfolioItem {
    let project: LearningProject
    let completedMilestones: Int
    let totalMilestones: Int

    var progress: Double {
        guard totalMilestones > 0 else { return 0 }
        return Double(completedMilestones) / Double(totalMilestones)
    }

    var isCompleted: Bool { totalMilestones > 0 && completedMilestones == totalMilestones }
}

enum ProjectPortfolioService {
    static func items(progressRecords: [Progress]) -> [ProjectPortfolioItem] {
        ProjectCatalog.projects.map { project in
            let completed = project.milestones.filter { milestone in
                let itemID = "project:\(project.id):milestone:\(milestone.id)"
                return progressRecords.contains { $0.itemID == itemID && $0.isCompleted }
            }.count
            return ProjectPortfolioItem(
                project: project,
                completedMilestones: completed,
                totalMilestones: project.milestones.count
            )
        }
    }

    static func recommendedNext(progressRecords: [Progress]) -> ProjectPortfolioItem? {
        items(progressRecords: progressRecords)
            .filter { !$0.isCompleted }
            .sorted {
                if $0.project.order == $1.project.order { return $0.project.id < $1.project.id }
                return $0.project.order < $1.project.order
            }
            .first
    }

    static func items(
        in track: ProjectTrack,
        progressRecords: [Progress]
    ) -> [ProjectPortfolioItem] {
        items(progressRecords: progressRecords)
            .filter { $0.project.track == track }
            .sorted { $0.project.order < $1.project.order }
    }

    static func markdown(
        progressRecords: [Progress],
        exportedAt: Date = .now
    ) -> String {
        let items = items(progressRecords: progressRecords)
        let completedProjects = items.filter(\.isCompleted).count
        let completedMilestones = items.reduce(0) { $0 + $1.completedMilestones }
        let totalMilestones = items.reduce(0) { $0 + $1.totalMilestones }

        var lines = [
            "# CS 自学项目作品集",
            "",
            "- 生成时间：\(exportedAt.formatted(date: .numeric, time: .shortened))",
            "- 已完成项目：\(completedProjects)/\(items.count)",
            "- 已完成里程碑：\(completedMilestones)/\(totalMilestones)",
            ""
        ]

        for item in items {
            lines += [
                "## \(item.project.title)",
                "",
                item.project.summary,
                "",
                "- 工程轨道：\(item.project.track.title)",
                "- 难度：\(item.project.level)",
                "- 预计工时：\(item.project.estimatedHours) 小时",
                "- 技术标签：\(item.project.tags.joined(separator: "、"))",
                "- 完成度：\(Int(item.progress * 100))%",
                "- 状态：\(item.isCompleted ? "已验收" : "进行中")",
                "",
                "### 里程碑"
            ]
            for milestone in item.project.milestones {
                let itemID = "project:\(item.project.id):milestone:\(milestone.id)"
                let record = progressRecords.first { $0.itemID == itemID && $0.isCompleted }
                let mark = record == nil ? "[ ]" : "[x]"
                let dateText = record?.completedAt.map { " · \($0.formatted(date: .numeric, time: .omitted))" } ?? ""
                lines.append("- \(mark) \(milestone.title)：\(milestone.detail)\(dateText)")
            }
            lines += [
                "",
                "### 仓库地图",
                ""
            ]
            lines += item.project.repository.map { "- `\($0.path)`：\($0.purpose)" }
            lines += [
                "",
                "### 质量门禁",
                ""
            ]
            lines += item.project.qualityGates.map { "- [ ] \($0)" }
            lines += [
                "",
                "### 交付物",
                ""
            ]
            lines += item.project.deliverables.map { "- [ ] \($0)" }
            lines.append("")
        }

        lines += [
            "---",
            "",
            "说明：本报告由 CS 自学 App 根据项目里程碑完成状态自动生成。交付物仍需要在真实仓库中提供文件、测试和演示记录。"
        ]
        return lines.joined(separator: "\n")
    }
}
