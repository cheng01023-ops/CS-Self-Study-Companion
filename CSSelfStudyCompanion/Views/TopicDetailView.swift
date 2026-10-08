import SwiftData
import SwiftUI

struct TopicDetailView: View {
    @Query(sort: \Topic.order) private var topics: [Topic]
    @Query(sort: \Tutorial.order) private var tutorials: [Tutorial]
    @Query(sort: \Concept.name) private var concepts: [Concept]
    @Query(sort: \MasteryRecord.score) private var masteryRecords: [MasteryRecord]
    @Query private var progressRecords: [Progress]

    let topicID: String

    private var topic: Topic? {
        topics.first { $0.id == topicID }
    }

    var body: some View {
        Group {
            if let topic {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(topic.summary)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineSpacing(4)
                            HStack {
                                StatPill(icon: "clock", text: "\(topic.estimatedMinutes) 分钟")
                                StatPill(icon: "book", text: "\(topic.tutorials.count) 篇教程")
                                StatPill(icon: "checkmark.seal", text: "\(topic.exercises.count) 道练习")
                            }
                        }
                        .learningCard()

                        topicReadinessCard(topic)
                        learningAdviceCard(topic)

                        if !topic.tutorials.isEmpty {
                            sectionTitle("教程")
                            ForEach(topic.tutorials.sorted(by: { $0.order < $1.order })) { tutorial in
                                NavigationLink(value: AppRoute.tutorial(tutorial.id)) {
                                    ContentRow(
                                        icon: "book.pages",
                                        title: tutorial.title,
                                        subtitle: tutorial.summary,
                                        done: completed(.tutorialProgressID(tutorial.id)),
                                        readiness: readiness(for: tutorial)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if !topic.exercises.isEmpty {
                            sectionTitle("练习")
                            ForEach(topic.exercises.sorted(by: { $0.order < $1.order })) { exercise in
                                NavigationLink(value: AppRoute.exercise(exercise.id)) {
                                    ContentRow(
                                        icon: "pencil.and.list.clipboard",
                                        title: exercise.title,
                                        subtitle: exercise.kind.title,
                                        done: completed(.exerciseProgressID(exercise.id))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                    .learningPageWidth()
                }
                .background(Color.appBackground)
                .navigationTitle(topic.title)
            } else {
                ContentUnavailableView("主题不存在", systemImage: "questionmark.folder")
            }
        }
    }

    private var adaptiveSnapshot: AdaptiveLearningSnapshot {
        AdaptiveLearningService.snapshot(
            tutorials: tutorials,
            concepts: concepts,
            masteryRecords: masteryRecords,
            progressRecords: progressRecords
        )
    }

    private func readiness(for tutorial: Tutorial) -> AdaptiveTutorialReadiness? {
        adaptiveSnapshot.items.first { $0.tutorial.id == tutorial.id }
    }

    private func topicReadinessCard(_ topic: Topic) -> some View {
        let items = topic.tutorials.compactMap(readiness)
        let average = items.isEmpty ? 0 : items.reduce(0) { $0 + ($1.level == .completed ? 1 : $1.score) } / Double(items.count)
        let ready = items.filter { $0.level == .ready }.count
        let bridges = items.filter { $0.level == .nearlyReady || $0.level == .needsBridge }.count

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("自适应就绪度", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.headline)
                Spacer()
                Text("\(Int(average * 100))%")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(.indigo)
            }
            LearningProgressBar(value: average, tint: .indigo)
            HStack {
                StatPill(icon: "play.circle.fill", text: "\(ready) 可开始", tint: .indigo)
                StatPill(icon: "arrow.triangle.branch", text: "\(bridges) 需补桥", tint: .orange)
                Spacer()
            }
        }
        .learningCard()
    }

    @ViewBuilder
    private func learningAdviceCard(_ topic: Topic) -> some View {
        let firstBridge = topic.tutorials
            .compactMap(readiness)
            .first { $0.level == .nearlyReady || $0.level == .needsBridge }

        if let firstBridge {
            VStack(alignment: .leading, spacing: 10) {
                Label("学习顺序建议", systemImage: "arrow.triangle.branch")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Text(firstBridge.reason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)

                if !firstBridge.missingConcepts.isEmpty {
                    Text("待补概念")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(firstBridge.missingConcepts) { readiness in
                                NavigationLink(value: AppRoute.concept(readiness.concept.id)) {
                                    Text("\(readiness.concept.name) · \(Int(readiness.score * 100))%")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 6)
                                        .background(.orange.opacity(0.1), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if let remediation = firstBridge.remediationTutorials.first {
                    NavigationLink(value: AppRoute.tutorial(remediation.id)) {
                        Label("先学习：\(remediation.title)", systemImage: "book.pages.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                }
            }
            .learningCard()
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    private func completed(_ itemID: String) -> Bool {
        progressRecords.contains { $0.itemID == itemID && $0.isCompleted }
    }
}

private struct ContentRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let done: Bool
    var readiness: AdaptiveTutorialReadiness?

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: done ? "checkmark.circle.fill" : icon)
                .font(.title3)
                .foregroundStyle(done ? .green : .accentColor)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if let readiness {
                    HStack(spacing: 6) {
                        Label(readiness.level.title, systemImage: readiness.level.icon)
                        if !readiness.missingConcepts.isEmpty {
                            Text("\(readiness.missingConcepts.count) 项前置待补")
                        } else {
                            Text("\(Int(readiness.score * 100))% 就绪")
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(readinessColor(readiness.level))
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .learningCard()
    }

    private func readinessColor(_ level: AdaptiveReadinessLevel) -> Color {
        switch level {
        case .completed: .green
        case .ready: .indigo
        case .nearlyReady: .orange
        case .needsBridge: .red
        }
    }
}
