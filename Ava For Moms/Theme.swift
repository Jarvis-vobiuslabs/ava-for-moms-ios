import SwiftUI

// MARK: - Sprig Design System

struct AvaTheme {
    // Backgrounds
    static let bg           = Color(hex: "FFF6EF")
    static let bgDeep       = Color(hex: "FCEADB")
    static let cream        = Color(hex: "FFFCF6")

    // Text
    static let ink          = Color(hex: "3A2A1E")
    static let inkMute      = Color(hex: "7A6455")
    static let inkSoft      = Color(hex: "B6A092")
    static let line         = Color(hex: "3A2A1E").opacity(0.10)

    // Accent
    static let blush        = Color(hex: "F5B8A5")
    static let blushDeep    = Color(hex: "E88D74")
    static let terracotta   = Color(hex: "D46A47")
    static let terracottaDeep = Color(hex: "B04A2A")
    static let sage         = Color(hex: "A5C09A")
    static let sageDeep     = Color(hex: "7A9A6E")

    // Gradients
    static let blushTerracotta = LinearGradient(
        colors: [Color(hex: "F5B8A5"), Color(hex: "D46A47")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let blushSage = LinearGradient(
        colors: [Color(hex: "F5B8A5"), Color(hex: "A5C09A")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // Font — system rounded gives the same feel as Nunito, no bundling needed
    static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: 1)
    }
}
