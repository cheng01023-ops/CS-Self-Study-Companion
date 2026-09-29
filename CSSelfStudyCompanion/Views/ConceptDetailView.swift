import SwiftData
import SwiftUI

struct ConceptDetailView: View {
    @Query(sort: \Concept.name) private var concepts: [Concept]
    @Query(sort: \Tutorial.order) private var tutorials: [Tutorial]
    @Query(sort: \MasteryRecord.score) private var masteryRecords: [MasteryRecord]

    let conceptID: String

    private var concept: Concept? {
        concepts.first { $0.id == conceptID }
    }

    var body: some View {
        Group {
            if let concept {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(concept.category, systemImage: "tag.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.indigo)
                            Text(concept.name)
                                .font(.largeTitle.bold())
                            Text(concept.summary)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .lineSpacing(4)
                        }
                        .learningCard()

                        masteryCard(concept)
                        prerequisiteCard(concept)
                        MarkdownText(markdown: concept.details)

                        relatedTutorials(concept)
                        relatedConcepts(concept)
                    }
                    .padding()
                    .learningPageWidth()
                }
                .background(Color.appBackground)
                .navigationTitle(concept.name)
            } else {
                ContentUnavailableView("概念不存在", systemImage: "questionmark.circle")
            }
        }
    }

    @ViewBuilder
    private func prerequisiteCard(_ concept: Concept) -> some View {
        let prerequisites = concepts.filter {
            ConceptDependencyCatalog.prerequisites(for: concept.id).contains($0.id)
        }
        if !prerequisites.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("建议先掌握", systemImage: "arrow.up.right.circle")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Text("如果下面的概念还不熟悉，建议先回看对应教程，再学习当前内容。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    ForEach(prerequisites) { prerequisite in
                        NavigationLink(value: AppRoute.concept(prerequisite.id)) {
                            Text(prerequisite.name)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(.orange.opacity(0.1), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .learningCard()
        }
    }

    @ViewBuilder
    private func masteryCard(_ concept: Concept) -> some View {
        let record = masteryRecords.first { $0.conceptID == concept.id }

        if let record, record.attempts > 0 {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("我的掌握度", systemImage: "brain.head.profile")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(record.score * 100))%")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(record.score >= 0.72 ? .green : .orange)
                }
                LearningProgressBar(
                    value: record.score,
                    tint: record.score >= 0.72 ? .green : .orange
                )
                HStack {
                    Text(MasteryService.masteryLabel(record.score))
                    Spacer()
                    Text("正确 \(record.correctCount) · 需复习 \(record.wrongCount)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Text("最近依据：\(record.lastReason)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .learningCard()
        }
    }

    private func relatedTutorials(_ concept: Concept) -> some View {
        let related = tutorials.filter { concept.relatedTutorialIDs.contains($0.id) }
        return VStack(alignment: .leading, spacing: 10) {
            Text("相关教程")
                .font(.title3.bold())
            ForEach(related) { tutorial in
                NavigationLink(value: AppRoute.tutorial(tutorial.id)) {
                    HStack(spacing: 12) {
                        Image(systemName: "book.pages.fill")
                            .foregroundStyle(.indigo)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(tutorial.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(tutorial.summary)
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
        }
    }

    private func relatedConcepts(_ concept: Concept) -> some View {
        let related = concepts.filter { $0.category == concept.category && $0.id != concept.id }.prefix(6)
        return VStack(alignment: .leading, spacing: 10) {
            Text("同类概念")
                .font(.title3.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Array(related)) { item in
                        NavigationLink(value: AppRoute.concept(item.id)) {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.indigo.opacity(0.1), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
