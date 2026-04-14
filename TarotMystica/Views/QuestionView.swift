import SwiftUI

struct QuestionView: View {
    @Environment(AppState.self) private var state
    @Environment(LocalizationManager.self) private var i18n
    @Environment(ThemeManager.self) private var theme

    @State private var question = ""
    @FocusState private var isFocused: Bool

    @State private var selectedPlaceholder: String
    @State private var contentOpacity = 0.0
    @State private var selectedTopic: String?

    init() {
        _selectedPlaceholder = State(initialValue: [
            "question.placeholder1",
            "question.placeholder2",
            "question.placeholder3",
            "question.placeholder4",
        ].randomElement() ?? "question.placeholder1")
    }

    private func t(_ key: String, _ params: [String: String] = [:]) -> String {
        i18n.t(key, params: params)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) { state.phase = .hero }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text(t("common.back"))
                                .font(.system(size: 15))
                        }
                        .foregroundColor(theme.colors.accent)
                        .padding(.vertical, 8)
                        .padding(.trailing, 8)
                        .contentShape(Rectangle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer().frame(height: 60)

                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text(t("question.title"))
                            .font(.system(size: 26, weight: .light, design: .serif))
                            .foregroundColor(theme.colors.foreground)
                            .multilineTextAlignment(.center)

                        Text(t("question.subtitle"))
                            .font(.system(size: 13))
                            .foregroundColor(theme.colors.muted)
                    }

                    TextField(t(selectedPlaceholder), text: $question, axis: .vertical)
                        .lineLimit(3)
                        .font(.system(size: 15))
                        .foregroundColor(theme.colors.foreground)
                        .padding(.vertical, 14)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(theme.colors.border)
                                .frame(height: 0.5)
                        }
                        .focused($isFocused)
                        .padding(.horizontal, 32)

                    topicTags
                        .padding(.horizontal, 32)
                }
                .opacity(contentOpacity)

                Spacer()

                VStack(spacing: 14) {
                    Button {
                        submit(question: question)
                    } label: {
                        Text(t("question.continue"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(theme.colors.accent)
                            .cornerRadius(28)
                            .shadow(color: theme.colors.accent.opacity(0.2), radius: 8, y: 2)
                    }

                    Button {
                        submit(question: "")
                    } label: {
                        Text(t("question.skip"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(theme.colors.muted.opacity(0.8))
                            .underline()
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            isFocused = true
            withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
                contentOpacity = 1.0
            }
        }
    }

    private var topicTags: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(["Career", "Love", "Wealth", "Health", "Growth"], id: \.self) { topic in
                    let key = "question.topic\(topic)"
                    let isSelected = selectedTopic == topic
                    Button {
                        Haptic.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if isSelected {
                                selectedTopic = nil
                                question = ""
                            } else {
                                selectedTopic = topic
                                question = t(key)
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(topicIcon(topic))
                                .font(.system(size: 13))
                            Text(topicLabel(topic))
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(isSelected ? .white : theme.colors.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(isSelected ? theme.colors.accent : theme.colors.accent.opacity(0.08))
                        .cornerRadius(16)
                    }
                }
            }
        }
    }

    private func topicIcon(_ topic: String) -> String {
        switch topic {
        case "Career": return "💼"
        case "Love": return "❤️"
        case "Wealth": return "💰"
        case "Health": return "🌿"
        case "Growth": return "🌱"
        default: return "✦"
        }
    }

    private func topicLabel(_ topic: String) -> String {
        switch topic {
        case "Career": return t("question.tagCareer")
        case "Love": return t("question.tagLove")
        case "Wealth": return t("question.tagWealth")
        case "Health": return t("question.tagHealth")
        case "Growth": return t("question.tagGrowth")
        default: return topic
        }
    }

    private func submit(question: String) {
        Haptic.primaryAction()
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        state.question = q.isEmpty ? t(selectedPlaceholder) : q
        withAnimation(.easeInOut(duration: 0.4)) {
            state.phase = .choose
        }
    }
}
