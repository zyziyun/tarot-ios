import SwiftUI

struct SpreadLayoutView: View {
    let spreadKey: String
    let count: Int
    let accentColor: Color
    let cardColor: Color
    var highlightIndex: Int? = nil
    var size: CGFloat = 80

    var body: some View {
        let positions = Self.layoutPositions(for: spreadKey, count: count)
        let cardW: CGFloat = size * 0.14
        let cardH: CGFloat = cardW * 1.5

        ZStack {
            ForEach(Array(positions.enumerated()), id: \.offset) { idx, pos in
                RoundedRectangle(cornerRadius: 2)
                    .fill(idx == highlightIndex ? accentColor : cardColor)
                    .frame(width: cardW, height: cardH)
                    .rotationEffect(.degrees(pos.rotation))
                    .offset(
                        x: pos.x * size * 0.4,
                        y: pos.y * size * 0.4
                    )
                    .opacity(idx == highlightIndex ? 1.0 : 0.5)
            }
        }
        .frame(width: size, height: size)
    }

    struct CardPosition {
        let x: CGFloat
        let y: CGFloat
        let rotation: Double
    }

    static func layoutPositions(for key: String, count: Int) -> [CardPosition] {
        switch key {
        case "single":
            return [CardPosition(x: 0, y: 0, rotation: 0)]

        case "threeCard":
            return [
                CardPosition(x: -0.7, y: 0, rotation: 0),
                CardPosition(x: 0, y: 0, rotation: 0),
                CardPosition(x: 0.7, y: 0, rotation: 0),
            ]

        case "mindBodySpirit":
            return [
                CardPosition(x: 0, y: -0.6, rotation: 0),
                CardPosition(x: -0.5, y: 0.4, rotation: 0),
                CardPosition(x: 0.5, y: 0.4, rotation: 0),
            ]

        case "fiveCard", "gypsyCross":
            return [
                CardPosition(x: -0.7, y: 0, rotation: 0),
                CardPosition(x: 0, y: -0.6, rotation: 0),
                CardPosition(x: 0, y: 0, rotation: 0),
                CardPosition(x: 0, y: 0.6, rotation: 0),
                CardPosition(x: 0.7, y: 0, rotation: 0),
            ]

        case "relationship":
            return [
                CardPosition(x: -0.5, y: -0.5, rotation: 0),
                CardPosition(x: 0.5, y: -0.5, rotation: 0),
                CardPosition(x: -0.5, y: 0.2, rotation: 0),
                CardPosition(x: 0.5, y: 0.2, rotation: 0),
                CardPosition(x: 0, y: 0.7, rotation: 0),
            ]

        case "horseshoe":
            return (0..<7).map { i in
                let angle = Double(i) * .pi / 6 - .pi / 2
                let radius: CGFloat = 0.8
                return CardPosition(
                    x: CGFloat(cos(angle + .pi)) * radius,
                    y: CGFloat(sin(angle + .pi)) * radius * 0.7 + 0.1,
                    rotation: 0
                )
            }

        case "celtic":
            return [
                CardPosition(x: -0.3, y: 0, rotation: 0),
                CardPosition(x: -0.3, y: 0, rotation: 90),
                CardPosition(x: -0.3, y: -0.65, rotation: 0),
                CardPosition(x: -0.3, y: 0.65, rotation: 0),
                CardPosition(x: -0.9, y: 0, rotation: 0),
                CardPosition(x: 0.3, y: 0, rotation: 0),
                CardPosition(x: 0.8, y: 0.7, rotation: 0),
                CardPosition(x: 0.8, y: 0.23, rotation: 0),
                CardPosition(x: 0.8, y: -0.23, rotation: 0),
                CardPosition(x: 0.8, y: -0.7, rotation: 0),
            ]

        case "twoPaths":
            return [
                CardPosition(x: 0, y: 0.6, rotation: 0),
                CardPosition(x: -0.6, y: 0, rotation: 0),
                CardPosition(x: -0.6, y: -0.6, rotation: 0),
                CardPosition(x: 0.6, y: 0, rotation: 0),
                CardPosition(x: 0.6, y: -0.6, rotation: 0),
            ]

        case "hexagram":
            return (0..<6).map { i in
                let angle = Double(i) * .pi / 3 - .pi / 2
                return CardPosition(
                    x: CGFloat(cos(angle)) * 0.7,
                    y: CGFloat(sin(angle)) * 0.7,
                    rotation: 0
                )
            } + [CardPosition(x: 0, y: 0, rotation: 0)]

        case "pentagram", "mirrorOfSelf":
            return (0..<5).map { i in
                let angle = Double(i) * 2 * .pi / 5 - .pi / 2
                return CardPosition(
                    x: CGFloat(cos(angle)) * 0.7,
                    y: CGFloat(sin(angle)) * 0.65,
                    rotation: 0
                )
            }

        case "zodiac":
            return (0..<12).map { i in
                let angle = Double(i) * .pi / 6 - .pi / 2
                return CardPosition(
                    x: CGFloat(cos(angle)) * 0.85,
                    y: CGFloat(sin(angle)) * 0.85,
                    rotation: 0
                )
            }

        case "yearAhead":
            // 12 in circle + 1 center
            return (0..<12).map { i in
                let angle = Double(i) * .pi / 6 - .pi / 2
                return CardPosition(
                    x: CGFloat(cos(angle)) * 0.85,
                    y: CGFloat(sin(angle)) * 0.85,
                    rotation: 0
                )
            } + [CardPosition(x: 0, y: 0, rotation: 0)]

        case "career":
            return [
                CardPosition(x: 0, y: 0.7, rotation: 0),
                CardPosition(x: -0.6, y: 0.2, rotation: 0),
                CardPosition(x: 0.6, y: 0.2, rotation: 0),
                CardPosition(x: -0.6, y: -0.3, rotation: 0),
                CardPosition(x: 0.6, y: -0.3, rotation: 0),
                CardPosition(x: 0, y: -0.7, rotation: 0),
            ]

        case "treeOfLife":
            return [
                CardPosition(x: 0, y: -0.85, rotation: 0),
                CardPosition(x: -0.6, y: -0.55, rotation: 0),
                CardPosition(x: 0.6, y: -0.55, rotation: 0),
                CardPosition(x: -0.6, y: -0.1, rotation: 0),
                CardPosition(x: 0.6, y: -0.1, rotation: 0),
                CardPosition(x: 0, y: 0.05, rotation: 0),
                CardPosition(x: -0.6, y: 0.35, rotation: 0),
                CardPosition(x: 0.6, y: 0.35, rotation: 0),
                CardPosition(x: 0, y: 0.55, rotation: 0),
                CardPosition(x: 0, y: 0.85, rotation: 0),
            ]

        case "loversTree":
            return [
                CardPosition(x: 0, y: -0.7, rotation: 0),
                CardPosition(x: -0.5, y: -0.25, rotation: 0),
                CardPosition(x: 0.5, y: -0.25, rotation: 0),
                CardPosition(x: -0.7, y: 0.25, rotation: 0),
                CardPosition(x: 0.7, y: 0.25, rotation: 0),
                CardPosition(x: -0.3, y: 0.65, rotation: 0),
                CardPosition(x: 0.3, y: 0.65, rotation: 0),
            ]

        default:
            // Generic row layout
            let cols = min(count, 5)
            let rows = (count + cols - 1) / cols
            return (0..<count).map { i in
                let row = i / cols
                let col = i % cols
                let totalInRow = min(cols, count - row * cols)
                let xOffset = CGFloat(col) - CGFloat(totalInRow - 1) / 2
                let yOffset = CGFloat(row) - CGFloat(rows - 1) / 2
                return CardPosition(
                    x: xOffset * 0.5,
                    y: yOffset * 0.6,
                    rotation: 0
                )
            }
        }
    }
}
