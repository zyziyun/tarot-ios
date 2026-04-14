import Foundation

/// Generates 78 TarotCards from cards.json config
enum CardGenerator {

    static func generate(from config: DataLoader.CardsConfig) -> [TarotCard] {
        var cards: [TarotCard] = []

        // Major Arcana (22)
        for entry in config.majorArcana {
            cards.append(TarotCard(
                id: entry.id,
                image: entry.image,
                arcana: .major,
                suit: nil
            ))
        }

        // Minor Arcana (56)
        var id = config.minorArcana.startId
        for suitName in config.minorArcana.suits {
            guard let suit = TarotCard.Suit(rawValue: suitName) else { continue }
            for rank in config.minorArcana.ranks {
                let image = config.minorArcana.imagePattern
                    .replacingOccurrences(of: "{suit}", with: suitName)
                    .replacingOccurrences(of: "{rank}", with: rank)
                cards.append(TarotCard(
                    id: id,
                    image: image,
                    arcana: .minor,
                    suit: suit
                ))
                id += 1
            }
        }

        return cards
    }
}
