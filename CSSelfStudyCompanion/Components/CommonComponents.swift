import SwiftUI

struct LearningProgressBar: View {
    let value: Double
    var tint: Color = .accentColor

    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                Capsule()
                    .fill(tint.gradient)
                    .frame(width: max(0, min(proxy.size.width, proxy.size.width * value)))
                    .overlay {
                        if differentiateWithoutColor {
                            Capsule()
                                .stroke(.primary.opacity(0.5), lineWidth: 1.5)
                        }
                    }
            }
        }
        .frame(height: 8)
        .accessibilityElement()
        .accessibilityLabel("学习进度")
        .accessibilityValue("\(Int(value * 100))%")
        .accessibilityHint("当前完成比例")
    }
}

struct StatPill: View {
    let icon: String
    let text: String
    var tint: Color = .secondary

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.1), in: Capsule())
            .accessibilityElement(children: .combine)
    }
}

struct CopyButton: View {
    let text: String
    var compact = false

    @State private var copied = false

    var body: some View {
        Button {
            Clipboard.copy(text)
            copied = true
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                copied = false
            }
        } label: {
            Label(copied ? "已复制" : "复制", systemImage: copied ? "checkmark" : "doc.on.doc")
                .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
        }
        .buttonStyle(.bordered)
        .tint(copied ? .green : .accentColor)
    }
}

enum Clipboard {
    static func copy(_ value: String) {
        #if os(iOS)
        UIPasteboard.general.string = value
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        #endif
    }
}
