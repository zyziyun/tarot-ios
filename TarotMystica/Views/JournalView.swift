import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(LocalizationManager.self) private var i18n
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \ReadingEntry.date, order: .reverse)
    private var entries: [ReadingEntry]

    @State private var selectedEntry: ReadingEntry?

    private func t(_ key: String, _ params: [String: String] = [:]) -> String {
        i18n.t(key, params: params)
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    journalList
                }
            }
            .background(theme.colors.background)
            .navigationTitle(t("journal.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("hero.cancel")) { dismiss() }
                }
            }
            .sheet(item: $selectedEntry) { entry in
                JournalDetailView(entry: entry)
                    .environment(i18n)
                    .environment(theme)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundColor(theme.colors.muted.opacity(0.3))
            Text(t("journal.empty"))
                .font(.system(size: 15))
                .foregroundColor(theme.colors.muted)
            Text(t("journal.emptyHint"))
                .font(.system(size: 12))
                .foregroundColor(theme.colors.muted.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var journalList: some View {
        ScrollView {
            // Stats summary
            if entries.count >= 3 {
                statsSummary
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }

            LazyVStack(spacing: 12) {
                ForEach(entries) { entry in
                    journalCard(entry)
                        .onTapGesture {
                            selectedEntry = entry
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Stats Summary

    private var statsSummary: some View {
        let totalReadings = entries.count
        let thisMonth = entries.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }.count

        // Most drawn cards
        let allCardIds = entries.flatMap { $0.cards.map { $0.cardId } }
        let cardCounts = Dictionary(grouping: allCardIds, by: { $0 }).mapValues { $0.count }
        let topCard = cardCounts.max(by: { $0.value < $1.value })

        return VStack(spacing: 12) {
            HStack(spacing: 16) {
                statPill(value: "\(totalReadings)", label: t("journal.totalReadings"))
                statPill(value: "\(thisMonth)", label: t("journal.thisMonth"))
                if let top = topCard {
                    statPill(
                        value: i18n.t("cards.\(top.key).name"),
                        label: t("journal.mostDrawn")
                    )
                }
            }
        }
        .padding(14)
        .background(theme.colors.surface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.colors.border.opacity(0.3), lineWidth: 0.5)
        )
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.colors.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(theme.colors.muted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Journal Card

    private func journalCard(_ entry: ReadingEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.spreadName)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundColor(theme.colors.foreground)

                Spacer()

                Text(formatDate(entry.date))
                    .font(.system(size: 10))
                    .foregroundColor(theme.colors.muted)
            }

            if !entry.question.isEmpty {
                Text("「\(entry.question)」")
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.muted)
                    .lineLimit(2)
            }

            // Card pills
            HStack(spacing: 6) {
                ForEach(entry.cards, id: \.cardId) { card in
                    HStack(spacing: 3) {
                        Text(i18n.t("cards.\(card.cardId).name"))
                            .font(.system(size: 9))
                        if card.reversed {
                            Text("R")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(theme.colors.accentPink)
                        }
                    }
                    .foregroundColor(theme.colors.accent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(theme.colors.accent.opacity(0.06))
                    .cornerRadius(8)
                }
            }

            // Preview of interpretation
            Text(entry.interpretation)
                .font(.system(size: 11))
                .foregroundColor(theme.colors.muted.opacity(0.7))
                .lineLimit(2)
        }
        .padding(14)
        .background(theme.colors.surface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.colors.border.opacity(0.3), lineWidth: 0.5)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: i18n.locale)
        return formatter.string(from: date)
    }
}

// MARK: - Journal Detail View

struct JournalDetailView: View {
    @Environment(LocalizationManager.self) private var i18n
    @Environment(ThemeManager.self) private var theme
    @Environment(\.dismiss) private var dismiss

    let entry: ReadingEntry

    private func t(_ key: String, _ params: [String: String] = [:]) -> String {
        i18n.t(key, params: params)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.spreadName)
                            .font(.system(size: 22, weight: .light, design: .serif))
                            .foregroundColor(theme.colors.foreground)

                        if !entry.question.isEmpty {
                            Text("「\(entry.question)」")
                                .font(.system(size: 13))
                                .foregroundColor(theme.colors.muted)
                        }

                        HStack(spacing: 12) {
                            Label(formatDate(entry.date), systemImage: "calendar")
                            Label(entry.style.capitalized, systemImage: "text.quote")
                        }
                        .font(.system(size: 10))
                        .foregroundColor(theme.colors.muted.opacity(0.6))
                    }

                    // Cards
                    VStack(spacing: 10) {
                        ForEach(entry.cards, id: \.cardId) { card in
                            HStack(spacing: 10) {
                                Image(systemName: card.reversed ? "arrow.down.circle" : "arrow.up.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(card.reversed ? theme.colors.accentPink : theme.colors.accent)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(card.position)
                                        .font(.system(size: 10))
                                        .foregroundColor(theme.colors.muted)
                                    HStack(spacing: 6) {
                                        Text(i18n.t("cards.\(card.cardId).name"))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(theme.colors.foreground)
                                        if card.reversed {
                                            Text(t("result.reversed"))
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(theme.colors.accentPink.opacity(0.8))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(theme.colors.surface)
                            .cornerRadius(10)
                        }
                    }

                    // Interpretation
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                            Text(t("result.aiDeepReading"))
                                .font(.system(size: 15, weight: .semibold, design: .serif))
                        }
                        .foregroundColor(theme.colors.foreground)

                        Rectangle()
                            .fill(theme.colors.border.opacity(0.3))
                            .frame(height: 0.5)

                        MarkdownText(entry.interpretation, theme: theme)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(theme.colors.surface)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.colors.border.opacity(0.3), lineWidth: 0.5)
                    )
                }
                .padding(20)
            }
            .background(theme.colors.background)
            .navigationTitle(t("journal.detail"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("hero.cancel")) { dismiss() }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: i18n.locale)
        return formatter.string(from: date)
    }
}
