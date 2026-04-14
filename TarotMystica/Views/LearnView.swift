import SwiftUI

struct LearnView: View {
    @Environment(LocalizationManager.self) private var i18n
    @Environment(ThemeManager.self) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var activeSection: LearnSection = .lessons

    private enum LearnSection {
        case lessons, symbols
    }

    private func t(_ key: String, _ params: [String: String] = [:]) -> String {
        i18n.t(key, params: params)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    sectionTab(title: t("learn.lessons"), icon: "book.pages", section: .lessons)
                    sectionTab(title: t("learn.symbols"), icon: "eye", section: .symbols)
                }
                .background(theme.colors.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.colors.border.opacity(0.5), lineWidth: 0.5)
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)

                if activeSection == .lessons {
                    lessonsSection
                } else {
                    symbolsSection
                }
            }
            .background(theme.colors.background)
            .navigationTitle(t("learn.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("hero.cancel")) { dismiss() }
                }
            }
        }
    }

    private func sectionTab(title: String, icon: String, section: LearnSection) -> some View {
        Button {
            Haptic.selection()
            withAnimation(.easeInOut(duration: 0.2)) { activeSection = section }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 11))
                Text(title).font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(activeSection == section ? .white : theme.colors.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(activeSection == section ? theme.colors.accent : Color.clear)
            .cornerRadius(10)
            .padding(2)
        }
    }

    private var lessonsSection: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(lessonTopics, id: \.key) { topic in
                    NavigationLink {
                        LessonDetailView(topic: topic)
                            .environment(i18n)
                            .environment(theme)
                    } label: {
                        lessonCard(topic)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    private var lessonTopics: [LessonTopic] {
        [
            LessonTopic(key: "basics", icon: "sparkle", color: .purple),
            LessonTopic(key: "majorArcana", icon: "star", color: .yellow),
            LessonTopic(key: "minorArcana", icon: "suit.club", color: .blue),
            LessonTopic(key: "spreads", icon: "rectangle.grid.2x2", color: .green),
            LessonTopic(key: "reversals", icon: "arrow.up.arrow.down", color: .pink),
            LessonTopic(key: "intuition", icon: "eye.trianglebadge.exclamationmark", color: .orange),
        ]
    }

    private func lessonCard(_ topic: LessonTopic) -> some View {
        HStack(spacing: 14) {
            Image(systemName: topic.icon)
                .font(.system(size: 18))
                .foregroundColor(topic.color)
                .frame(width: 44, height: 44)
                .background(topic.color.opacity(0.1))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(t("learn.lesson.\(topic.key).title"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.colors.foreground)
                Text(t("learn.lesson.\(topic.key).desc"))
                    .font(.system(size: 11))
                    .foregroundColor(theme.colors.muted)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(theme.colors.muted.opacity(0.4))
        }
        .padding(14)
        .background(theme.colors.surface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.colors.border.opacity(0.3), lineWidth: 0.5)
        )
    }

    private var symbolsSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(t("learn.symbolsIntro"))
                    .font(.system(size: 13))
                    .foregroundColor(theme.colors.muted)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                LazyVStack(spacing: 12) {
                    ForEach(symbolCategories, id: \.key) { cat in
                        NavigationLink {
                            SymbolDetailView(category: cat)
                                .environment(i18n)
                                .environment(theme)
                        } label: {
                            symbolCard(cat)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }

    private var symbolCategories: [SymbolCategory] {
        [
            SymbolCategory(key: "elements", icon: "🔥", symbols: ["fire", "water", "air", "earth"]),
            SymbolCategory(key: "celestial", icon: "🌙", symbols: ["sun", "moon", "star", "tower"]),
            SymbolCategory(key: "figures", icon: "👑", symbols: ["fool", "magician", "priestess", "empress"]),
            SymbolCategory(key: "animals", icon: "🦁", symbols: ["lion", "eagle", "bull", "sphinx"]),
            SymbolCategory(key: "objects", icon: "⚔️", symbols: ["sword", "cup", "wand", "pentacle"]),
            SymbolCategory(key: "colors", icon: "🎨", symbols: ["red", "blue", "gold", "white"]),
        ]
    }

    private func symbolCard(_ cat: SymbolCategory) -> some View {
        HStack(spacing: 14) {
            Text(cat.icon)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(theme.colors.accent.opacity(0.06))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(t("learn.symbol.\(cat.key).title"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.colors.foreground)

                HStack(spacing: 6) {
                    ForEach(cat.symbols.prefix(4), id: \.self) { s in
                        Text(t("learn.symbol.\(cat.key).\(s).name"))
                            .font(.system(size: 9))
                            .foregroundColor(theme.colors.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.colors.accent.opacity(0.06))
                            .cornerRadius(6)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(theme.colors.muted.opacity(0.4))
        }
        .padding(14)
        .background(theme.colors.surface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.colors.border.opacity(0.3), lineWidth: 0.5)
        )
    }
}

struct LessonTopic {
    let key: String
    let icon: String
    let color: Color
}

struct SymbolCategory {
    let key: String
    let icon: String
    let symbols: [String]
}

struct LessonDetailView: View {
    @Environment(LocalizationManager.self) private var i18n
    @Environment(ThemeManager.self) private var theme

    let topic: LessonTopic

    private func t(_ key: String) -> String { i18n.t(key) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: topic.icon)
                        .font(.system(size: 24))
                        .foregroundColor(topic.color)
                        .frame(width: 48, height: 48)
                        .background(topic.color.opacity(0.1))
                        .cornerRadius(14)

                    Text(t("learn.lesson.\(topic.key).title"))
                        .font(.system(size: 22, weight: .light, design: .serif))
                        .foregroundColor(theme.colors.foreground)
                }

                Rectangle()
                    .fill(theme.colors.border.opacity(0.3))
                    .frame(height: 0.5)

                let content = t("learn.lesson.\(topic.key).content")
                if content != "learn.lesson.\(topic.key).content" {
                    MarkdownText(content, theme: theme)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(t("learn.comingSoon"))
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                }
            }
            .padding(20)
        }
        .background(theme.colors.background)
        .navigationTitle(t("learn.lesson.\(topic.key).title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SymbolDetailView: View {
    @Environment(LocalizationManager.self) private var i18n
    @Environment(ThemeManager.self) private var theme

    let category: SymbolCategory

    private func t(_ key: String) -> String { i18n.t(key) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                let intro = t("learn.symbol.\(category.key).intro")
                if intro != "learn.symbol.\(category.key).intro" {
                    Text(intro)
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.muted)
                }

                ForEach(category.symbols, id: \.self) { symbol in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(t("learn.symbol.\(category.key).\(symbol).name"))
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .foregroundColor(theme.colors.foreground)

                        let meaning = t("learn.symbol.\(category.key).\(symbol).meaning")
                        if meaning != "learn.symbol.\(category.key).\(symbol).meaning" {
                            Text(meaning)
                                .font(.system(size: 13))
                                .foregroundColor(theme.colors.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        let cards = t("learn.symbol.\(category.key).\(symbol).cards")
                        if cards != "learn.symbol.\(category.key).\(symbol).cards" {
                            HStack(spacing: 4) {
                                Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                                    .font(.system(size: 9))
                                Text(cards)
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(theme.colors.accent.opacity(0.7))
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.colors.surface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.colors.border.opacity(0.3), lineWidth: 0.5)
                    )
                }
            }
            .padding(20)
        }
        .background(theme.colors.background)
        .navigationTitle(t("learn.symbol.\(category.key).title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
