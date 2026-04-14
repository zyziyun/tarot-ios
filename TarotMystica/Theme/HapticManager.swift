import UIKit

enum Haptic {

    static func cardDraw() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func cardFlip() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.8)
    }

    static func allCardsDrawn() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func shuffleTick() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4)
    }

    static func shuffleComplete() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.6)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func primaryAction() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.7)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func aiComplete() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
