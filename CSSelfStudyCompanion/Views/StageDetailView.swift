import SwiftData
import SwiftUI

struct StageDetailView: View {
    @Query(sort: \Stage.order) private var stages: [Stage]
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
                        ForEach(stage.topics.sorted(by: { $0.order < $1.order })) { topic in
                            NavigationLink(value: AppRoute.topic(topic.id)) {
                                TopicRow(topic: topic, isCompleted: topicCompleted(topic))
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
            }

            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .learningCard()
    }
}
