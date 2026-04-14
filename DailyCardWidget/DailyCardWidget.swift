import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct DailyCardProvider: TimelineProvider {

    func placeholder(in context: Context) -> DailyCardEntry {
        DailyCardEntry(date: Date(), cardId: 0, cardName: "The Fool", cardImage: "00-fool", isReversed: false, meaning: "New beginnings, innocence, spontaneity")
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyCardEntry) -> Void) {
        completion(generateEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyCardEntry>) -> Void) {
        let entry = generateEntry(for: Date())

        // Refresh at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())
            .map { calendar.startOfDay(for: $0) }
            ?? Date().addingTimeInterval(86400)
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    private func generateEntry(for date: Date) -> DailyCardEntry {
        let cards = loadCards()
        let locale = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
        let i18n = loadI18n(locale: String(locale))

        // Use date as seed for deterministic daily card
        let calendar = Calendar.current
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        let seed = day &* 2654435761 // Knuth multiplicative hash
        let idx = abs(seed) % cards.count

        let card = cards[idx]
        let isReversed = (seed / cards.count) % 3 == 0 // ~33% chance reversed

        let name = i18n["cards.\(card.id).name"] ?? card.fallbackName
        let meaningKey = isReversed ? "cards.\(card.id).reversed" : "cards.\(card.id).upright"
        let meaning = i18n[meaningKey] ?? ""

        return DailyCardEntry(
            date: date,
            cardId: card.id,
            cardName: name,
            cardImage: card.image,
            isReversed: isReversed,
            meaning: meaning
        )
    }

    // MARK: - Data Loading

    private struct SimpleCard {
        let id: Int
        let image: String
        let fallbackName: String
    }

    private func loadCards() -> [SimpleCard] {
        guard let url = Bundle.main.url(forResource: "cards", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [SimpleCard(id: 0, image: "00-fool", fallbackName: "The Fool")]
        }

        var result: [SimpleCard] = []

        // Major arcana
        if let majors = json["majorArcana"] as? [[String: Any]] {
            for m in majors {
                let id = m["id"] as? Int ?? 0
                let image = m["image"] as? String ?? ""
                result.append(SimpleCard(id: id, image: image, fallbackName: "Card \(id)"))
            }
        }

        // Minor arcana
        if let minor = json["minorArcana"] as? [String: Any],
           let suits = minor["suits"] as? [String],
           let ranks = minor["ranks"] as? [String],
           let startId = minor["startId"] as? Int,
           let pattern = minor["imagePattern"] as? String {
            var idx = startId
            for suit in suits {
                for rank in ranks {
                    let image = pattern
                        .replacingOccurrences(of: "{suit}", with: suit)
                        .replacingOccurrences(of: "{rank}", with: rank)
                    result.append(SimpleCard(id: idx, image: image, fallbackName: "\(rank) of \(suit)"))
                    idx += 1
                }
            }
        }

        return result.isEmpty ? [SimpleCard(id: 0, image: "00-fool", fallbackName: "The Fool")] : result
    }

    private func loadI18n(locale: String) -> [String: String] {
        let supportedLocales = ["en", "zh", "fr", "es"]
        let resolvedLocale = supportedLocales.contains(locale) ? locale : "en"

        guard let url = Bundle.main.url(forResource: resolvedLocale, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }

        // Flatten nested JSON into dot-notation keys
        var flat: [String: String] = [:]
        func flatten(_ dict: [String: Any], prefix: String) {
            for (k, v) in dict {
                let key = prefix.isEmpty ? k : "\(prefix).\(k)"
                if let s = v as? String {
                    flat[key] = s
                } else if let nested = v as? [String: Any] {
                    flatten(nested, prefix: key)
                }
            }
        }
        flatten(json, prefix: "")
        return flat
    }
}

// MARK: - Entry

struct DailyCardEntry: TimelineEntry {
    let date: Date
    let cardId: Int
    let cardName: String
    let cardImage: String
    let isReversed: Bool
    let meaning: String
}

// MARK: - Widget View

struct DailyCardWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: DailyCardEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: 0x1a1225), Color(hex: 0x0d0a14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 6) {
                // Card image
                cardImageView
                    .frame(width: 60, height: 90)
                    .rotationEffect(entry.isReversed ? .degrees(180) : .zero)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(color: Color(hex: 0xc9a84c).opacity(0.3), radius: 8)

                Text(entry.cardName)
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if entry.isReversed {
                    Text("Reversed")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Color(hex: 0xe88ca5))
                }
            }
            .padding(12)
        }
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x1a1225), Color(hex: 0x0d0a14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                // Card
                cardImageView
                    .frame(width: 80, height: 120)
                    .rotationEffect(entry.isReversed ? .degrees(180) : .zero)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: Color(hex: 0xc9a84c).opacity(0.3), radius: 10)

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text("✦ Daily Card")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color(hex: 0xc9a84c).opacity(0.6))

                    Text(entry.cardName)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundColor(.white)

                    if entry.isReversed {
                        Text("Reversed")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: 0xe88ca5))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: 0xe88ca5).opacity(0.15))
                            .cornerRadius(4)
                    }

                    if !entry.meaning.isEmpty {
                        Text(entry.meaning)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(3)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }

    // MARK: - Card Image

    @ViewBuilder
    private var cardImageView: some View {
        let name = entry.cardImage.replacingOccurrences(of: ".webp", with: "")
        if let path = Bundle.main.path(forResource: name, ofType: "webp"),
           let uiImage = UIImage(contentsOfFile: path) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x6b4fa0), Color(hex: 0x4a3570)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Text("✦")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: 0xc9a84c).opacity(0.5))
                )
        }
    }
}

// MARK: - Widget Configuration

@main
struct DailyCardWidgetBundle: Widget {
    let kind: String = "DailyCardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyCardProvider()) { entry in
            DailyCardWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(hex: 0x0d0a14)
                }
        }
        .configurationDisplayName("Daily Card")
        .description("Your daily tarot card guidance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    DailyCardWidgetBundle()
} timeline: {
    DailyCardEntry(date: .now, cardId: 0, cardName: "The Fool", cardImage: "00-fool", isReversed: false, meaning: "New beginnings")
}

#Preview(as: .systemMedium) {
    DailyCardWidgetBundle()
} timeline: {
    DailyCardEntry(date: .now, cardId: 9, cardName: "The Hermit", cardImage: "09-hermit", isReversed: true, meaning: "Inner wisdom, contemplation, solitude and reflection on life's deeper questions")
}
