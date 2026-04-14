import Foundation

/// Describes a single scene in the video storyboard
enum VideoScene {
    case titleCard(question: String, spreadName: String)
    case spreadLayout(spreadKey: String, positionCount: Int, spreadName: String)
    case cardDraw(cards: [(card: DrawnCard, position: SpreadPosition, name: String)], progress: Double)
    case cardReveal(card: DrawnCard, position: SpreadPosition, cardName: String)
    case allCards(cards: [(card: DrawnCard, position: SpreadPosition, name: String)], spreadKey: String?)
    case aiSummary(text: String, question: String, spreadName: String, cards: [(card: DrawnCard, position: SpreadPosition, name: String)])
    case outro

    /// Duration of this scene in seconds (excluding crossfade transitions)
    var holdDuration: TimeInterval {
        switch self {
        case .titleCard: return 2.0
        case .spreadLayout: return 1.5
        case .cardDraw: return 2.0
        case .cardReveal: return 1.5
        case .allCards: return 2.0
        case .aiSummary: return 3.0
        case .outro: return 1.5
        }
    }

    /// Whether this scene has per-frame animation (vs static)
    var isAnimated: Bool {
        switch self {
        case .cardReveal, .cardDraw: return true
        default: return false
        }
    }
}

/// The complete video storyboard with all scenes and timing
struct VideoStoryboard {
    let scenes: [VideoScene]
    let fps: Int = 30
    let width: Int = 1080
    let height: Int = 1920
    let crossfadeDuration: TimeInterval = 0.3

    /// Total frame count for the entire video
    var totalFrames: Int {
        var total: TimeInterval = 0
        for (i, scene) in scenes.enumerated() {
            total += scene.holdDuration
            if i < scenes.count - 1 {
                total += crossfadeDuration
            }
        }
        return Int(total * Double(fps))
    }

    /// Build a storyboard from the completed reading state
    static func create(
        question: String,
        spreadName: String,
        spreadKey: String?,
        drawnCards: [DrawnCard],
        positions: [SpreadPosition],
        aiReading: String,
        cardNameFn: (TarotCard) -> String
    ) -> VideoStoryboard {
        var scenes: [VideoScene] = []

        // 1. Title card — question + spread name
        scenes.append(.titleCard(question: question, spreadName: spreadName))

        // 2. Spread layout — show the spread pattern (skip for single card)
        let cardCount = positions.count > 0 ? positions.count : drawnCards.count
        if let key = spreadKey, cardCount > 1 {
            scenes.append(.spreadLayout(
                spreadKey: key,
                positionCount: cardCount,
                spreadName: spreadName
            ))
        }

        // 3. Card draw — cards appearing face-down one by one
        let allCardData = drawnCards.enumerated().map { idx, drawn in
            let pos = idx < positions.count ? positions[idx] : SpreadPosition(label: "", description: "")
            return (card: drawn, position: pos, name: cardNameFn(drawn.card))
        }
        scenes.append(.cardDraw(cards: allCardData, progress: 0))

        // 4. Card reveals — flip each card (up to 3 individually)
        let maxIndividual = min(drawnCards.count, 3)
        for i in 0..<maxIndividual {
            let pos = i < positions.count ? positions[i] : SpreadPosition(label: "", description: "")
            scenes.append(.cardReveal(
                card: drawnCards[i],
                position: pos,
                cardName: cardNameFn(drawnCards[i].card)
            ))
        }

        // 5. All cards summary
        scenes.append(.allCards(cards: allCardData, spreadKey: spreadKey))

        // 6. AI summary (first ~300 chars, cleaned)
        if !aiReading.isEmpty {
            let cleaned = cleanCodeFences(aiReading)
            let truncated = truncateReading(cleaned)
            scenes.append(.aiSummary(text: truncated, question: question, spreadName: spreadName, cards: allCardData))
        }

        // 7. Outro
        scenes.append(.outro)

        return VideoStoryboard(scenes: scenes)
    }

    private static func cleanCodeFences(_ text: String) -> String {
        var s = text
        s = s.replacingOccurrences(of: "```markdown", with: "")
        s = s.replacingOccurrences(of: "```json", with: "")
        s = s.replacingOccurrences(of: "```text", with: "")
        s = s.replacingOccurrences(of: "```", with: "")
        s = s.replacingOccurrences(of: "`", with: "")
        return s
    }

    private static func truncateReading(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        var result: [String] = []
        var charCount = 0

        for line in lines {
            result.append(line)
            charCount += line.count
            if charCount > 300 { break }
        }

        let truncated = result.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if truncated.count < text.count {
            return truncated + "\n\n✦ ..."
        }
        return truncated
    }
}
