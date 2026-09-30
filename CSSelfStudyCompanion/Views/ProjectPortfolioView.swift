import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ProjectPortfolioView: View {
    @Query private var progressRecords: [Progress]
    @State private var selectedTrack: ProjectTrack?
    @State private var document: AppBackupDocument?
    @State private var isExporting = false
    @State private var statusMessage = ""

    private var items: [ProjectPortfolioItem] {
        ProjectPortfolioService.items(progressRecords: progressRecords)
    }

    private var visibleTracks: [ProjectTrack] {
        ProjectTrack.allCases
            .filter { selectedTrack == nil || $0 == selectedTrack }
            .sorted { $0.order < $1.order }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                header
                if let next = ProjectPortfolioService.recommendedNext(progressRecords: progressRecords) {
                    nextProjectCard(next)
                }
                trackFilter

                ForEach(visibleTracks) { track in
                    let trackItems = ProjectPortfolioService.items(in: track, progressRecords: progressRecords)
                    if !trackItems.isEmpty {
                        trackSection(track, items: trackItems)
                    }
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
        let totalHours = ProjectCatalog.projects.reduce(0) { $0 + $1.estimatedHours }

        return VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Label("工程作品阶梯", systemImage: "folder.badge.gearshape")
                        .font(.title2.bold())
                    Text("从单文件 CLI 到并发服务、存储引擎和 Apple 平台 App，每个项目都包含仓库地图、质量门禁和发布验收。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
                Spacer()
                Image(systemName: "shippingbox.and.arrow.backward.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.orange.opacity(0.75))
            }

            HStack {
                StatPill(icon: "hammer.fill", text: "\(completedProjects)/\(items.count) 项目", tint: .orange)
                StatPill(icon: "checkmark.circle.fill", text: "\(completedMilestones)/\(totalMilestones) 里程碑", tint: .green)
                StatPill(icon: "clock", text: "约 \(totalHours) 小时", tint: .blue)
            }
        }
        .learningCard()
    }

    private func nextProjectCard(_ item: ProjectPortfolioItem) -> some View {
        let color = Color(hex: item.project.themeHex)
        return NavigationLink(value: AppRoute.project(item.project.id)) {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 13))

                VStack(alignment: .leading, spacing: 5) {
                    Text("推荐下一项工程")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    Text(item.project.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(item.project.track.title) · \(item.project.level) · \(item.project.estimatedHours) 小时")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(color)
                    Text(item.project.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .learningCard()
        }
        .buttonStyle(.plain)
    }

    private var trackFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterButton(title: "全部", track: nil)
                ForEach(ProjectTrack.allCases.sorted { $0.order < $1.order }) { track in
                    filterButton(title: track.title, track: track)
                }
            }
        }
    }

    private func filterButton(title: String, track: ProjectTrack?) -> some View {
        let selected = selectedTrack == track
        return Button {
            selectedTrack = track
        } label: {
            Label(title, systemImage: track?.icon ?? "square.grid.2x2.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? .white : .primary)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(selected ? Color.indigo : Color.secondary.opacity(0.09), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func trackSection(_ track: ProjectTrack, items: [ProjectPortfolioItem]) -> some View {
        let color = Color(hex: track.tintHex)
        let completed = items.filter(\.isCompleted).count

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(track.title, systemImage: track.icon)
                    .font(.title3.bold())
                    .foregroundStyle(color)
                Spacer()
                Text("\(completed)/\(items.count)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(.secondary)
            }

            ForEach(items, id: \.project.id) { item in
                projectCard(item)
            }
        }
    }

    private func projectCard(_ item: ProjectPortfolioItem) -> some View {
        let color = Color(hex: item.project.themeHex)
        let nextMilestone = item.project.milestones.first { milestone in
            let itemID = "project:\(item.project.id):milestone:\(milestone.id)"
            return !progressRecords.contains { $0.itemID == itemID && $0.isCompleted }
        }

        return NavigationLink(value: AppRoute.project(item.project.id)) {
            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .top) {
                    Image(systemName: item.project.icon)
                        .font(.title3)
                        .foregroundStyle(color)
                        .frame(width: 34, height: 34)
                        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.project.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("\(item.project.level) · \(item.project.estimatedHours) 小时")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(color)
                    }
                    Spacer()
                    Text(item.isCompleted ? "已验收" : "\(Int(item.progress * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(item.isCompleted ? .green : color)
                }

                Text(item.project.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let nextMilestone {
                    Label("下一里程碑：\(nextMilestone.title)", systemImage: "arrow.forward.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

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
                    Image(systemName: "chevron.right")
                        .font(.caption2.bold())
                        .foregroundStyle(.tertiary)
                }
            }
            .learningCard()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.project.title)，完成 \(item.completedMilestones) 个，共 \(item.totalMilestones) 个里程碑")
    }

    private func exportPortfolio() {
        let markdown = ProjectPortfolioService.markdown(progressRecords: progressRecords)
        document = AppBackupDocument(data: Data(markdown.utf8))
        isExporting = true
    }
}

#Preview {
    ProjectPortfolioView()
        .modelContainer(for: [Progress.self], inMemory: true)
}
