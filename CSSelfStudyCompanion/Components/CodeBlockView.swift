import Foundation
import SwiftUI

struct CodeBlockView: View {
    let code: String
    let language: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(languageLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                CopyButton(text: code, compact: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.thinMaterial)

            ScrollView(.horizontal, showsIndicators: true) {
                Text(highlightedCode)
                    .font(.system(.body, design: .monospaced))
                    .lineSpacing(5)
                    .textSelection(.enabled)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(hex: "10131A"))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
    }

    private var languageLabel: String {
        switch language.lowercased() {
        case "c": "C"
        case "swift": "Swift"
        case "bash", "sh", "shell": "Shell"
        default: language.uppercased()
        }
    }

    private var highlightedCode: AttributedString {
        SyntaxHighlighter.highlight(code, language: language)
    }
}

enum SyntaxHighlighter {
    private static let keywords = [
        "auto", "break", "case", "char", "const", "continue", "default", "do",
        "double", "else", "enum", "extern", "float", "for", "goto", "if",
        "inline", "int", "long", "register", "return", "short", "signed",
        "sizeof", "static", "struct", "switch", "typedef", "union", "unsigned",
        "void", "volatile", "while", "NULL", "true", "false",
        "actor", "async", "await", "class", "defer", "extension", "func",
        "guard", "import", "in", "init", "let", "nil", "private", "protocol",
        "public", "repeat", "self", "some", "throw", "throws", "try", "var"
    ]

    static func highlight(_ code: String, language: String) -> AttributedString {
        let pattern = #"(\/\/[^\n]*|\/\*[\s\S]*?\*\/|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|#(?:include|define|if|ifdef|ifndef|endif|pragma)\b|\b(?:[A-Za-z_]\w*)\b|\b\d+(?:\.\d+)?\b)"#
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.anchorsMatchLines, .dotMatchesLineSeparators]
        ) else {
            return AttributedString(code)
        }

        var result = AttributedString()
        var cursor = code.startIndex
        let fullRange = NSRange(code.startIndex..<code.endIndex, in: code)

        for match in regex.matches(in: code, range: fullRange) {
            guard let range = Range(match.range, in: code) else { continue }
            append(String(code[cursor..<range.lowerBound]), color: .white.opacity(0.78), to: &result)

            let token = String(code[range])
            append(token, color: color(for: token, language: language), to: &result)
            cursor = range.upperBound
        }
        append(String(code[cursor...]), color: .white.opacity(0.78), to: &result)
        return result
    }

    private static func append(_ value: String, color: Color, to result: inout AttributedString) {
        var part = AttributedString(value)
        part.foregroundColor = color
        result.append(part)
    }

    private static func color(for token: String, language: String) -> Color {
        if token.hasPrefix("//") || token.hasPrefix("/*") {
            return Color(hex: "7F8C98")
        }
        if token.hasPrefix("\"") || token.hasPrefix("'") {
            return Color(hex: "F6C177")
        }
        if token.hasPrefix("#") {
            return Color(hex: "9CCFD8")
        }
        if token.first?.isNumber == true {
            return Color(hex: "C4A7E7")
        }
        if keywords.contains(token) {
            return language.lowercased() == "swift"
                ? Color(hex: "EB6F92")
                : Color(hex: "E38C7A")
        }
        return .white.opacity(0.92)
    }
}
