import SwiftUI

struct FollowUpChatView: View {
    @Environment(LLMService.self) private var llm
    @Environment(LocalizationManager.self) private var i18n
    @Environment(ThemeManager.self) private var theme
    @Environment(\.dismiss) private var dismiss

    let question: String
    let spreadName: String
    let aiInterpretation: String
    let originalMessages: [APIExecutor.Message]
    let cardDescriptions: [PromptBuilder.CardDescription]

    @State private var chatMessages: [(id: UUID, role: String, content: String)] = []
    @State private var chatInput = ""
    @State private var chatStreamingText = ""
    @State private var isChatting = false
    @State private var suggestedQuestions: [String] = []
    @State private var hasGeneratedSuggestions = false
    @FocusState private var chatFocused: Bool

    private func t(_ key: String, _ params: [String: String] = [:]) -> String {
        i18n.t(key, params: params)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            contextCard
                                .padding(.top, 12)

                            ForEach(chatMessages, id: \.id) { msg in
                                chatBubble(role: msg.role, content: msg.content)
                            }

                            if isChatting && !chatStreamingText.isEmpty {
                                chatBubble(role: "assistant", content: chatStreamingText)
                            } else if isChatting {
                                loadingBubble
                            }

                            if chatMessages.isEmpty && !isChatting {
                                suggestionsSection
                            }

                            Spacer().frame(height: 8)
                                .id("chatBottom")
                        }
                        .padding(.horizontal, 16)
                    }
                    .onChange(of: chatMessages.count) {
                        withAnimation {
                            proxy.scrollTo("chatBottom", anchor: .bottom)
                        }
                    }
                    .onChange(of: chatStreamingText) {
                        proxy.scrollTo("chatBottom", anchor: .bottom)
                    }
                }

                inputBar
            }
            .background(theme.colors.background)
            .navigationTitle(t("chat.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("hero.cancel")) { dismiss() }
                }
            }
        }
        .task {
            if !hasGeneratedSuggestions {
                hasGeneratedSuggestions = true
                await generateSuggestions()
            }
        }
    }

    // MARK: - Context Summary

    private var contextCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                Text(t("chat.context"))
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(theme.colors.accent)

            if !question.isEmpty {
                Text("「\(question)」")
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.muted)
            }

            Text("\(spreadName) · \(cardDescriptions.count) \(t("chat.cards"))")
                .font(.system(size: 11))
                .foregroundColor(theme.colors.muted.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(theme.colors.accent.opacity(0.04))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.colors.accent.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Loading Bubble

    private var loadingBubble: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 9))
                    Text(t("chat.aiLabel"))
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(theme.colors.accent)

                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text(t("chat.thinking"))
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.muted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(theme.colors.surface)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.colors.border.opacity(0.3), lineWidth: 0.5)
                )
            }

            Spacer(minLength: 60)
        }
    }

    // MARK: - Suggestions

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if suggestedQuestions.isEmpty {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.6)
                    Text(t("chat.loadingSuggestions"))
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.muted)
                }
                .padding(.top, 8)
            } else {
                Text(t("chat.suggestionsTitle"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.colors.muted)
                    .padding(.top, 8)

                ForEach(suggestedQuestions, id: \.self) { q in
                    Button {
                        chatInput = q
                        sendFollowUp()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 11))
                            Text(q)
                                .font(.system(size: 13))
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.up.circle")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(theme.colors.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(theme.colors.accent.opacity(0.06))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(theme.colors.accent.opacity(0.15), lineWidth: 0.5)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Chat Bubble

    @ViewBuilder
    private func chatBubble(role: String, content: String) -> some View {
        let isUser = role == "user"
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if !isUser {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9))
                        Text(t("chat.aiLabel"))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(theme.colors.accent)
                }

                if isUser {
                    Text(content)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(theme.colors.accent)
                        .cornerRadius(16)
                } else {
                    MarkdownText(content, theme: theme)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(theme.colors.surface)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.colors.border.opacity(0.3), lineWidth: 0.5)
                        )
                }
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField(t("chat.placeholder"), text: $chatInput, axis: .vertical)
                .lineLimit(1...4)
                .font(.system(size: 14))
                .foregroundColor(theme.colors.foreground)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(theme.colors.surface)
                .cornerRadius(22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(theme.colors.border.opacity(0.5), lineWidth: 0.5)
                )
                .focused($chatFocused)

            Button {
                sendFollowUp()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isChatting
                            ? theme.colors.muted.opacity(0.3)
                            : theme.colors.accent
                    )
            }
            .disabled(chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isChatting)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            theme.colors.background
                .shadow(.drop(color: theme.colors.foreground.opacity(0.05), radius: 8, y: -2))
        )
    }

    // MARK: - Generate AI Suggestions

    private func generateSuggestions() async {
        let locale = i18n.locale

        let systemMsg = APIExecutor.Message(
            role: "system",
            content: """
            You are a tarot reader assistant. Based on the reading context below, generate exactly 3 short follow-up questions \
            that the querent might want to ask. Each question should be on its own line, numbered 1-3. \
            Keep each question under 20 words. Write in the same language as the user's question. \
            Do NOT include any other text, just the 3 numbered questions.
            """
        )
        let userMsg = APIExecutor.Message(
            role: "user",
            content: """
            Spread: \(spreadName)
            Question: \(question.isEmpty ? "General reading" : question)
            Cards: \(cardDescriptions.map { "\($0.name)\($0.reversed ? " (R)" : "")" }.joined(separator: ", "))
            Language: \(locale)
            """
        )

        let result = await llm.followUpChat(
            messages: [systemMsg, userMsg],
            onToken: { _ in }
        )

        if let result {
            let lines = result.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .map { line in
                    var cleaned = line
                    // Strip bullet prefix: "- "
                    if cleaned.hasPrefix("- ") { cleaned = String(cleaned.dropFirst(2)) }
                    // Strip "1. ", "2. ", "1\. " etc.
                    if let range = cleaned.range(of: #"^\d+[\\]?[\.\)、]\s*"#, options: .regularExpression) {
                        cleaned = String(cleaned[range.upperBound...])
                    }
                    // Strip bold markdown: **text** → text
                    cleaned = cleaned.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "$1", options: .regularExpression)
                    // Strip italic: *text* → text
                    cleaned = cleaned.replacingOccurrences(of: #"\*(.+?)\*"#, with: "$1", options: .regularExpression)
                    // Strip backticks
                    cleaned = cleaned.replacingOccurrences(of: "`", with: "")
                    return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .filter { !$0.isEmpty && !$0.lowercased().hasPrefix("follow") }

            await MainActor.run {
                suggestedQuestions = Array(lines.prefix(3))
            }
        }

        // Fallback if AI didn't work
        if suggestedQuestions.isEmpty {
            await MainActor.run {
                suggestedQuestions = [
                    t("chat.suggest1"),
                    t("chat.suggest2"),
                    t("chat.suggest3")
                ].filter { $0 != "chat.suggest1" && $0 != "chat.suggest2" && $0 != "chat.suggest3" }
            }
        }
    }

    // MARK: - Send

    private func sendFollowUp() {
        let text = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isChatting else { return }

        Haptic.primaryAction()
        chatInput = ""
        chatMessages.append((id: UUID(), role: "user", content: text))
        chatStreamingText = ""
        isChatting = true
        chatFocused = false

        Task {
            let history = chatMessages.map { (role: $0.role, content: $0.content) }

            let messages = PromptBuilder.followUpMessages(
                originalMessages: originalMessages,
                interpretation: aiInterpretation,
                chatHistory: history,
                locale: i18n.locale,
                t: { key, params in i18n.t(key, params: params) }
            )

            let result = await llm.followUpChat(
                messages: messages,
                onToken: { text in
                    chatStreamingText = text
                }
            )

            if let result {
                chatMessages.append((id: UUID(), role: "assistant", content: result))
                Haptic.aiComplete()
            }
            chatStreamingText = ""
            isChatting = false
        }
    }
}
