import SwiftUI

struct OnboardingDiagnosticView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("recommendedStartStage") private var recommendedStartStage = 0
    @AppStorage("hasCompletedDiagnostic") private var hasCompletedDiagnostic = false

    @State private var answers = Array(repeating: 0, count: questions.count)

    private static let questions: [DiagnosticQuestion] = [
        DiagnosticQuestion(title: "你使用过终端或命令行吗？", options: ["几乎没有", "会基本目录和文件命令", "熟练使用管道、权限和 Git"]),
        DiagnosticQuestion(title: "你写过 C 语言吗？", options: ["没有", "会变量、循环和函数", "理解指针、数组和结构体"]),
        DiagnosticQuestion(title: "你接触过 Linux 吗？", options: ["没有", "安装并使用过 Ubuntu", "会用户、权限、服务和 Shell 脚本"]),
        DiagnosticQuestion(title: "你了解数据结构与算法吗？", options: ["不太了解", "知道数组、链表和排序", "理解复杂度、树、图和哈希"]),
        DiagnosticQuestion(title: "你知道程序如何与操作系统交互吗？", options: ["不了解", "知道进程和文件", "理解系统调用、线程、内存和网络"]),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("先确定你的起点")
                            .font(.title2.bold())
                        Text("这不是考试，只需要选择最接近当前情况的答案。系统会推荐一个起始阶段，之后仍可自由调整。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .learningCard()

                    ForEach(Array(Self.questions.enumerated()), id: \.offset) { index, question in
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(index + 1). \(question.title)")
                                .font(.headline)
                            ForEach(Array(question.options.enumerated()), id: \.offset) { optionIndex, option in
                                Button {
                                    answers[index] = optionIndex
                                } label: {
                                    HStack {
                                        Image(systemName: answers[index] == optionIndex ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(answers[index] == optionIndex ? .indigo : .secondary)
                                        Text(option)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                    }
                                    .padding(11)
                                    .background(
                                        answers[index] == optionIndex ? Color.indigo.opacity(0.1) : Color.secondary.opacity(0.06),
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .learningCard()
                    }
                }
                .padding()
                .learningPageWidth()
            }
            .background(Color.appBackground)
            .navigationTitle("入学诊断")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("跳过") {
                        recommendedStartStage = 0
                        hasCompletedDiagnostic = true
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("生成路线") {
                        let score = answers.reduce(0, +)
                        recommendedStartStage = StudyPlanService.recommendedStageOrder(for: score)
                        hasCompletedDiagnostic = true
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 620, minHeight: 760)
        #endif
    }
}

private struct DiagnosticQuestion {
    let title: String
    let options: [String]
}
