import Foundation

/// Builds prompts for AI interpretation and spread recommendation
/// using i18n keys from providers.json prompt definitions
enum PromptBuilder {

    struct CardDescription {
        let name: String
        let position: String
        let reversed: Bool
        let uprightMeaning: String
        let reversedMeaning: String
        // Extended context for richer prompts
        var description: String = ""
        var loveMeaning: String = ""
        var careerMeaning: String = ""
        var keywords: String = ""
    }

    /// Returns a style instruction to inject into the system prompt
    static func styleInstruction(
        _ style: AIConfig.InterpretationStyle,
        t: (String, [String: String]) -> String
    ) -> String {
        let key = "ai.style.\(style.rawValue)"
        let instruction = t(key, [:])
        // If key not found (returns key itself), use empty string
        if instruction == key { return "" }
        return "\n\n" + instruction
    }

    private static func languageInstruction(_ locale: String) -> String {
        switch locale {
        case "zh": return "\n\n⚠️ 重要：你必须完全使用中文回答。"
        case "fr": return "\n\n⚠️ Important : Vous devez répondre entièrement en français."
        case "es": return "\n\n⚠️ Importante: Debes responder completamente en español."
        default: return "\n\n⚠️ Important: You must respond entirely in English."
        }
    }

    /// Build messages for tarot reading interpretation
    static func interpretationMessages(
        question: String,
        spreadName: String,
        cards: [CardDescription],
        style: AIConfig.InterpretationStyle = .standard,
        isLocal: Bool = false,
        locale: String = "en",
        t: (String, [String: String]) -> String
    ) -> [APIExecutor.Message] {
        if isLocal {
            return localInterpretationMessages(
                question: question, spreadName: spreadName,
                cards: cards, locale: locale, t: t
            )
        }

        let cardDescriptions = cards.map { card in
            let key = card.reversed ? "ai.cardDescReversed" : "ai.cardDescUpright"
            return t(key, [
                "position": card.position,
                "name": card.name,
                "meaning": card.reversed ? card.reversedMeaning : card.uprightMeaning,
            ])
        }.joined(separator: "\n")

        let systemMsg = t("ai.systemPrompt", ["spreadName": spreadName])
            + styleInstruction(style, t: t)
            + languageInstruction(locale)
        let userMsg = t("ai.userPrompt", ["question": question, "cardDescriptions": cardDescriptions])

        return [
            .init(role: "system", content: systemMsg),
            .init(role: "user", content: userMsg),
        ]
    }

    // MARK: - Simplified Local Model Prompt

    /// For on-device small models (2-8B): shorter prompt, explicit card meanings,
    /// constrained output structure to reduce hallucination.
    /// Uses i18n keys: ai.localSystemPrompt, ai.localUserPrompt, ai.localCardDesc, ai.localCardDescReversed
    private static func localInterpretationMessages(
        question: String,
        spreadName: String,
        cards: [CardDescription],
        locale: String,
        t: (String, [String: String]) -> String
    ) -> [APIExecutor.Message] {
        // Build rich card descriptions using i18n templates
        let cardDescriptions = cards.enumerated().map { idx, card in
            let key = card.reversed ? "ai.localCardDescReversed" : "ai.localCardDesc"
            let result = t(key, [
                "index": "\(idx + 1)",
                "name": card.name,
                "position": card.position,
                "meaning": card.reversed ? card.reversedMeaning : card.uprightMeaning,
                "description": card.description,
                "keywords": card.keywords,
            ])
            // If the i18n key wasn't found, fall back to a simple format
            if result == key {
                let orientation = card.reversed ? "REVERSED" : "Upright"
                return "Card \(idx + 1): \(card.name) [\(card.position)] (\(orientation)) — \(card.reversed ? card.reversedMeaning : card.uprightMeaning)"
            }
            return result
        }.joined(separator: "\n\n")

        let systemPrompt = t("ai.localSystemPrompt", ["spreadName": spreadName])
            + languageInstruction(locale)
        let userPrompt = t("ai.localUserPrompt", [
            "spreadName": spreadName,
            "question": question,
            "cardDescriptions": cardDescriptions,
        ])

        return [
            .init(role: "system", content: systemPrompt),
            .init(role: "user", content: userPrompt),
        ]
    }

    /// Build messages for follow-up conversation after initial reading
    static func followUpMessages(
        originalMessages: [APIExecutor.Message],
        interpretation: String,
        chatHistory: [(role: String, content: String)],
        locale: String = "en",
        t: (String, [String: String]) -> String
    ) -> [APIExecutor.Message] {
        var messages = originalMessages

        // Add the AI's initial interpretation as assistant response
        messages.append(.init(role: "assistant", content: interpretation))

        // Add follow-up system instruction
        let followUpInstruction = t("ai.followUpInstruction", [:])
        if followUpInstruction != "ai.followUpInstruction" {
            messages.append(.init(role: "system", content: followUpInstruction + languageInstruction(locale)))
        }

        // Add chat history
        for entry in chatHistory {
            messages.append(.init(role: entry.role, content: entry.content))
        }

        return messages
    }

    /// Build messages for spread recommendation
    static func recommendationMessages(
        question: String,
        spreads: [(key: String, name: String, positions: [String])],
        locale: String = "en",
        t: (String, [String: String]) -> String
    ) -> [APIExecutor.Message] {
        let spreadList = spreads.map { s in
            "- \(s.key): \(s.name)（\(s.positions.count) cards，positions：\(s.positions.joined(separator: "、"))）"
        }.joined(separator: "\n")

        let systemMsg = [
            t("ai.recommendSystemIntro", [:]),
            "",
            t("ai.recommendChoice", [:]),
            "",
            t("ai.recommendExistingSpreads", ["spreadList": spreadList]),
            "",
            t("ai.recommendFormat", [:]),
            languageInstruction(locale),
        ].joined(separator: "\n")

        let userMsg = t("ai.recommendUserPrompt", ["question": question])

        return [
            .init(role: "system", content: systemMsg),
            .init(role: "user", content: userMsg),
        ]
    }
}
