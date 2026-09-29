import SwiftData
import SwiftUI

struct TopicDetailView: View {
    @Query(sort: \Topic.order) private var topics: [Topic]
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

                        if !topic.tutorials.isEmpty {
                            sectionTitle("教程")
                            ForEach(topic.tutorials.sorted(by: { $0.order < $1.order })) { tutorial in
                                NavigationLink(value: AppRoute.tutorial(tutorial.id)) {
                                    ContentRow(
                                        icon: "book.pages",
                                        title: tutorial.title,
                                        subtitle: tutorial.summary,
                                        done: completed(.tutorialProgressID(tutorial.id))
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
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .learningCard()
    }
}
