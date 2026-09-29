import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ProjectPortfolioView: View {
    @Query private var progressRecords: [Progress]
    @State private var document: AppBackupDocument?
    @State private var isExporting = false
    @State private var statusMessage = ""

    private var items: [ProjectPortfolioItem] {
        ProjectPortfolioService.items(progressRecords: progressRecords)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                header
                ForEach(items, id: \.project.id) { item in
                    projectCard(item)
                }
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .learningCard()
                }
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
        .navigationTitle("项目作品集")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    exportPortfolio()
                } label: {
                    Label("导出作品集", systemImage: "square.and.arrow.up")
                }
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: document,
            contentType: .plainText,
            defaultFilename: "CS自学项目作品集"
        ) { result in
            switch result {
            case .success: statusMessage = "作品集报告已导出。"
            case let .failure(error): statusMessage = "导出失败：\(error.localizedDescription)"
            }
        }
    }

    private var header: some View {
        let completedProjects = items.filter(\.isCompleted).count
        let completedMilestones = items.reduce(0) { $0 + $1.completedMilestones }
        let totalMilestones = items.reduce(0) { $0 + $1.totalMilestones }
        return VStack(alignment: .leading, spacing: 12) {
            Label("项目作品集", systemImage: "folder.badge.gearshape")
                .font(.title2.bold())
            Text("作品集根据项目里程碑自动生成，记录已完成项目、关键实现步骤和交付物状态。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
            HStack {
                StatPill(icon: "hammer.fill", text: "\(completedProjects)/\(items.count) 项目")
                StatPill(icon: "checkmark.circle.fill", text: "\(completedMilestones)/\(totalMilestones) 里程碑")
            }
        }
        .learningCard()
    }

    private func projectCard(_ item: ProjectPortfolioItem) -> some View {
        let color = Color(hex: item.project.themeHex)
        return VStack(alignment: .leading, spacing: 11) {
            HStack {
                Image(systemName: item.project.icon)
                    .foregroundStyle(color)
                Text(item.project.title)
                    .font(.headline)
                Spacer()
                Text(item.isCompleted ? "已验收" : "\(Int(item.progress * 100))%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(item.isCompleted ? .green : color)
            }
            Text(item.project.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            LearningProgressBar(value: item.progress, tint: color)
            HStack {
                ForEach(item.project.tags.prefix(3), id: \.self) { tag in
                    Text(tag)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.1), in: Capsule())
                }
                Spacer()
                Text("\(item.completedMilestones)/\(item.totalMilestones) 步骤")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .learningCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.project.title)，完成 \(item.completedMilestones) 个，共 \(item.totalMilestones) 个里程碑")
    }

    private func exportPortfolio() {
        let markdown = ProjectPortfolioService.markdown(progressRecords: progressRecords)
        document = AppBackupDocument(data: Data(markdown.utf8))
        isExporting = true
    }
}
