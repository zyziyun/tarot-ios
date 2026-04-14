import SwiftUI

enum Phase: String, CaseIterable {
    case hero, question, choose, draw, result
}

@Observable
final class AppState {
    var phase: Phase = .hero
    var splashFinished = false
    var question: String = ""
    var activeSpread: Spread?
    var activeSpreadKey: String?
    var resolvedPositions: [SpreadPosition] = []
    var drawnCards: [DrawnCard] = []
    var aiRecommendation: AISpreadRecommendation?
    var isRecommending: Bool = false

    func reset() {
        phase = .hero
        question = ""
        activeSpread = nil
        activeSpreadKey = nil
        resolvedPositions = []
        drawnCards = []
        aiRecommendation = nil
        isRecommending = false
    }
}
