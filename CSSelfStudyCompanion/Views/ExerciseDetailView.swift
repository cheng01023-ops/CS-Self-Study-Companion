import SwiftData
import SwiftUI

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.order) private var exercises: [Exercise]
    @Query private var progressRecords: [Progress]
    @Query private var reviewItems: [ReviewItem]

    let exerciseID: String

    @State private var selectedOption: String?
    @State private var showReference = false

    private var exercise: Exercise? {
        exercises.first { $0.id == exerciseID }
    }

    private var itemID: String {
        .exerciseProgressID(exerciseID)
    }

    private var isCompleted: Bool {
        progressRecords.contains { $0.itemID == itemID && $0.isCompleted }
    }

    var body: some View {
        Group {
            if let exercise {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        questionCard(exercise)

                        if exercise.kind == .multipleChoice {
                            options(exercise)
                            answerControls(exercise)
                        } else {
                            codingExercise(exercise)
                        }
                    }
                    .padding()
                    .learningPageWidth()
                }
                .background(Color.appBackground)
                .navigationTitle(exercise.title)
            } else {
                ContentUnavailableView("练习不存在", systemImage: "pencil.slash")
            }
        }
    }

    private func questionCard(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatPill(icon: "pencil.and.list.clipboard", text: exercise.kind.title)
                if isCompleted {
                    StatPill(icon: "checkmark.circle.fill", text: "已完成", tint: .green)
                }
            }
            Text(exercise.question)
                .font(.title3.weight(.semibold))
                .lineSpacing(5)
                .textSelection(.enabled)

            if exercise.kind == .coding, !exercise.starterCode.isEmpty {
                CodeBlockView(code: exercise.starterCode, language: exercise.codeLanguage)
            }
        }
        .learningCard()
    }

    private func options(_ exercise: Exercise) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(exercise.options.enumerated()), id: \.offset) { index, option in
                Button {
                    selectedOption = option
                    recordAttempt(option, exercise: exercise)
                } label: {
                    HStack(spacing: 12) {
                        Text(optionLetter(index))
                            .font(.subheadline.bold())
                            .foregroundStyle(selectedOption == option ? .white : .indigo)
                            .frame(width: 30, height: 30)
                            .background(selectedOption == option ? Color.indigo : Color.indigo.opacity(0.1), in: Circle())

                        Text(option)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if selectedOption == option, option == exercise.answer {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else if selectedOption == option {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                    .learningCard()
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func answerControls(_ exercise: Exercise) -> some View {
        if let selectedOption {
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    selectedOption == exercise.answer ? "回答正确" : "再想一想",
                    systemImage: selectedOption == exercise.answer ? "checkmark.seal.fill" : "lightbulb"
                )
                .font(.headline)
                .foregroundStyle(selectedOption == exercise.answer ? .green : .orange)

                Text(exercise.explanation)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)

                if selectedOption == exercise.answer {
                    completionButton(score: 1)
                } else {
                    Button("查看提示") {
                        showReference = true
                    }
                    .buttonStyle(.bordered)

                    if showReference {
                        Text("正确答案：\(exercise.answer)")
                            .font(.subheadline.weight(.semibold))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .learningCard()
        }
    }

    private func codingExercise(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("在代码工作台中实现并运行测试。没有自动判题的题目，可以复制到外部编辑器继续练习。")
                .foregroundStyle(.secondary)

            CodeExerciseWorkspaceView(exercise: exercise)

            Button {
                withAnimation {
                    showReference.toggle()
                }
            } label: {
                Label(showReference ? "收起参考答案" : "查看参考答案", systemImage: "chevron.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if showReference {
                CodeBlockView(code: exercise.answer, language: exercise.codeLanguage)
                Text(exercise.explanation)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)

                if reviewItem(for: exercise) == nil {
                    Button {
                        ReviewService.addCodingExercise(exercise: exercise, in: modelContext)
                    } label: {
                        Label("加入错题本", systemImage: "bookmark.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                } else {
                    Label("已加入错题本", systemImage: "bookmark.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                }

                completionButton(score: 1)
            }
        }
        .learningCard()
    }

    private func completionButton(score: Double) -> some View {
        Button {
            ProgressService.setCompleted(!isCompleted, itemID: itemID, score: score, in: modelContext)
        } label: {
            Label(
                isCompleted ? "标记为未完成" : "完成本题",
                systemImage: isCompleted ? "arrow.uturn.backward" : "checkmark.circle.fill"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(isCompleted ? .secondary : .green)
    }

    private func reviewItem(for exercise: Exercise) -> ReviewItem? {
        let sourceID = String.exerciseProgressID(exercise.id)
        return reviewItems.first { $0.sourceID == sourceID && !$0.isArchived }
    }

    private func recordAttempt(_ option: String, exercise: Exercise) {
        MasteryService.recordExercise(exercise, correct: option == exercise.answer, in: modelContext)

        if option == exercise.answer {
            if let item = reviewItem(for: exercise) {
                ReviewService.review(item, remembered: true, in: modelContext)
            }
        } else {
            ReviewService.recordWrongExercise(exercise: exercise, userAnswer: option, in: modelContext)
        }
    }

    private func optionLetter(_ index: Int) -> String {
        String(UnicodeScalar(65 + index)!)
    }
}
