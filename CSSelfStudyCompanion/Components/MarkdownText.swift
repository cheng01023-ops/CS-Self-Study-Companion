import SwiftUI

struct MarkdownText: View {
    let markdown: String

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var blocks: [MarkdownBlock] {
        var result: [MarkdownBlock] = []
        var paragraphLines: [String] = []

        func flushParagraph() {
            guard !paragraphLines.isEmpty else { return }
            result.append(.paragraph(paragraphLines.joined(separator: "\n")))
            paragraphLines.removeAll()
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flushParagraph()
            } else if line.hasPrefix("### ") {
                flushParagraph()
                result.append(.heading(String(line.dropFirst(4)), level: 3))
            } else if line.hasPrefix("## ") {
                flushParagraph()
                result.append(.heading(String(line.dropFirst(3)), level: 2))
            } else if line.hasPrefix("# ") {
                flushParagraph()
                result.append(.heading(String(line.dropFirst(2)), level: 1))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                flushParagraph()
                result.append(.bullet(String(line.dropFirst(2))))
            } else if line.first?.isNumber == true, line.contains(". ") {
                flushParagraph()
                result.append(.numbered(line))
            } else {
                paragraphLines.append(rawLine)
            }
        }
        flushParagraph()
        return result
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case let .heading(text, level):
            Text(inlineMarkdown(text))
                .font(level == 1 ? .title2.bold() : level == 2 ? .title3.bold() : .headline)
                .padding(.top, level == 1 ? 4 : 2)

        case let .paragraph(text):
            Text(inlineMarkdown(text))
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .textSelection(.enabled)

        case let .bullet(text):
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
                Text(inlineMarkdown(text))
                    .font(.body)
                    .lineSpacing(3)
                    .textSelection(.enabled)
            }

        case let .numbered(text):
            Text(inlineMarkdown(text))
                .font(.body)
                .lineSpacing(3)
                .padding(.leading, 4)
                .textSelection(.enabled)
        }
    }

    private func inlineMarkdown(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }
}

private enum MarkdownBlock {
    case heading(String, level: Int)
    case paragraph(String)
    case bullet(String)
    case numbered(String)
}
