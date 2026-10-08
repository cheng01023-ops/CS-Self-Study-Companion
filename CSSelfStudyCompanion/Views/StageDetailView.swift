import SwiftData
import SwiftUI

struct StageDetailView: View {
    @Query(sort: \Stage.order) private var stages: [Stage]
    @Query(sort: \Tutorial.order) private var tutorials: [Tutorial]
    @Query(sort: \Concept.name) private var concepts: [Concept]
    @Query(sort: \MasteryRecord.score) private var masteryRecords: [MasteryRecord]
    @Query private var progressRecords: [Progress]

    let stageID: String

    private var stage: Stage? {
        stages.first { $0.id == stageID }
    }

    var body: some View {
        Group {
            if let stage {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        header(stage)
                        adaptiveHeader(stage)
                        ForEach(stage.topics.sorted(by: { $0.order < $1.order })) { topic in
                            let readiness = topicReadiness(topic)
                            NavigationLink(value: AppRoute.topic(topic.id)) {
                                TopicRow(
                                    topic: topic,
                                    isCompleted: topicCompleted(topic),
                                    readinessLevel: readiness.level,
                                    readinessScore: readiness.score,
                                    readyCount: readiness.readyCount,
                                    totalCount: readiness.totalCount
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .learningPageWidth()
                }
                .background(Color.appBackground)
                .navigationTitle(stage.title)
            } else {
                ContentUnavailableView("阶段不存在", systemImage: "questionmark.folder")
            }
        }
    }

    private func header(_ stage: Stage) -> some View {
        let color = Color(hex: stage.themeHex)
        let value = stage.topics.isEmpty ? 0 : Double(stage.topics.filter(topicCompleted).count) / Double(stage.topics.count)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: stage.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 58, height: 58)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 6) {
                    Text("阶段 \(stage.order)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color)
                    Text(stage.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
            }

            HStack {
                Text("阶段进度")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(color)
            }
            LearningProgressBar(value: value, tint: color)

            Text("建议按顺序完成。遇到陌生概念时先运行示例，再回到解释中逐行理解。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .learningCard()
    }

    private func adaptiveHeader(_ stage: Stage) -> some View {
        let stageTutorialIDs = Set(stage.topics.flatMap(\.tutorials).map(\.id))
        let items = adaptiveSnapshot.items.filter { stageTutorialIDs.contains($0.tutorial.id) }
        let average = items.isEmpty ? 0 : items.reduce(0) { $0 + ($1.level == .completed ? 1 : $1.score) } / Double(items.count)
        let ready = items.filter { $0.level == .ready }.count
        let bridges = items.filter { $0.level == .nearlyReady || $0.level == .needsBridge }.count
        let color = Color(hex: stage.themeHex)

        return VStack(alignment: .leading, spacing: 11) {
            HStack {
                Label("自适应就绪度", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.headline)
                Spacer()
                Text("\(Int(average * 100))%")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(color)
            }
            LearningProgressBar(value: average, tint: color)
            HStack {
                StatPill(icon: "play.circle.fill", text: "\(ready) 可开始", tint: .indigo)
                StatPill(icon: "arrow.triangle.branch", text: "\(bridges) 需补桥", tint: .orange)
                Spacer()
                NavigationLink(value: AppRoute.adaptivePath) {
                    Label("查看路线", systemImage: "arrow.right")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
            }
            Text("就绪度会结合前置概念的掌握度和教程完成记录。建议表示推荐顺序，不会锁住你自由学习。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .learningCard()
    }

    private var adaptiveSnapshot: AdaptiveLearningSnapshot {
        AdaptiveLearningService.snapshot(
            tutorials: tutorials,
            concepts: concepts,
            masteryRecords: masteryRecords,
            progressRecords: progressRecords
        )
    }

    private func topicReadiness(_ topic: Topic) -> (
        level: AdaptiveReadinessLevel,
        score: Double,
        readyCount: Int,
        totalCount: Int
    ) {
        let ids = Set(topic.tutorials.map(\.id))
        let items = adaptiveSnapshot.items.filter { ids.contains($0.tutorial.id) }
        guard !items.isEmpty else { return (.ready, 1, 0, 0) }

        let score = items.reduce(0) { $0 + ($1.level == .completed ? 1 : $1.score) } / Double(items.count)
        let readyCount = items.filter { $0.level == .ready || $0.level == .completed }.count
        let level: AdaptiveReadinessLevel
        if items.allSatisfy({ $0.level == .completed }) {
            level = .completed
        } else if items.contains(where: { $0.level == .needsBridge }) {
            level = .needsBridge
        } else if items.contains(where: { $0.level == .nearlyReady }) {
            level = .nearlyReady
        } else {
            level = .ready
        }
        return (level, score, readyCount, items.count)
    }

    private func topicCompleted(_ topic: Topic) -> Bool {
        let ids = topic.tutorials.map { String.tutorialProgressID($0.id) }
            + topic.exercises.map { String.exerciseProgressID($0.id) }
        guard !ids.isEmpty else { return false }
        return ids.allSatisfy { id in
            progressRecords.contains { $0.itemID == id && $0.isCompleted }
        }
    }
}

private struct TopicRow: View {
    let topic: Topic
    let isCompleted: Bool
    let readinessLevel: AdaptiveReadinessLevel
    let readinessScore: Double
    let readyCount: Int
    let totalCount: Int

    private var readinessColor: Color {
        switch readinessLevel {
        case .completed: .green
        case .ready: .indigo
        case .nearlyReady: .orange
        case .needsBridge: .red
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green.opacity(0.14) : Color.accentColor.opacity(0.1))
                Image(systemName: isCompleted ? "checkmark" : "\(topic.order).circle.fill")
                    .font(.headline)
                    .foregroundStyle(isCompleted ? .green : .accentColor)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(topic.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(topic.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 12) {
                    Label("\(topic.tutorials.count) 篇", systemImage: "book")
                    Label("\(topic.exercises.count) 题", systemImage: "pencil.and.list.clipboard")
                    Label("\(topic.estimatedMinutes) 分钟", systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.tertiary)

                HStack(spacing: 6) {
                    Label(readinessLevel.title, systemImage: readinessLevel.icon)
                    Text("\(readyCount)/\(totalCount) · \(Int(readinessScore * 100))%")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(readinessColor)
            }

            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .learningCard()
    }
}
