import Foundation

/// Generic API executor that reads provider config from providers.json
/// Zero provider-specific if/else — everything is config-driven
actor APIExecutor {

    private let providersConfig: DataLoader.ProvidersConfig

    init(providersConfig: DataLoader.ProvidersConfig) {
        self.providersConfig = providersConfig
    }

    struct Message {
        let role: String
        let content: String
    }

    /// Stream chat completion, calling onToken with accumulated filtered text
    func streamChat(
        config: AIConfig,
        messages: [Message],
        onToken: @escaping @Sendable (String) -> Void
    ) async throws -> String {
        let providerKey = config.apiProvider
        guard let provider = providersConfig.provider(providerKey) else {
            throw LLMError.providerNotFound(providerKey)
        }

        let baseUrl: String
        if providerKey == "custom" && !config.apiBaseUrl.isEmpty {
            baseUrl = config.apiBaseUrl + provider.chatEndpoint
        } else {
            baseUrl = provider.baseUrl + provider.chatEndpoint
        }
        guard let url = URL(string: baseUrl) else {
            throw LLMError.invalidURL(baseUrl)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        for (headerName, template) in provider.authHeaders {
            let value = template.replacingOccurrences(of: "{apiKey}", with: config.apiKey)
            request.setValue(value, forHTTPHeaderField: headerName)
        }

        var body: [String: Any] = [
            "model": config.apiModel,
            "stream": true,
        ]

        if provider.systemMessageLocation == "separateField" {
            let systemContent = messages.first(where: { $0.role == "system" })?.content ?? ""
            let fieldName = provider.systemFieldName ?? "system"
            body[fieldName] = systemContent
            body["messages"] = messages.filter { $0.role != "system" }.map {
                ["role": $0.role, "content": $0.content]
            }
        } else {
            body["messages"] = messages.map {
                ["role": $0.role, "content": $0.content]
            }
        }

        let isReasoning = isReasoningModel(config.apiModel)
        let tempCondition = provider.conditionalFields["temperature"]
        if let tempCondition {
            let skipWhen = tempCondition["skipWhen"] as? String
            if skipWhen != "reasoningModel" || !isReasoning {
                body["temperature"] = providersConfig.temperatures["interpretation"] ?? 0.9
            }
        } else if !isReasoning {
            body["temperature"] = providersConfig.temperatures["interpretation"] ?? 0.9
        }

        if let maxTokens = provider.bodyTemplate["max_tokens"] as? Int {
            body["max_tokens"] = maxTokens
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            var errText = ""
            for try await line in bytes.lines {
                errText += line
                if errText.count > 200 { break }
            }
            throw LLMError.apiError(httpResponse.statusCode, errText)
        }

        var fullText = ""
        let deltaPath = provider.sseDeltaPath
        let eventFilter = provider.sseEventFilter
        let doneSignal = provider.sseDoneSignal

        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let data = String(line.dropFirst(6))
            if data == doneSignal { break }

            guard let jsonData = data.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                continue
            }

            if let filter = eventFilter {
                guard let eventType = parsed["type"] as? String, eventType == filter else {
                    continue
                }
            }

            let delta = resolveDotPath(deltaPath, in: parsed) as? String ?? ""
            fullText += delta
            let display = filterThinkTags(fullText)
            onToken(display)
        }

        return filterThinkTags(fullText)
    }

    /// Non-streaming chat (for JSON responses like spread recommendation)
    func chat(
        config: AIConfig,
        messages: [Message]
    ) async throws -> String {
        var result = ""
        result = try await streamChat(config: config, messages: messages) { _ in }
        return result
    }

    private func isReasoningModel(_ model: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: providersConfig.reasoningModelPattern) else {
            return false
        }
        let range = NSRange(model.startIndex..., in: model)
        return regex.firstMatch(in: model, range: range) != nil
    }

    private func filterThinkTags(_ text: String) -> String {
        var result = text
        for pattern in providersConfig.thinkTagFilters {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators) else { continue }
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Resolve dot path like "choices[0].delta.content" in JSON dict
    private func resolveDotPath(_ path: String, in obj: Any) -> Any? {
        let parts = path.components(separatedBy: ".")
        var current: Any = obj

        for part in parts {
            if let bracketRange = part.range(of: "["),
               let closeBracket = part.range(of: "]") {
                let key = String(part[..<bracketRange.lowerBound])
                let indexStr = String(part[bracketRange.upperBound..<closeBracket.lowerBound])
                guard let index = Int(indexStr),
                      let dict = current as? [String: Any],
                      let arr = dict[key] as? [Any],
                      index < arr.count else { return nil }
                current = arr[index]
            } else if let dict = current as? [String: Any] {
                guard let next = dict[part] else { return nil }
                current = next
            } else {
                return nil
            }
        }
        return current
    }
}

enum LLMError: LocalizedError {
    case providerNotFound(String)
    case invalidURL(String)
    case apiError(Int, String)
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .providerNotFound(let p): return "Provider not found: \(p)"
        case .invalidURL(let u): return "Invalid URL: \(u)"
        case .apiError(let code, let msg): return "API error (\(code)): \(msg)"
        case .notConfigured: return "AI not configured"
        }
    }
}
