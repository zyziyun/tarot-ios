import SwiftUI

@Observable
final class ThemeManager {
    let colors: ThemeColors
    let fonts: ThemeFonts
    let cardBack: CardBackStyle
    let animations: AnimationParams

    init() {
        let json = DataLoader.loadRawJSON("theme")
        let c = json["colors"] as? [String: String] ?? [:]
        let f = json["fonts"] as? [String: String] ?? [:]
        let cb = json["cardBack"] as? [String: Any] ?? [:]
        let anim = json["animations"] as? [String: Any] ?? [:]

        colors = ThemeColors(
            background: Color(hex: c["background"] ?? "#faf6f0"),
            foreground: Color(hex: c["foreground"] ?? "#2d2926"),
            muted: Color(hex: c["muted"] ?? "#78716c"),
            subtle: Color(hex: c["subtle"] ?? "#f5f0e8"),
            surface: Color(hex: c["surface"] ?? "#fffdf9"),
            border: Color(hex: c["border"] ?? "#e8e0d4"),
            accent: Color(hex: c["accent"] ?? "#7c3aed"),
            gold: Color(hex: c["gold"] ?? "#c9a84c"),
            accentPink: Color(hex: c["accentPink"] ?? "#ec4899")
        )

        fonts = ThemeFonts(
            heading: f["heading"] ?? "Playfair Display"
        )

        let gradient = cb["gradient"] as? [String] ?? ["#f5f0ff", "#ede9fe", "#f8f0e3"]
        let symbol = cb["centerSymbol"] as? [String: Any] ?? [:]
        cardBack = CardBackStyle(
            gradientColors: gradient.map { Color(hex: $0) },
            borderColor: Color(hex: "#c9a84c").opacity(0.3),
            symbolCharacter: symbol["character"] as? String ?? "✦",
            symbolColor: Color(hex: "#c9a84c").opacity(0.5)
        )

        let shuffle = anim["shuffle"] as? [String: Any] ?? [:]
        let flip = anim["cardFlip"] as? [String: Any] ?? [:]
        let draw = anim["draw"] as? [String: Any] ?? [:]
        animations = AnimationParams(
            shuffleDuration: shuffle["duration"] as? Double ?? 2.4,
            shuffleTotalDelay: (shuffle["totalDelay"] as? Double ?? 2800) / 1000,
            flipDuration: flip["duration"] as? Double ?? 0.8,
            flipStiffness: flip["stiffness"] as? Double ?? 80,
            flipDamping: flip["damping"] as? Double ?? 15,
            drawFlipDelay: (draw["flipDelay"] as? Double ?? 500) / 1000,
            drawCompleteDelay: (draw["completeDelay"] as? Double ?? 600) / 1000
        )
    }
}

struct ThemeColors {
    let background: Color
    let foreground: Color
    let muted: Color
    let subtle: Color
    let surface: Color
    let border: Color
    let accent: Color
    let gold: Color
    let accentPink: Color
}

struct ThemeFonts {
    let heading: String
}

struct CardBackStyle {
    let gradientColors: [Color]
    let borderColor: Color
    let symbolCharacter: String
    let symbolColor: Color
}

struct AnimationParams {
    let shuffleDuration: Double
    let shuffleTotalDelay: Double
    let flipDuration: Double
    let flipStiffness: Double
    let flipDamping: Double
    let drawFlipDelay: Double
    let drawCompleteDelay: Double
}

// MARK: - Color hex init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
