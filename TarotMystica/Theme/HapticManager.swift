import UIKit

/// Centralized haptic feedback manager for key interaction moments.
/// Uses UIKit generators — lightweight, no dependencies.
enum Haptic {

    // MARK: - Card interactions

    /// Tapping the card stack to draw — soft thud
    static func cardDraw() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Card flip reveal — crisp snap
    static func cardFlip() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.8)
    }

    /// All cards drawn — satisfying completion
    static func allCardsDrawn() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Shuffle

    /// Shuffle phase transitions — subtle ticks
    static func shuffleTick() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4)
    }

    /// Shuffle complete — stack together
    static func shuffleComplete() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.6)
    }

    // MARK: - Navigation & selection

    /// Selecting a spread, topic tag, or option
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Primary action button (start reading, view AI, etc.)
    static func primaryAction() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.7)
    }

    // MARK: - Feedback

    /// Error or destructive action confirmation
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// AI interpretation complete
    static func aiComplete() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
