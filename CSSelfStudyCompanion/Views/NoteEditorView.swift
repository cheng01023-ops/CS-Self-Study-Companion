import SwiftData
import SwiftUI

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var notes: [LearningNote]

    let targetID: String
    let parentTutorialID: String?
    let stepIndex: Int?
    let title: String

    @State private var bodyText = ""
    @State private var didLoad = false

    private var existingNote: LearningNote? {
        notes.first { $0.targetID == targetID }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline)
                    Text("记录自己的理解、疑问、实验结果和待复习内容。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TextEditor(text: $bodyText)
                    .font(.body)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .frame(minHeight: 220)

                HStack {
                    if existingNote != nil {
                        Button(role: .destructive) {
                            if let existingNote {
                                KnowledgeService.deleteNote(existingNote, in: modelContext)
                            }
                            dismiss()
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }

                    Spacer()

                    Button("取消") {
                        dismiss()
                    }

                    Button("保存") {
                        KnowledgeService.saveNote(
                            targetID: targetID,
                            parentTutorialID: parentTutorialID,
                            stepIndex: stepIndex,
                            title: title,
                            body: bodyText,
                            in: modelContext
                        )
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
            .navigationTitle("学习笔记")
            .onAppear {
                guard !didLoad else { return }
                bodyText = existingNote?.body ?? ""
                didLoad = true
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 430)
        #endif
    }
}
