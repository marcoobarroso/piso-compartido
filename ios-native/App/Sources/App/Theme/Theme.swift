import SwiftUI
import RumisCore

/// Dark-only palette for v1, converted from the web app's OKLCH tokens in
/// app/globals.css (.dark block) to sRGB so it reads identically on both
/// clients. Light mode can be added later by mirroring the :root block.
enum RTheme {
    static let background = Color(hex: "#0a0a0a")
    static let foreground = Color(hex: "#fafafa")
    static let card = Color(hex: "#171717")
    static let cardForeground = foreground
    static let primary = Color(hex: "#df6c32")
    static let primaryForeground = Color(hex: "#fafafa")
    static let secondary = Color(hex: "#262626")
    static let secondaryForeground = foreground
    static let muted = Color(hex: "#262626")
    static let mutedForeground = Color(hex: "#a1a1a1")
    static let accent = Color(hex: "#53230a")
    static let accentForeground = Color(hex: "#ffb997")
    static let destructive = Color(hex: "#ff6467")
    static let border = Color.white.opacity(0.10)
    static let ring = Color(hex: "#e57f4f")

    enum Radius {
        static let sm: CGFloat = 7
        static let md: CGFloat = 10
        static let lg: CGFloat = 12
        static let xl: CGFloat = 17
        static let xxl: CGFloat = 21
    }
}

/// Same categorical chart palette as lib/chart-colors.ts / the CSS --chart-N
/// tokens, so a series reads as the same color in Stats on both clients.
enum ChartPalette {
    static let colors: [Color] = [
        Color(hex: "#e2673d"),
        Color(hex: "#2f8fc9"),
        Color(hex: "#a88a1e"),
        Color(hex: "#7c5fd9"),
        Color(hex: "#5c9c4a"),
        Color(hex: "#9d5bc9"),
        Color(hex: "#d84f4f"),
        Color(hex: "#2fa88a"),
    ]

    static func color(at index: Int) -> Color {
        colors[index % colors.count]
    }
}

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s.removeAll { $0 == "#" }

        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)

        let r, g, b: UInt64
        (r, g, b) = ((value >> 16) & 0xff, (value >> 8) & 0xff, value & 0xff)

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

extension ExpenseCategory {
    /// SF Symbol matching the lucide-react icon used on the web for each
    /// category (lib/categories.ts CATEGORY_ICONS).
    var systemImage: String {
        switch self {
        case .comida: return "fork.knife"
        case .suministros: return "bolt.fill"
        case .ocio: return "party.popper.fill"
        case .hogar: return "house.fill"
        case .transporte: return "bus"
        case .otros: return "shippingbox.fill"
        }
    }

    var color: Color {
        Color(hex: hex)
    }
}
