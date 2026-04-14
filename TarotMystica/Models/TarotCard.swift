import Foundation

struct TarotCard: Identifiable, Equatable {
    let id: Int
    let image: String
    let arcana: Arcana
    let suit: Suit?

    enum Arcana: String, Codable {
        case major, minor
    }

    enum Suit: String, Codable, CaseIterable {
        case wands, cups, swords, pentacles
    }
}

struct DrawnCard: Identifiable, Equatable {
    let id: Int  // position index
    let card: TarotCard
    let reversed: Bool
}

struct Spread: Identifiable, Equatable {
    let id: String  // key
    let icon: String
    let positionCount: Int
}

struct SpreadPosition: Equatable {
    let label: String
    let description: String
}

struct AISpreadRecommendation: Equatable {
    let isCustom: Bool
    let existingKey: String?
    let customSpread: CustomSpread?
    let reason: String

    struct CustomSpread: Equatable {
        let name: String
        let positions: [SpreadPosition]
    }
}
