import SwiftData
import SwiftUI

struct CodeReadingCenterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressRecords: [Progress]
    @Query private var reviewItems: [ReviewItem]

    @State private var selectedFocus = "全部"
    @State private var answers: [String: Int] = [:]

    private var focuses: [String] {
        ["全部"] + Array(Set(CodeReadingCatalog.exercises.map(\.focus))).sorted()
    }

    private var exercises: [CodeReadingExercise] {
        selectedFocus == "全部"
            ? CodeReadingCatalog.exercises
            : CodeReadingCatalog.exercises.filter { $0.focus == selectedFocus }
    }

    private var completedCount: Int {
        CodeReadingCatalog.exercises.filter { exercise in
            progressRecords.contains {
                $0.itemID == itemID(exercise) && $0.isCompleted
            }
        }.count
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                header
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(focuses, id: \.self) { focus in
                            Button {
                                selectedFocus = focus
                            } label: {
                                Text(focus)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 7)
                                    .background(
                                        selectedFocus == focus ? Color.indigo : Color.secondary.opacity(0.09),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(selectedFocus == focus ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                ForEach(exercises) { exercise in
                    exerciseCard(exercise)
                }
            }
            .padding()
            .learningPageWidth()
        }
        .background(Color.appBackground)
        .navigationTitle("代码阅读训练")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("代码阅读、错误定位与输出预测", systemImage: "doc.text.magnifyingglass")
                    .font(.title3.bold())
                Spacer()
                Text("\(completedCount)/\(CodeReadingCatalog.exercises.count)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(.indigo)
            }
            Text("不要只运行代码。先阅读、预测、找出错误，再查看解释。错误题目会自动进入复习计划。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
            LearningProgressBar(
                value: CodeReadingCatalog.exercises.isEmpty ? 0 : Double(completedCount) / Double(CodeReadingCatalog.exercises.count),
                tint: .indigo
            )
        }
        .learningCard()
    }

    private func exerciseCard(_ exercise: CodeReadingExercise) -> some View {
        let selected = answers[exercise.id]
        let isCorrect = selected == exercise.correctIndex
        let completed = progressRecords.contains {
            $0.itemID == itemID(exercise) && $0.isCompleted
        }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.title)
                        .font(.headline)
                    Text("\(exercise.focus) · \(exercise.language.uppercased())")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.indigo)
                }
                Spacer()
                if completed {
                    Label("已掌握", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }

            CodeBlockView(code: exercise.code, language: exercise.language)

            Text(exercise.prompt)
                .font(.subheadline.weight(.semibold))

            ForEach(Array(exercise.options.enumerated()), id: \.offset) { index, option in
                Button {
                    select(index, for: exercise)
                } label: {
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: optionIcon(index, selected: selected, correctIndex: exercise.correctIndex))
                            .foregroundStyle(optionColor(index, selected: selected, correctIndex: exercise.correctIndex))
                        Text(option)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(10)
                    .background(
                        optionBackground(index, selected: selected, correctIndex: exercise.correctIndex),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .buttonStyle(.plain)
            }

            if let selected {
                VStack(alignment: .leading, spacing: 6) {
                    Label(isCorrect ? "判断正确" : "需要重新分析", systemImage: isCorrect ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(isCorrect ? .green : .orange)
                    Text(exercise.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                .padding(11)
                .background((isCorrect ? Color.green : Color.orange).opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .learningCard()
    }

    private func select(_ index: Int, for exercise: CodeReadingExercise) {
        guard answers[exercise.id] == nil else { return }
        answers[exercise.id] = index
        let correct = index == exercise.correctIndex

        ProgressService.setCompleted(
            correct,
            itemID: itemID(exercise),
            score: correct ? 1 : 0,
            in: modelContext
        )
        MasteryService.recordText(
            "\(exercise.title) \(exercise.prompt) \(exercise.explanation)",
            positive: correct,
            reason: correct ? "代码阅读分析正确" : "代码阅读分析错误",
            in: modelContext
        )

        if !correct {
            addToReview(exercise)
        }
    }

    private func addToReview(_ exercise: CodeReadingExercise) {
        let sourceID = "code-reading:\(exercise.id)"
        if let existing = reviewItems.first(where: { $0.sourceID == sourceID }) {
            existing.isArchived = false
            existing.dueAt = .now
            try? modelContext.save()
            return
        }

        modelContext.insert(
            ReviewItem(
                id: "review:\(sourceID)",
                sourceType: "code-reading",
                sourceID: sourceID,
                title: exercise.title,
                question: exercise.prompt,
                referenceAnswer: exercise.options[exercise.correctIndex],
                explanation: exercise.explanation,
                dueAt: .now
            )
        )
        try? modelContext.save()
    }

    private func itemID(_ exercise: CodeReadingExercise) -> String {
        "code-reading:\(exercise.id)"
    }

    private func optionIcon(_ index: Int, selected: Int?, correctIndex: Int) -> String {
        guard let selected else { return "circle" }
        if index == correctIndex { return "checkmark.circle.fill" }
        if index == selected { return "xmark.circle.fill" }
        return "circle"
    }

    private func optionColor(_ index: Int, selected: Int?, correctIndex: Int) -> Color {
        guard let selected else { return .secondary }
        if index == correctIndex { return .green }
        if index == selected { return .red }
        return .secondary
    }

    private func optionBackground(_ index: Int, selected: Int?, correctIndex: Int) -> Color {
        guard let selected else { return Color.secondary.opacity(0.06) }
        if index == correctIndex { return Color.green.opacity(0.1) }
        if index == selected { return Color.red.opacity(0.1) }
        return Color.secondary.opacity(0.05)
    }
}
