import SwiftData
import SwiftUI

private enum PracticeStudioMode: String, CaseIterable, Identifiable {
    case training
    case heatmap

    var id: String { rawValue }

    var title: String {
        switch self {
        case .training: "动态训练"
        case .heatmap: "掌握热力图"
        }
    }

    var icon: String {
        switch self {
        case .training: "bolt.fill"
        case .heatmap: "square.grid.3x3.fill"
        }
    }
}

struct PracticeStudioView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Concept.name) private var concepts: [Concept]
    @Query(sort: \MasteryRecord.score) private var masteryRecords: [MasteryRecord]
    @Query(sort: \Tutorial.order) private var tutorials: [Tutorial]
    @Query private var progressRecords: [Progress]

    @State private var mode: PracticeStudioMode = .training
    @State private var questions: [DynamicPracticeQuestion] = []
    @State private var currentIndex = 0
    @State private var selectedOption: String?
    @State private var isAnswered = false
    @State private var correctCount = 0
    @State private var finished = false
    @State private var sessionSeed: UInt64 = 1

    private var currentQuestion: DynamicPracticeQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    private var weakCount: Int {
        masteryRecords.filter { $0.attempts > 0 && $0.score < 0.72 }.count
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                header
                modePicker

                switch mode {
                case .training:
                    trainingContent
                case .heatmap:
                    MasteryHeatmapContent(
                        concepts: concepts,
                        masteryRecords: masteryRecords,
                        tutorials: tutorials,
                        progressRecords: progressRecords
                    )
                }
            }
            .padding()
            .learningPageWidth(maxWidth: 1080)
        }
        .background(Color.appBackground)
        .navigationTitle("练习与掌握度")
        .onAppear {
            if questions.isEmpty {
                startSession()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Label("动态练习与掌握度", systemImage: "bolt.circle.fill")
                        .font(.title3.bold())
                    Text("系统会优先抽取薄弱概念，生成一组不同主题的练习题，避免连续重复单一知识点。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
                Spacer()
                Image(systemName: "waveform.path.ecg.rectangle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange.opacity(0.75))
            }

            HStack {
                StatPill(icon: "target", text: "\(weakCount) 个薄弱概念", tint: .orange)
                StatPill(icon: "arrow.triangle.2.circlepath", text: "间隔训练", tint: .teal)
                StatPill(icon: "chart.bar.fill", text: "\(concepts.count) 个概念", tint: .indigo)
            }
        }
        .learningCard()
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(PracticeStudioMode.allCases) { item in
                Button {
                    mode = item
                } label: {
                    Label(item.title, systemImage: item.icon)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(mode == item ? Color.orange : Color.secondary.opacity(0.08), in: Capsule())
                        .foregroundStyle(mode == item ? .white : .primary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(item == .training ? "practice-training-mode" : "mastery-heatmap-mode")
            }
        }
    }

    @ViewBuilder
    private var trainingContent: some View {
        if finished {
            sessionSummary
        } else if let question = currentQuestion {
            questionCard(question)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("暂时没有可用于动态生成的概念。")
                    .font(.headline)
                Text("先完成一些教程和练习，系统会把概念加入训练池。")
                    .foregroundStyle(.secondary)
            }
            .learningCard()
        }
    }

    private func questionCard(_ question: DynamicPracticeQuestion) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("第 \(currentIndex + 1)/\(questions.count) 题", systemImage: "number")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
                Spacer()
                Text(question.difficulty)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(question.conceptName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.indigo)
            }

            Text(question.title)
                .font(.title3.bold())
            Text(question.prompt)
                .font(.body)
                .lineSpacing(4)

            if let code = question.code {
                CodeBlockView(code: code, language: "text")
            }

            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                Button {
                    choose(option, question: question)
                } label: {
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: optionIcon(index, question: question))
                            .foregroundStyle(optionColor(index, question: question))
                        Text(option)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(10)
                    .background(optionBackground(index, question: question), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(isAnswered)
            }

            if isAnswered {
                VStack(alignment: .leading, spacing: 7) {
                    Label(isCorrect ? "回答正确" : "需要重新分析", systemImage: isCorrect ? "checkmark.circle.fill" : "lightbulb.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(isCorrect ? .green : .orange)
                    Text(question.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                .padding(11)
                .background((isCorrect ? Color.green : Color.orange).opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

                Button {
                    nextQuestion()
                } label: {
                    Label(currentIndex + 1 == questions.count ? "查看训练结果" : "下一题", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .learningCard()
        .accessibilityIdentifier("dynamic-practice-question")
    }

    private var sessionSummary: some View {
        let accuracy = questions.isEmpty ? 0 : Double(correctCount) / Double(questions.count)
        return VStack(alignment: .leading, spacing: 13) {
            HStack {
                Label("训练完成", systemImage: "checkmark.seal.fill")
                    .font(.title3.bold())
                    .foregroundStyle(.green)
                Spacer()
                Text("\(Int(accuracy * 100))%")
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(accuracy >= 0.7 ? .green : .orange)
            }
            Text("本轮完成 \(questions.count) 题，答对 \(correctCount) 题。错题和薄弱概念已进入复习和掌握度记录。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
            LearningProgressBar(value: accuracy, tint: accuracy >= 0.7 ? .green : .orange)

            HStack {
                Button {
                    startSession()
                } label: {
                    Label("再练一组", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button {
                    mode = .heatmap
                } label: {
                    Label("查看热力图", systemImage: "square.grid.3x3.fill")
                }
                .buttonStyle(.bordered)
            }
        }
        .learningCard()
    }

    private func choose(_ option: String, question: DynamicPracticeQuestion) {
        guard !isAnswered else { return }
        selectedOption = option
        isAnswered = true
        let correct = option == question.options[question.correctIndex]
        if correct { correctCount += 1 }

        MasteryService.recordConceptPractice(
            conceptID: question.conceptID,
            positive: correct,
            reason: correct ? "动态练习回答正确" : "动态练习回答错误",
            in: modelContext
        )
        ReviewService.scheduleConceptPractice(
            conceptID: question.conceptID,
            title: question.conceptName,
            question: question.prompt,
            referenceAnswer: question.options[question.correctIndex],
            needsReview: !correct,
            in: modelContext
        )
    }

    private func nextQuestion() {
        if currentIndex + 1 < questions.count {
            currentIndex += 1
            selectedOption = nil
            isAnswered = false
        } else {
            finished = true
        }
    }

    private func startSession() {
        sessionSeed = sessionSeed &+ 1
        questions = AdaptivePracticeService.generateSession(
            concepts: concepts,
            masteryRecords: masteryRecords,
            count: min(5, max(3, concepts.isEmpty ? 3 : concepts.count)),
            seed: sessionSeed
        )
        currentIndex = 0
        selectedOption = nil
        isAnswered = false
        correctCount = 0
        finished = false
    }

    private var isCorrect: Bool {
        guard let question = currentQuestion, let selectedOption else { return false }
        return selectedOption == question.options[question.correctIndex]
    }

    private func optionIcon(_ index: Int, question: DynamicPracticeQuestion) -> String {
        guard isAnswered else { return "circle" }
        if index == question.correctIndex { return "checkmark.circle.fill" }
        if question.options[index] == selectedOption { return "xmark.circle.fill" }
        return "circle"
    }

    private func optionColor(_ index: Int, question: DynamicPracticeQuestion) -> Color {
        guard isAnswered else { return .secondary }
        if index == question.correctIndex { return .green }
        if question.options[index] == selectedOption { return .red }
        return .secondary
    }

    private func optionBackground(_ index: Int, question: DynamicPracticeQuestion) -> Color {
        guard isAnswered else { return Color.secondary.opacity(0.06) }
        if index == question.correctIndex { return Color.green.opacity(0.1) }
        if question.options[index] == selectedOption { return Color.red.opacity(0.1) }
        return Color.secondary.opacity(0.05)
    }
}

private struct MasteryHeatmapContent: View {
    let concepts: [Concept]
    let masteryRecords: [MasteryRecord]
    let tutorials: [Tutorial]
    let progressRecords: [Progress]

    private var grouped: [(String, [Concept])] {
        Dictionary(grouping: concepts, by: \.category)
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label("掌握度热力图", systemImage: "square.grid.3x3.fill")
                    .font(.title3.bold())
                Text("颜色越接近绿色，说明掌握越稳；灰色表示还没有练习或复习证据。点击任意方块进入概念详情。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                legend
            }
            .learningCard()

            ForEach(Array(grouped.enumerated()), id: \.offset) { _, group in
                let category = group.0
                let items = group.1
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(category)
                            .font(.headline)
                        Spacer()
                        Text("\(items.count) 个")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 120), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(items) { concept in
                            NavigationLink(value: AppRoute.concept(concept.id)) {
                                heatmapTile(concept)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .learningCard()
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 8) {
            legendItem("未练习", color: .secondary.opacity(0.18))
            legendItem("待加强", color: .red)
            legendItem("学习中", color: .orange)
            legendItem("理解", color: .yellow)
            legendItem("熟练", color: .green)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private func legendItem(_ title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(title)
        }
    }

    private func heatmapTile(_ concept: Concept) -> some View {
        let score = inferredScore(concept)
        let color = heatmapColor(score)
        return VStack(alignment: .leading, spacing: 6) {
            Text(concept.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
            Spacer(minLength: 4)
            Text(score == nil ? "未练习" : "\(Int((score ?? 0) * 100))%")
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(score == nil ? .secondary : color)
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .padding(11)
        .background(color.opacity(score == nil ? 0.12 : 0.16), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.25), lineWidth: 1)
        }
    }

    private func inferredScore(_ concept: Concept) -> Double? {
        let record = masteryRecords.first { $0.conceptID == concept.id }
        if let record, record.attempts > 0 {
            return record.score
        }
        let completedTutorialIDs = Set(
            tutorials
                .filter { tutorial in
                    progressRecords.contains {
                        $0.itemID == .tutorialProgressID(tutorial.id) && $0.isCompleted
                    }
                }
                .map(\.id)
        )
        let hasCompletedRelatedTutorial = concept.relatedTutorialIDs.contains {
            completedTutorialIDs.contains($0)
        }
        guard hasCompletedRelatedTutorial else { return nil }

        let tutorialMap = Dictionary(uniqueKeysWithValues: tutorials.map { ($0.id, $0) })
        return AdaptiveLearningService.inferredConceptScore(
            concept,
            mastery: record,
            tutorialMap: tutorialMap,
            completedTutorialIDs: completedTutorialIDs
        )
    }

    private func heatmapColor(_ score: Double?) -> Color {
        guard let score else { return .secondary }
        switch score {
        case 0.85...: return .green
        case 0.65..<0.85: return .yellow
        case 0.4..<0.65: return .orange
        default: return .red
        }
    }
}
