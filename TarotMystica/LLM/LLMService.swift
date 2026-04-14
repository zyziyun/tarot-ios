import Foundation

/// Main LLM service that coordinates both API and local (MLX) inference
@Observable
final class LLMService {
    var config: AIConfig
    var isReady: Bool = false
    var isLoading: Bool = false
    var isGenerating: Bool = false
    var error: String?

    let mlxService = MLXService()
    private let apiExecutor: APIExecutor
    private let providersConfig: DataLoader.ProvidersConfig

    var localModels: [MLXService.LocalModel] = []

    init(providersConfig: DataLoader.ProvidersConfig) {
        self.config = AIConfig.load()
        self.providersConfig = providersConfig
        self.apiExecutor = APIExecutor(providersConfig: providersConfig)
        self.localModels = MLXService.availableModels(from: providersConfig)

        if config.mode == .api && config.configured {
            isReady = true
        }

        // Returning user: reload their previously chosen local model
        if config.mode == .local && config.configured && !config.localModel.isEmpty {
            Task { @MainActor in
                await self.loadLocalModel(config.localModel)
            }
        }
    }

    func updateConfig(_ update: (inout AIConfig) -> Void) {
        update(&config)
        config.save()
        refreshReadyState()
    }

    private func refreshReadyState() {
        switch config.mode {
        case .api:
            isReady = config.configured
        case .local:
            isReady = mlxService.isReady
        }
    }

    // MARK: - Local Model Management

    @MainActor
    func loadLocalModel(_ modelId: String) async {
        isLoading = true
        error = nil
        await mlxService.loadModel(modelId)

        if mlxService.isReady {
            TarotAnalytics.logModelSelected(modelId)
            updateConfig { c in
                c.mode = .local
                c.localModel = modelId
                c.configured = true
            }
        } else if case .error(let msg) = mlxService.state {
            error = msg
        }
        isLoading = false
    }

    func unloadLocalModel() {
        mlxService.unload()
        refreshReadyState()
    }

    // MARK: - Interpret Reading (streaming)

    @MainActor
    func interpretReading(
        question: String,
        spreadName: String,
        cards: [PromptBuilder.CardDescription],
        locale: String = "en",
        t: @escaping (String, [String: String]) -> String,
        onToken: @escaping (String) -> Void
    ) async -> String? {
        guard config.configured else {
            error = "AI not configured"
            return nil
        }

        isGenerating = true
        error = nil

        let isLocal = config.mode == .local
        let messages = PromptBuilder.interpretationMessages(
            question: question,
            spreadName: spreadName,
            cards: cards,
            style: config.interpretationStyle,
            isLocal: isLocal,
            locale: locale,
            t: t
        )

        do {
            let result: String
            if isLocal {
                result = try await mlxService.generate(
                    messages: messages,
                    temperature: 0.65
                ) { text in
                    Task { @MainActor in onToken(text) }
                }
            } else {
                result = try await apiExecutor.streamChat(
                    config: config,
                    messages: messages
                ) { text in
                    Task { @MainActor in onToken(text) }
                }
            }
            isGenerating = false
            return result
        } catch {
            isGenerating = false
            self.error = error.localizedDescription
            return nil
        }
    }

    // MARK: - Follow-up Chat (continuing conversation after initial reading)

    @MainActor
    func followUpChat(
        messages: [APIExecutor.Message],
        onToken: @escaping (String) -> Void
    ) async -> String? {
        guard config.configured else {
            error = "AI not configured"
            return nil
        }

        isGenerating = true
        error = nil

        do {
            let result: String
            if config.mode == .local {
                result = try await mlxService.generate(
                    messages: messages,
                    temperature: 0.8
                ) { text in
                    Task { @MainActor in onToken(text) }
                }
            } else {
                result = try await apiExecutor.streamChat(
                    config: config,
                    messages: messages
                ) { text in
                    Task { @MainActor in onToken(text) }
                }
            }
            isGenerating = false
            return result
        } catch {
            isGenerating = false
            self.error = error.localizedDescription
            return nil
        }
    }

    // MARK: - Recommend Spread

    @MainActor
    func recommendSpread(
        question: String,
        spreads: [(key: String, name: String, positions: [String])],
        locale: String = "en",
        t: @escaping (String, [String: String]) -> String
    ) async -> AISpreadRecommendation? {
        guard config.configured else { return nil }

        let messages = PromptBuilder.recommendationMessages(
            question: question,
            spreads: spreads,
            locale: locale,
            t: t
        )

        do {
            let result: String
            if config.mode == .local {
                result = try await mlxService.generate(
                    messages: messages,
                    temperature: 0.7
                ) { _ in }
            } else {
                result = try await apiExecutor.chat(config: config, messages: messages)
            }

            guard let range = result.range(of: #"\{[\s\S]*\}"#, options: .regularExpression),
                  let data = result[range].data(using: .utf8) else { return nil }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let json else { return nil }

            let isCustom = json["isCustom"] as? Bool ?? false
            let existingKey = json["existingKey"] as? String
            let reason = json["reason"] as? String ?? ""

            var customSpread: AISpreadRecommendation.CustomSpread?
            if isCustom, let cs = json["customSpread"] as? [String: Any] {
                let name = cs["name"] as? String ?? ""
                let positionsRaw = cs["positions"] as? [[String: String]] ?? []
                let positions = positionsRaw.map {
                    SpreadPosition(label: $0["label"] ?? "", description: $0["description"] ?? "")
                }
                customSpread = .init(name: name, positions: positions)
            }

            return AISpreadRecommendation(
                isCustom: isCustom,
                existingKey: existingKey,
                customSpread: customSpread,
                reason: reason
            )
        } catch {
            return nil
        }
    }
}
