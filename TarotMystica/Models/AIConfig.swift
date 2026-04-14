import Foundation

struct AIConfig: Codable, Equatable {
    var mode: Mode = .api
    var configured: Bool = false
    var localModel: String = ""
    var apiProvider: String = "openai"
    var apiModel: String = "gpt-4.1"
    var apiKey: String = ""
    var apiBaseUrl: String = ""
    var interpretationStyle: InterpretationStyle = .standard

    enum Mode: String, Codable {
        case local, api
    }

    enum InterpretationStyle: String, Codable, CaseIterable {
        case concise     // Brief, to-the-point
        case standard    // Default balanced style
        case poetic      // Mystical, literary
        case analytical  // Structured, detailed
    }

    static let storageKey = "tarot-ai-config"

    static func load() -> AIConfig {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let config = try? JSONDecoder().decode(AIConfig.self, from: data) else {
            return AIConfig()
        }
        return config
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
