import SwiftData
import SwiftUI

struct CodeExerciseWorkspaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var drafts: [CodeDraft]

    let exercise: Exercise

    @State private var sourceCode = ""
    @State private var input = ""
    @State private var selectedTestCaseIndex = 0
    @State private var result: CodeRunResult?
    @State private var isRunning = false
    @State private var didLoad = false

    private var spec: CodeExerciseSpec? {
        CodeExerciseCatalog.spec(for: exercise.id)
    }

    private var testCases: [CodeTestCase] {
        spec?.testCases ?? []
    }

    private var currentTestCase: CodeTestCase? {
        guard testCases.indices.contains(selectedTestCaseIndex) else { return nil }
        return testCases[selectedTestCaseIndex]
    }

    private var draft: CodeDraft? {
        drafts.first { $0.exerciseID == exercise.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("代码工作台", systemImage: "hammer.fill")
                    .font(.title3.bold())
                Spacer()
                HStack(spacing: 8) {
                    Text("\(sourceCode.components(separatedBy: .newlines).count) 行")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Label(bracketsBalanced ? "括号平衡" : "括号不平衡", systemImage: bracketsBalanced ? "checkmark.circle" : "exclamationmark.triangle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(bracketsBalanced ? .green : .orange)
                    Text(exercise.codeLanguage.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.indigo)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.indigo.opacity(0.1), in: Capsule())
                }
            }

            TextEditor(text: $sourceCode)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color(hex: "10131A"), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
                .frame(minHeight: 280)

            if !testCases.isEmpty {
                Picker("测试用例", selection: $selectedTestCaseIndex) {
                    ForEach(Array(testCases.enumerated()), id: \.offset) { index, testCase in
                        Text(testCase.name).tag(index)
                    }
                }
                .pickerStyle(.segmented)

                if let currentTestCase {
                    VStack(alignment: .leading, spacing: 7) {
                        Label("输入", systemImage: "arrow.down.doc")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        TextEditor(text: $input)
                            .font(.system(.caption, design: .monospaced))
                            .frame(minHeight: 58)
                            .padding(7)
                            .scrollContentBackground(.hidden)
                            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))

                        Text("预期输出：\(currentTestCase.expectedOutput.isEmpty ? "无输出" : currentTestCase.expectedOutput)")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            } else {
                Label("当前题目暂未配置自动判题，可以编辑并复制代码，或查看参考答案。", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            HStack {
                Button {
                    sourceCode = exercise.starterCode
                    input = spec?.primaryTestCase?.input ?? ""
                    result = nil
                    saveDraft(passed: false)
                } label: {
                    Label("重置", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)

                CopyButton(text: sourceCode)

                Spacer()

                if let testCase = currentTestCase {
                    Text(testCase.expectedOutput.isEmpty ? "无预期输出" : "自动比较输出")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    run()
                } label: {
                    if isRunning {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("编译并运行", systemImage: "play.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [.command])
                .help("Command + Return 编译并运行")
                .disabled(isRunning || spec == nil)
            }

            if let result {
                resultView(result)
            } else if let draft, draft.passed {
                Label("上次运行已通过", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
        .padding(16)
        .background(.indigo.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.indigo.opacity(0.14), lineWidth: 1)
        }
        .onAppear {
            guard !didLoad else { return }
            sourceCode = draft?.sourceCode ?? exercise.starterCode
            input = draft?.input ?? spec?.primaryTestCase?.input ?? ""
            didLoad = true
        }
        .onChange(of: sourceCode) { _, _ in
            saveDraft(passed: draft?.passed ?? false)
        }
        .onChange(of: input) { _, _ in
            saveDraft(passed: draft?.passed ?? false)
        }
    }

    private var bracketsBalanced: Bool {
        var round = 0
        var square = 0
        var curly = 0
        var inString = false
        var escaped = false

        for character in sourceCode {
            if inString {
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == "\"" {
                    inString = false
                }
                continue
            }

            switch character {
            case "\"":
                inString = true
            case "(":
                round += 1
            case ")":
                round -= 1
            case "[":
                square += 1
            case "]":
                square -= 1
            case "{":
                curly += 1
            case "}":
                curly -= 1
            default:
                break
            }

            if round < 0 || square < 0 || curly < 0 {
                return false
            }
        }

        return round == 0 && square == 0 && curly == 0 && !inString
    }

    private func run() {
        guard let testCase = currentTestCase else { return }
        isRunning = true
        result = nil

        Task {
            let runResult = await CodeExecutionService.run(
                code: sourceCode,
                language: spec?.language ?? exercise.codeLanguage,
                input: input,
                arguments: testCase.arguments,
                expectedOutput: testCase.expectedOutput
            )

            await MainActor.run {
                result = runResult
                isRunning = false
                saveDraft(passed: runResult.passed)
                MasteryService.recordCodeResult(exercise, passed: runResult.passed, in: modelContext)
            }
        }
    }

    private func resultView(_ result: CodeRunResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                result.message,
                systemImage: result.passed ? "checkmark.seal.fill" : result.succeeded ? "exclamationmark.triangle.fill" : "xmark.octagon.fill"
            )
            .font(.headline)
            .foregroundStyle(result.passed ? .green : result.succeeded ? .orange : .red)

            if !result.stdout.isEmpty {
                outputBlock(title: "标准输出", value: result.stdout, tint: .green)
            }

            if !result.stderr.isEmpty {
                outputBlock(title: "标准错误", value: result.stderr, tint: .red)
            }

            Text("退出码：\(result.exitCode)\(result.timedOut ? " · 已超时" : "")")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }

    private func outputBlock(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(tint)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(9)
                .background(Color(hex: "10131A"), in: RoundedRectangle(cornerRadius: 9))
                .foregroundStyle(.white)
        }
    }

    private func saveDraft(passed: Bool) {
        CodeDraftService.save(
            exerciseID: exercise.id,
            sourceCode: sourceCode,
            input: input,
            output: result?.stdout ?? "",
            error: result?.stderr ?? "",
            passed: passed,
            in: modelContext
        )
    }
}
