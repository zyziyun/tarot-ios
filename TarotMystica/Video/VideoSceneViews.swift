import SwiftUI

/// Self-contained scene views for video rendering.
/// Designed to look like the real app UI for an authentic feel.
/// No @Environment dependencies; all data passed as parameters.

// MARK: - Shared Constants

private let cream = Color(red: 0.98, green: 0.965, blue: 0.94)
private let cream2 = Color(red: 0.96, green: 0.94, blue: 0.90)
private let dark = Color(red: 0.176, green: 0.161, blue: 0.149)
private let muted = Color(red: 0.47, green: 0.443, blue: 0.424)
private let gold = Color(red: 0.788, green: 0.659, blue: 0.298)
private let accent = Color(red: 0.486, green: 0.227, blue: 0.929)
private let surface = Color(red: 0.96, green: 0.95, blue: 0.93)
private let cardBackColors = [Color(red: 0.42, green: 0.31, blue: 0.63), Color(red: 0.29, green: 0.21, blue: 0.44)]

// MARK: - Video Frame Size

let videoLogicalSize = CGSize(width: 540, height: 960) // rendered @2x = 1080x1920

// MARK: - Celestial Decorative Elements

private struct CelestialBackground: View {
    var opacity: Double = 0.06

    private let symbols: [(String, CGFloat, CGFloat, CGFloat, CGFloat)] = [
        ("✦", 42, 180, 10, 0),
        ("☽", 480, 220, 14, -15),
        ("✧", 70, 400, 8, 10),
        ("⊹", 490, 480, 9, 5),
        ("✦", 30, 650, 7, -8),
        ("☆", 500, 700, 11, 12),
        ("✧", 260, 130, 6, 0),
        ("⊹", 120, 820, 8, -5),
        ("✦", 460, 860, 7, 8),
        ("☽", 300, 750, 9, -10),
    ]

    var body: some View {
        ZStack {
            ForEach(Array(symbols.enumerated()), id: \.offset) { _, item in
                Text(item.0)
                    .font(.system(size: item.3))
                    .foregroundColor(gold.opacity(opacity))
                    .rotationEffect(.degrees(item.4))
                    .position(x: item.1, y: item.2)
            }
        }
    }
}

private struct OrnamentalDivider: View {
    var width: CGFloat = 120
    var symbol: String = "✦"

    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(gold.opacity(0.2)).frame(width: width * 0.35, height: 0.5)
            Text(symbol)
                .font(.system(size: 10))
                .foregroundColor(gold.opacity(0.35))
            Rectangle().fill(gold.opacity(0.2)).frame(width: width * 0.35, height: 0.5)
        }
    }
}

private struct MoonPhaseRow: View {
    var body: some View {
        HStack(spacing: 14) {
            ForEach(["🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘"], id: \.self) { moon in
                Text(moon)
                    .font(.system(size: 10))
                    .opacity(0.35)
            }
        }
    }
}

// MARK: - Mock App Chrome (top bar + bottom bar)

private struct VideoAppChrome<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            LinearGradient(colors: [cream, cream2], startPoint: .top, endPoint: .bottom)
            CelestialBackground(opacity: 0.04)

            VStack(spacing: 0) {
                Color.clear.frame(height: 54)

                HStack {
                    Text("9:41")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(dark.opacity(0.5))
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "wifi")
                            .font(.system(size: 10))
                        Image(systemName: "battery.75percent")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(dark.opacity(0.3))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 4)

                HStack {
                    Text("✦")
                        .font(.system(size: 16))
                        .foregroundColor(accent.opacity(0.5))
                    Spacer()
                    VStack(spacing: 2) {
                        Text(title)
                            .font(.system(size: 17, weight: .medium, design: .serif))
                            .foregroundColor(dark)
                        if let sub = subtitle {
                            Text(sub)
                                .font(.system(size: 10))
                                .foregroundColor(muted.opacity(0.4))
                        }
                    }
                    Spacer()
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundColor(muted.opacity(0.3))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                Rectangle()
                    .fill(gold.opacity(0.1))
                    .frame(height: 0.5)

                content()

                Color.clear.frame(height: 34)
            }

            videoWatermark
        }
        .frame(width: videoLogicalSize.width, height: videoLogicalSize.height)
    }
}

// MARK: - Title Card Scene

struct VideoTitleScene: View {
    let question: String
    let spreadName: String

    var body: some View {
        ZStack {
            LinearGradient(colors: [cream, cream2], startPoint: .top, endPoint: .bottom)
            CelestialBackground(opacity: 0.07)
            RadialGradient(
                colors: [gold.opacity(0.06), Color.clear],
                center: .center, startRadius: 40, endRadius: 300
            )

            VStack(spacing: 0) {
                Spacer()

                OrnamentalDivider(width: 140, symbol: "☽")
                Spacer().frame(height: 20)

                Text("TAROT MYSTICA")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(muted.opacity(0.35))
                    .tracking(6)
                Spacer().frame(height: 10)
                Text("✦  AI-Powered Tarot Reading  ✦")
                    .font(.system(size: 11))
                    .foregroundColor(gold.opacity(0.3))
                    .tracking(2)

                Spacer().frame(height: 40)

                Text(spreadName)
                    .font(.system(size: 44, weight: .light, design: .serif))
                    .foregroundColor(dark)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer().frame(height: 20)

                VStack(spacing: 3) {
                    Rectangle().fill(gold.opacity(0.25)).frame(width: 80, height: 0.5)
                    Rectangle().fill(gold.opacity(0.15)).frame(width: 50, height: 0.5)
                }

                Spacer().frame(height: 20)

                if !question.isEmpty {
                    Text("「\(question)」")
                        .font(.system(size: 22, weight: .light, design: .serif))
                        .foregroundColor(muted)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .padding(.horizontal, 36)
                }

                Spacer().frame(height: 16)

                Text(formattedDate())
                    .font(.system(size: 12))
                    .foregroundColor(muted.opacity(0.3))

                Spacer()

                VStack(spacing: 12) {
                    MoonPhaseRow()
                    HStack(spacing: -8) {
                        ForEach(0..<5, id: \.self) { i in
                            cardBackMini
                                .rotationEffect(.degrees(Double(i - 2) * 8))
                        }
                    }
                    OrnamentalDivider(width: 100, symbol: "✧")
                    Text("Tap to begin your reading")
                        .font(.system(size: 13))
                        .foregroundColor(muted.opacity(0.3))
                }
                .padding(.bottom, 48)
            }

            videoWatermark
        }
        .frame(width: videoLogicalSize.width, height: videoLogicalSize.height)
    }

    private func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        return f.string(from: Date())
    }

    private var cardBackMini: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(LinearGradient(colors: cardBackColors, startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: 5)
                .stroke(gold.opacity(0.25), lineWidth: 0.5)
            Text("✦")
                .font(.system(size: 10))
                .foregroundColor(gold.opacity(0.4))
        }
        .frame(width: 40, height: 62)
        .shadow(color: accent.opacity(0.1), radius: 4, y: 2)
    }
}

// MARK: - Spread Layout Scene

struct VideoSpreadLayoutScene: View {
    let spreadKey: String
    let positionCount: Int
    let spreadName: String

    var body: some View {
        VideoAppChrome(title: "Tarot Mystica", subtitle: "Choose Your Spread") {
            VStack(spacing: 0) {
                Spacer().frame(height: 10)

                HStack(spacing: 10) {
                    spreadChip("Past-Present-Future", active: spreadKey == "three_card")
                    spreadChip("Celtic Cross", active: spreadKey == "celtic_cross")
                    spreadChip("Love", active: spreadKey == "love")
                }
                .padding(.horizontal, 16)

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(gold.opacity(0.15), lineWidth: 0.5)
                        )
                        .shadow(color: dark.opacity(0.04), radius: 12, y: 4)

                    VStack(spacing: 16) {
                        OrnamentalDivider(width: 80, symbol: "✧")
                            .padding(.top, 4)

                        SpreadLayoutView(
                            spreadKey: spreadKey,
                            count: positionCount,
                            accentColor: accent,
                            cardColor: accent.opacity(0.2),
                            size: 180
                        )

                        Text(spreadName)
                            .font(.system(size: 28, weight: .light, design: .serif))
                            .foregroundColor(dark)

                        HStack(spacing: 16) {
                            infoTag(icon: "rectangle.stack", text: "\(positionCount) cards")
                            infoTag(icon: "clock", text: "~5 min")
                            infoTag(icon: "sparkles", text: "AI")
                        }

                        Text("Explore your path through\npast, present, and future")
                            .font(.system(size: 13))
                            .foregroundColor(muted.opacity(0.45))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.vertical, 24)
                }
                .padding(.horizontal, 28)

                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                    Text("Begin Reading")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(colors: [accent, accent.opacity(0.85)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(28)
                .shadow(color: accent.opacity(0.25), radius: 10, y: 4)
                .padding(.horizontal, 44)

                Spacer().frame(height: 12)
            }
        }
    }

    private func spreadChip(_ name: String, active: Bool) -> some View {
        Text(name)
            .font(.system(size: 11, weight: active ? .semibold : .regular))
            .foregroundColor(active ? accent : muted.opacity(0.35))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(active ? accent.opacity(0.08) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(active ? accent.opacity(0.2) : gold.opacity(0.1), lineWidth: 0.5)
            )
    }

    private func infoTag(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 12))
        }
        .foregroundColor(muted.opacity(0.45))
    }
}

// MARK: - Card Draw Scene (animated)

struct VideoCardDrawScene: View {
    let cards: [(card: DrawnCard, position: SpreadPosition, name: String)]
    let drawProgress: Double

    var body: some View {
        let visibleCount = max(1, Int(Double(cards.count) * drawProgress))

        VideoAppChrome(title: "Drawing Cards", subtitle: "\(visibleCount) of \(cards.count)") {
            VStack(spacing: 0) {
                Spacer().frame(height: 28)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(gold.opacity(0.08))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(colors: [accent.opacity(0.5), accent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(20, CGFloat(visibleCount) / CGFloat(cards.count) * (videoLogicalSize.width - 80)), height: 4)
                }
                .padding(.horizontal, 40)

                Spacer().frame(height: 10)

                HStack(spacing: 8) {
                    ForEach(0..<cards.count, id: \.self) { i in
                        Circle()
                            .fill(i < visibleCount ? accent : muted.opacity(0.12))
                            .frame(width: 8, height: 8)
                    }
                }

                if visibleCount > 0 && visibleCount <= cards.count {
                    let currentLabel = cards[visibleCount - 1].position.label
                    if !currentLabel.isEmpty {
                        Text("Drawing: \(currentLabel)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(accent.opacity(0.6))
                            .padding(.top, 14)
                    }
                }

                Spacer()

                cardLayout(visibleCount: visibleCount)

                Spacer()

                Text("Concentrate on your question...")
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(gold.opacity(0.35))
                    .italic()

                Spacer().frame(height: 8)

                OrnamentalDivider(width: 80, symbol: "☽")
                    .padding(.bottom, 8)
            }
        }
    }

    /// Card size adapts to card count
    private var cardSize: CGSize {
        switch cards.count {
        case 1: return CGSize(width: 160, height: 248)
        case 2...3: return CGSize(width: 120, height: 186)
        case 4...6: return CGSize(width: 105, height: 162)
        case 7...8: return CGSize(width: 88, height: 136)
        default: return CGSize(width: 72, height: 112)
        }
    }

    @ViewBuilder
    private func cardLayout(visibleCount: Int) -> some View {
        let cw = cardSize.width
        let ch = cardSize.height

        if cards.count <= 3 {
            HStack(spacing: 16) {
                ForEach(0..<cards.count, id: \.self) { i in
                    cardSlot(index: i, visible: i < visibleCount, label: cards[i].position.label, w: cw, h: ch)
                }
            }
        } else if cards.count <= 8 {
            let cols = cards.count <= 4 ? 2 : (cards.count <= 6 ? 3 : 4)
            let rows = (cards.count + cols - 1) / cols
            VStack(spacing: 14) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(0..<cols, id: \.self) { col in
                            let idx = row * cols + col
                            if idx < cards.count {
                                cardSlot(index: idx, visible: idx < visibleCount, label: cards[idx].position.label, w: cw, h: ch)
                            }
                        }
                    }
                }
            }
        } else {
            let cols = 5
            let rows = (cards.count + cols - 1) / cols
            VStack(spacing: 8) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(0..<cols, id: \.self) { col in
                            let idx = row * cols + col
                            if idx < cards.count {
                                cardSlot(index: idx, visible: idx < visibleCount, label: "", w: cw, h: ch)
                            }
                        }
                    }
                }
            }
        }
    }

    private func cardSlot(index: Int, visible: Bool, label: String, w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: 6) {
            ZStack {
                if visible {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(colors: cardBackColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(gold.opacity(0.3), lineWidth: 0.5)
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(gold.opacity(0.12), lineWidth: 0.5)
                            .padding(5)
                        VStack(spacing: 4) {
                            Text("✦")
                                .font(.system(size: min(20, h * 0.13)))
                                .foregroundColor(gold.opacity(0.5))
                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(gold.opacity(0.3))
                        }
                    }
                    .frame(width: w, height: h)
                    .shadow(color: accent.opacity(0.15), radius: 8, y: 4)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(gold.opacity(0.02))
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(gold.opacity(0.12), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(gold.opacity(0.15))
                    }
                    .frame(width: w, height: h)
                }
            }

            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(visible ? accent.opacity(0.6) : muted.opacity(0.3))
                    .lineLimit(1)
                    .frame(width: w)
            }
        }
    }
}

// MARK: - Card Reveal Scene

struct VideoCardRevealScene: View {
    let cardImage: String
    let cardName: String
    let positionLabel: String
    let isReversed: Bool
    let flipProgress: Double

    var body: some View {
        VideoAppChrome(title: "Your Reading") {
            VStack(spacing: 0) {
                Spacer()

                if !positionLabel.isEmpty {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(accent.opacity(0.5))
                            .frame(width: 6, height: 6)
                        Text(positionLabel.uppercased())
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(gold)
                            .tracking(3)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(gold.opacity(0.06))
                    .cornerRadius(16)

                    Spacer().frame(height: 14)
                }

                ZStack {
                    if flipProgress > 0.5 {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                RadialGradient(
                                    colors: [gold.opacity(0.12), Color.clear],
                                    center: .center, startRadius: 20, endRadius: 140
                                )
                            )
                            .frame(width: 220, height: 350)
                            .opacity(min(1.0, (flipProgress - 0.5) * 3))
                    }

                    if flipProgress < 0.5 {
                        cardBackView
                            .scaleEffect(x: max(0.01, 1.0 - flipProgress * 2), y: 1)
                    } else {
                        cardFrontView
                            .scaleEffect(x: max(0.01, (flipProgress - 0.5) * 2), y: 1)
                    }
                }
                .frame(width: 170, height: 264)
                .shadow(color: gold.opacity(0.25), radius: 16, y: 8)

                Spacer().frame(height: 28)

                if flipProgress >= 0.5 {
                    VStack(spacing: 10) {
                        Text(cardName)
                            .font(.system(size: 24, weight: .medium, design: .serif))
                            .foregroundColor(dark)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        HStack(spacing: 8) {
                            Image(systemName: isReversed ? "arrow.down" : "arrow.up")
                                .font(.system(size: 11, weight: .bold))
                            Text(isReversed ? "Reversed" : "Upright")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(isReversed ? accent.opacity(0.7) : gold.opacity(0.6))
                        .cornerRadius(14)

                        Text(isReversed ? "Inner reflection & new perspective" : "Clear energy & forward momentum")
                            .font(.system(size: 12, design: .serif))
                            .foregroundColor(muted.opacity(0.4))
                            .italic()
                    }
                    .opacity(min(1.0, (flipProgress - 0.5) * 4))
                }

                Spacer()

                if flipProgress >= 0.8 {
                    OrnamentalDivider(width: 60, symbol: "✦")
                        .opacity(min(1.0, (flipProgress - 0.8) * 5))
                        .padding(.bottom, 8)
                }
            }
        }
    }

    private var cardBackView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: cardBackColors, startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: 14)
                .stroke(gold.opacity(0.3), lineWidth: 1)
            RoundedRectangle(cornerRadius: 11)
                .stroke(gold.opacity(0.12), lineWidth: 0.5)
                .padding(6)
            VStack(spacing: 8) {
                Text("✦")
                    .font(.system(size: 32))
                    .foregroundColor(gold.opacity(0.5))
                Text("MYSTICA")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(gold.opacity(0.25))
                    .tracking(4)
            }
        }
    }

    private var cardFrontView: some View {
        Group {
            let name = cardImage.replacingOccurrences(of: ".webp", with: "")
            if let path = Bundle.main.path(forResource: name, ofType: "webp"),
               let uiImage = UIImage(contentsOfFile: path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(14)
                    .rotationEffect(isReversed ? .degrees(180) : .zero)
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.15))
            }
        }
    }
}

// MARK: - All Cards Scene

struct VideoAllCardsScene: View {
    let cards: [(card: DrawnCard, position: SpreadPosition, name: String)]
    let spreadKey: String?

    /// Card size adapts to card count
    private var cardW: CGFloat {
        switch cards.count {
        case 1: return 140
        case 2...3: return 100
        case 4...6: return 75
        case 7...10: return 58
        default: return 48
        }
    }
    private var cardH: CGFloat { cardW * 1.55 }
    private var labelFont: CGFloat {
        switch cards.count {
        case 1: return 12
        case 2...3: return 10
        case 4...6: return 9
        default: return 7
        }
    }
    private var nameFont: CGFloat {
        switch cards.count {
        case 1: return 16
        case 2...3: return 12
        case 4...6: return 9
        default: return 8
        }
    }

    var body: some View {
        VideoAppChrome(title: "Your Cards") {
            VStack(spacing: 0) {
                Spacer().frame(height: 10)

                mockSegmentedControl(leftTitle: "✦ AI Reading", rightTitle: "Cards (\(cards.count))", rightActive: true)
                    .padding(.horizontal, 24)

                Spacer()

                spreadLayoutCards

                Spacer().frame(height: 16)

                HStack(spacing: 8) {
                    summaryChip(icon: "arrow.up", count: cards.filter { !$0.card.reversed }.count, label: "Upright", color: gold)
                    summaryChip(icon: "arrow.down", count: cards.filter { $0.card.reversed }.count, label: "Reversed", color: accent)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
    }

    private func summaryChip(icon: String, count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text("\(count) \(label)")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(color.opacity(0.5))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.04))
        .cornerRadius(10)
    }

    // MARK: - Spread layout using actual positions

    /// Compute a safe spread multiplier that prevents card overlap
    private var spreadMultiplier: CGFloat {
        // Each card occupies roughly cardW+20 width, cardH+30 height
        // Need enough spread so adjacent positions don't overlap
        let cellW = cardW + 24
        let cellH = cardH + 30
        let maxCell = max(cellW, cellH)
        // Minimum distance between positions varies by spread; use 0.5 as typical min gap
        let minGap: CGFloat = 0.5
        // Scale so that minGap * layoutSize * multiplier >= maxCell
        let layoutSize: CGFloat = videoLogicalSize.width - 40
        let needed = maxCell / (minGap * layoutSize)
        return min(max(needed, 0.30), 0.42)
    }

    private var spreadLayoutCards: some View {
        let key = spreadKey ?? "default"
        let positions = SpreadLayoutView.layoutPositions(for: key, count: cards.count)
        let layoutSize: CGFloat = videoLogicalSize.width - 40
        let mult = spreadMultiplier

        return ZStack {
            ForEach(Array(cards.enumerated()), id: \.offset) { idx, item in
                if idx < positions.count {
                    let pos = positions[idx]
                    spreadCardView(item: item, rotation: pos.rotation)
                        .offset(
                            x: pos.x * layoutSize * mult,
                            y: pos.y * layoutSize * mult
                        )
                }
            }
        }
        .frame(width: layoutSize, height: layoutSize * 0.85)
    }

    private func spreadCardView(item: (card: DrawnCard, position: SpreadPosition, name: String), rotation: Double) -> some View {
        VStack(spacing: 2) {
            if !item.position.label.isEmpty {
                Text(item.position.label)
                    .font(.system(size: labelFont, weight: .bold))
                    .foregroundColor(accent)
                    .tracking(0.5)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(accent.opacity(0.06))
                    .cornerRadius(3)
            }

            cardImageView(item.card.card.image)
                .frame(width: cardW, height: cardH)
                .rotationEffect(item.card.reversed ? .degrees(180) : .zero)
                .rotationEffect(.degrees(rotation))
                .shadow(color: gold.opacity(0.15), radius: 4, y: 2)

            Text(item.name)
                .font(.system(size: nameFont, weight: .medium, design: .serif))
                .foregroundColor(dark)
                .lineLimit(1)

            if item.card.reversed {
                Text("Rev.")
                    .font(.system(size: max(labelFont - 2, 7), weight: .bold))
                    .foregroundColor(accent.opacity(0.7))
            }
        }
        .frame(width: cardW + 16)
    }
}

// MARK: - AI Summary Scene

struct VideoAISummaryScene: View {
    let text: String
    let question: String
    let spreadName: String
    let cards: [(card: DrawnCard, position: SpreadPosition, name: String)]

    var body: some View {
        VideoAppChrome(title: "Your Reading") {
            VStack(spacing: 0) {
                Spacer().frame(height: 10)

                mockSegmentedControl(leftTitle: "✦ AI Reading", rightTitle: "Cards", rightActive: false)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 12)

                HStack(spacing: cards.count > 7 ? 4 : 8) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { _, item in
                        VStack(spacing: 4) {
                            cardImageView(item.card.card.image)
                                .frame(width: cardThumbWidth, height: cardThumbWidth * 1.55)
                                .rotationEffect(item.card.reversed ? .degrees(180) : .zero)
                                .cornerRadius(4)
                                .shadow(color: gold.opacity(0.1), radius: 3, y: 2)

                            if !item.position.label.isEmpty {
                                Text(item.position.label)
                                    .font(.system(size: thumbLabelFont, weight: .medium))
                                    .foregroundColor(dark.opacity(0.5))
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: cardThumbWidth + 8)
                    }
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 14)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("AI 深度解读")
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundColor(dark)
                    }

                    Rectangle()
                        .fill(gold.opacity(0.12))
                        .frame(height: 0.5)

                    posterMarkdownView(stripMarkdown(text))
                }
                .padding(16)
                .frame(maxHeight: aiCardMaxHeight, alignment: .top)
                .clipped()
                .background(surface)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(gold.opacity(0.1), lineWidth: 0.5))
                .shadow(color: dark.opacity(0.03), radius: 8, y: 3)
                .padding(.horizontal, 18)

                Spacer().frame(height: 10)

                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 13))
                    Text("Ask a follow-up question...")
                        .font(.system(size: 13))
                }
                .foregroundColor(muted.opacity(0.3))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(surface.opacity(0.6))
                .cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(gold.opacity(0.08), lineWidth: 0.5))
                .padding(.horizontal, 18)

                Spacer().frame(height: 8)
            }
        }
    }

    /// Max height for AI content card to prevent overflow
    /// Total frame: 960pt. Chrome top ~100pt, tabs ~40pt, thumbnails ~100pt, follow-up ~40pt, bottom ~42pt
    /// Available for card: 960 - 100 - 40 - 100 - 40 - 42 - margins ≈ 520pt
    private var aiCardMaxHeight: CGFloat {
        let thumbHeight = cardThumbWidth * 1.55 + 20 // card + label
        let overhead: CGFloat = 100 + 40 + thumbHeight + 14 + 10 + 40 + 42 + 16
        return videoLogicalSize.height - overhead
    }

    private var cardThumbWidth: CGFloat {
        switch cards.count {
        case 1: return 70
        case 2...3: return 60
        case 4...6: return 48
        case 7...10: return 36
        default: return 28
        }
    }

    private var thumbLabelFont: CGFloat {
        switch cards.count {
        case 1...3: return 11
        case 4...6: return 9
        default: return 7
        }
    }

    private func stripMarkdown(_ text: String) -> String {
        var s = text
        s = s.replacingOccurrences(of: "```markdown", with: "")
        s = s.replacingOccurrences(of: "```json", with: "")
        s = s.replacingOccurrences(of: "```text", with: "")
        s = s.replacingOccurrences(of: "```", with: "")
        s = s.replacingOccurrences(of: "`", with: "")
        s = s.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\*(.+?)\*"#, with: "$1", options: .regularExpression)
        return s
    }
}

// MARK: - Outro Scene

struct VideoOutroScene: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [cream, cream2], startPoint: .top, endPoint: .bottom)
            CelestialBackground(opacity: 0.08)
            RadialGradient(
                colors: [accent.opacity(0.04), Color.clear],
                center: .center, startRadius: 20, endRadius: 280
            )

            VStack(spacing: 0) {
                Spacer()

                OrnamentalDivider(width: 100, symbol: "☽")
                Spacer().frame(height: 28)

                ZStack {
                    RoundedRectangle(cornerRadius: 26)
                        .fill(LinearGradient(
                            colors: [accent.opacity(0.12), gold.opacity(0.08)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 96, height: 96)
                        .overlay(
                            RoundedRectangle(cornerRadius: 26)
                                .stroke(gold.opacity(0.2), lineWidth: 0.5)
                        )
                        .shadow(color: accent.opacity(0.1), radius: 16, y: 6)
                    Text("✦")
                        .font(.system(size: 42))
                        .foregroundColor(accent.opacity(0.6))
                }

                Spacer().frame(height: 20)

                Text("TAROT MYSTICA")
                    .font(.system(size: 18, weight: .medium))
                    .tracking(6)
                    .foregroundColor(dark.opacity(0.6))

                Spacer().frame(height: 8)

                Text("Your Personal Tarot Companion")
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(muted.opacity(0.4))

                Spacer().frame(height: 28)

                VStack(spacing: 12) {
                    featureRow(icon: "brain.head.profile", text: "On-Device AI Interpretation")
                    featureRow(icon: "lock.shield", text: "100% Private & Secure")
                    featureRow(icon: "globe", text: "Multi-Language Support")
                    featureRow(icon: "sparkles", text: "Beautiful Card Artwork")
                }

                Spacer().frame(height: 28)

                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(gold.opacity(0.5))
                    }
                }

                Spacer().frame(height: 8)

                VStack(spacing: 12) {
                    Rectangle()
                        .fill(gold.opacity(0.15))
                        .frame(width: 48, height: 0.5)

                    HStack(spacing: 6) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 13))
                        Text("Available on the App Store")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(muted.opacity(0.4))
                }

                Spacer()

                MoonPhaseRow()
                    .padding(.bottom, 40)
            }
        }
        .frame(width: videoLogicalSize.width, height: videoLogicalSize.height)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(accent.opacity(0.4))
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(dark.opacity(0.5))
            Spacer()
        }
        .padding(.horizontal, 80)
    }
}

// MARK: - Shared Components

private func mockSegmentedControl(leftTitle: String, rightTitle: String, rightActive: Bool) -> some View {
    HStack(spacing: 0) {
        segmentTab(title: leftTitle, active: !rightActive)
        segmentTab(title: rightTitle, active: rightActive)
    }
    .background(surface)
    .cornerRadius(12)
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(gold.opacity(0.1), lineWidth: 0.5))
}

private func segmentTab(title: String, active: Bool) -> some View {
    Text(title)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(active ? .white : muted.opacity(0.5))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(active ? accent : Color.clear)
        .cornerRadius(10)
        .padding(2)
}

// MARK: - Watermark Overlay

private var videoWatermark: some View {
    VStack {
        HStack {
            Spacer()
            HStack(spacing: 4) {
                Text("✦")
                    .font(.system(size: 9))
                    .foregroundColor(gold.opacity(0.2))
                Text("Tarot Mystica")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(muted.opacity(0.2))
            }
            .padding(.trailing, 16)
            .padding(.top, 32)
        }
        Spacer()
    }
}

// MARK: - Poster-style Markdown View

@ViewBuilder
private func posterMarkdownView(_ text: String) -> some View {
    let lines = text.components(separatedBy: "\n")
    VStack(alignment: .leading, spacing: 5) {
        ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                Spacer().frame(height: 3)
            } else if trimmed.hasPrefix("###") {
                Text(trimmed.replacingOccurrences(of: "### ", with: "").replacingOccurrences(of: "###", with: ""))
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundColor(dark)
                    .padding(.top, 4)
            } else if trimmed.hasPrefix("##") {
                Text(trimmed.replacingOccurrences(of: "## ", with: "").replacingOccurrences(of: "##", with: ""))
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(dark)
                    .padding(.top, 6)
            } else if trimmed.hasPrefix("#") {
                Text(trimmed.replacingOccurrences(of: "# ", with: "").replacingOccurrences(of: "#", with: ""))
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundColor(dark)
                    .padding(.top, 8)
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                HStack(alignment: .top, spacing: 8) {
                    Text("·")
                        .font(.system(size: 13))
                        .foregroundColor(gold)
                        .offset(y: 1)
                    Text(String(trimmed.dropFirst(2)))
                        .font(.system(size: 14))
                        .foregroundColor(dark.opacity(0.8))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if trimmed.hasPrefix("---") || trimmed.hasPrefix("***") || trimmed == "✦ ..." {
                if trimmed == "✦ ..." {
                    Text("✦ ...")
                        .font(.system(size: 12))
                        .foregroundColor(gold.opacity(0.5))
                        .padding(.top, 4)
                } else {
                    Rectangle()
                        .fill(gold.opacity(0.15))
                        .frame(height: 0.5)
                        .padding(.vertical, 4)
                }
            } else {
                Text(trimmed)
                    .font(.system(size: 14))
                    .foregroundColor(dark.opacity(0.8))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Shared Card Image Helper

func cardImageView(_ filename: String) -> some View {
    let name = filename.replacingOccurrences(of: ".webp", with: "")
    if let path = Bundle.main.path(forResource: name, ofType: "webp"),
       let uiImage = UIImage(contentsOfFile: path) {
        return AnyView(
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(8)
        )
    }
    return AnyView(
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.1))
    )
}
