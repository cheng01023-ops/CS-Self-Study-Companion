import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red: UInt64
        let green: UInt64
        let blue: UInt64
        let alpha: UInt64

        switch cleaned.count {
        case 3:
            red = (value >> 8) * 17
            green = ((value >> 4) & 0xF) * 17
            blue = (value & 0xF) * 17
            alpha = 255
        case 6:
            red = value >> 16
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
            alpha = 255
        case 8:
            red = value >> 24
            green = (value >> 16) & 0xFF
            blue = (value >> 8) & 0xFF
            alpha = value & 0xFF
        default:
            red = 59
            green = 130
            blue = 246
            alpha = 255
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}

struct LearningCardModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        colorSchemeContrast == .increased ? Color.primary.opacity(0.28) : Color.secondary.opacity(0.16),
                        lineWidth: colorSchemeContrast == .increased ? 2 : 1
                    )
            }
            .shadow(
                color: .black.opacity(colorSchemeContrast == .increased ? 0 : 0.04),
                radius: colorSchemeContrast == .increased ? 0 : 8,
                y: colorSchemeContrast == .increased ? 0 : 3
            )
    }
}

extension View {
    func learningCard() -> some View {
        modifier(LearningCardModifier())
    }
}

extension Color {
    static var appBackground: Color {
        #if os(iOS)
        Color(.systemGroupedBackground)
        #elseif os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.gray.opacity(0.12)
        #endif
    }
}

struct LearningPageWidthModifier: ViewModifier {
    let maxWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

extension View {
    /// 让页面在窄窗口占满可用宽度，在大窗口和全屏时扩展到合适的阅读宽度并保持居中。
    func learningPageWidth(maxWidth: CGFloat = 1180) -> some View {
        modifier(LearningPageWidthModifier(maxWidth: maxWidth))
    }
}
