import Foundation
import SwiftData

// MARK: - Schema versioning (add new versions here when modifying ReadingEntry)

enum ReadingSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [ReadingEntry.self] }
}

enum ReadingMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [ReadingSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

/// A saved tarot reading entry for the journal
@Model
final class ReadingEntry {
    var id: UUID
    var date: Date
    var question: String
    var spreadKey: String?       // nil for custom spreads
    var spreadName: String
    var interpretation: String   // AI interpretation text
    var locale: String           // language used
    var style: String            // interpretation style used

    // Serialized card data (lightweight, no images)
    var cardsJSON: Data?         // JSON array of SavedCard

    init(
        question: String,
        spreadKey: String?,
        spreadName: String,
        interpretation: String,
        cards: [SavedCard],
        locale: String,
        style: String
    ) {
        self.id = UUID()
        self.date = Date()
        self.question = question
        self.spreadKey = spreadKey
        self.spreadName = spreadName
        self.interpretation = interpretation
        self.locale = locale
        self.style = style
        self.cardsJSON = try? JSONEncoder().encode(cards)
    }

    var cards: [SavedCard] {
        guard let data = cardsJSON else { return [] }
        return (try? JSONDecoder().decode([SavedCard].self, from: data)) ?? []
    }
}

/// Lightweight card info for persistence (no images, just IDs)
struct SavedCard: Codable {
    let cardId: Int
    let position: String
    let reversed: Bool
}
