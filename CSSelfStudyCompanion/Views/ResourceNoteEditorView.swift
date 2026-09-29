import SwiftUI

struct ResourceNoteEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    @State private var bodyText: String
    let onSave: (String) -> Void

    init(title: String, initialBody: String, onSave: @escaping (String) -> Void) {
        self.title = title
        _bodyText = State(initialValue: initialBody)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.headline)
                TextEditor(text: $bodyText)
                    .frame(minHeight: 260)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                Text("记录这份资源最值得保留的内容、疑问和实验结论。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("资源笔记")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(bodyText)
                        dismiss()
                    }
                    .disabled(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 560, minHeight: 460)
        #endif
    }
}
