import Foundation

/// Loads shared JSON config files from app bundle
enum DataLoader {

    // MARK: - Generic JSON loading

    static func loadJSON<T: Decodable>(_ filename: String, as type: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            #if DEBUG
            print("[DataLoader] Missing or unreadable \(filename).json")
            #endif
            return nil
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("[DataLoader] Cannot decode \(filename).json: \(error)")
            #endif
            return nil
        }
    }

    static func loadRawJSON(_ filename: String) -> [String: Any] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return json
    }

    // MARK: - Providers config (loaded as raw JSON due to mixed types)

    struct ProvidersConfig {
        let raw: [String: Any]

        var temperatures: [String: Double] {
            raw["temperatures"] as? [String: Double] ?? [:]
        }
        var reasoningModelPattern: String {
            raw["reasoningModelPattern"] as? String ?? ""
        }
        var thinkTagFilters: [String] {
            raw["thinkTagFilters"] as? [String] ?? []
        }
        var responseJsonExtractPattern: String {
            raw["responseJsonExtractPattern"] as? String ?? ""
        }
        var providers: [String: [String: Any]] {
            raw["providers"] as? [String: [String: Any]] ?? [:]
        }
        var localModels: [String: Any] {
            raw["localModels"] as? [String: Any] ?? [:]
        }
        var prompts: [String: Any] {
            raw["prompts"] as? [String: Any] ?? [:]
        }
        var defaultConfig: [String: Any] {
            raw["defaultConfig"] as? [String: Any] ?? [:]
        }

        func provider(_ key: String) -> ProviderInfo? {
            guard let dict = providers[key] else { return nil }
            return ProviderInfo(dict: dict)
        }
    }

    struct ProviderInfo {
        let dict: [String: Any]

        var name: String { dict["name"] as? String ?? "" }
        var baseUrl: String { dict["baseUrl"] as? String ?? "" }
        var defaultModel: String { dict["defaultModel"] as? String ?? "" }
        var models: [String] { dict["models"] as? [String] ?? [] }

        var authHeaders: [String: String] {
            (dict["auth"] as? [String: Any])?["headers"] as? [String: String] ?? [:]
        }
        var chatEndpoint: String {
            (dict["endpoints"] as? [String: Any])?["chat"] as? String ?? "/chat/completions"
        }

        var request: [String: Any] { dict["request"] as? [String: Any] ?? [:] }
        var bodyTemplate: [String: Any] { request["bodyTemplate"] as? [String: Any] ?? [:] }
        var systemMessageLocation: String { request["systemMessageLocation"] as? String ?? "inMessages" }
        var systemFieldName: String? { request["systemFieldName"] as? String }
        var conditionalFields: [String: [String: Any]] {
            request["conditionalFields"] as? [String: [String: Any]] ?? [:]
        }

        var sseDeltaPath: String {
            (dict["sse"] as? [String: Any])?["deltaPath"] as? String ?? ""
        }
        var sseEventFilter: String? {
            (dict["sse"] as? [String: Any])?["eventFilter"] as? String
        }
        var sseDoneSignal: String {
            (dict["sse"] as? [String: Any])?["doneSignal"] as? String ?? "[DONE]"
        }
    }

    static func loadProviders() -> ProvidersConfig {
        ProvidersConfig(raw: loadRawJSON("providers"))
    }

    // MARK: - Cards config

    struct CardsConfig: Decodable {
        let majorArcana: [MajorCard]
        let minorArcana: MinorConfig
        let reversalChance: Double
        let totalCount: Int

        struct MajorCard: Decodable {
            let id: Int
            let image: String
        }
        struct MinorConfig: Decodable {
            let suits: [String]
            let ranks: [String]
            let startId: Int
            let imagePattern: String
        }
    }

    static func loadCards() -> CardsConfig {
        loadJSON("cards", as: CardsConfig.self) ?? CardsConfig(
            majorArcana: [MajorCard(id: 0, image: "00-fool")],
            minorArcana: MinorConfig(suits: [], ranks: [], startId: 22, imagePattern: ""),
            reversalChance: 0.3,
            totalCount: 1
        )
    }

    private typealias MajorCard = CardsConfig.MajorCard
    private typealias MinorConfig = CardsConfig.MinorConfig

    // MARK: - Spreads config

    struct SpreadsConfig: Decodable {
        let spreads: [SpreadDef]
        let phaseFlow: PhaseFlow
        let aiTriggers: [String: AITrigger]

        struct SpreadDef: Decodable {
            let key: String
            let icon: String
            let positionCount: Int
        }
        struct PhaseFlow: Decodable {
            let phases: [String]
            let backTransitions: [String: String]
        }
        struct AITrigger: Decodable {
            let triggerPhase: String
            let requires: [String]
        }
    }

    static func loadSpreads() -> SpreadsConfig {
        loadJSON("spreads", as: SpreadsConfig.self) ?? SpreadsConfig(
            spreads: [],
            phaseFlow: PhaseFlow(phases: ["hero"], backTransitions: [:]),
            aiTriggers: [:]
        )
    }

    private typealias PhaseFlow = SpreadsConfig.PhaseFlow
}
