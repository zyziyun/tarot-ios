import SwiftUI

struct SpreadSelectorView: View {
    @Environment(AppState.self) private var state
    @Environment(LocalizationManager.self) private var i18n
    @Environment(ThemeManager.self) private var theme

    let spreads: [Spread]

    @State private var contentOpacity = 0.0

    private func t(_ key: String, _ params: [String: String] = [:]) -> String {
        i18n.t(key, params: params)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) { state.phase = .question }
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

                VStack(spacing: 10) {
                    Text(t("spreadSelector.title"))
                        .font(.system(size: 26, weight: .light, design: .serif))
                        .foregroundColor(theme.colors.foreground)

                    Text(t("spreadSelector.subtitleDefault"))
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.muted)
                }
                .padding(.top, 28)

                // AI recommendation loading
                if state.isRecommending {
                    aiLoadingCard
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                }

                // AI recommendation result
                if let rec = state.aiRecommendation, !state.isRecommending {
                    if rec.isCustom, let custom = rec.customSpread {
                        customSpreadCard(custom, reason: rec.reason)
                            .padding(.top, 16)
                            .padding(.horizontal, 20)
                    } else if let key = rec.existingKey {
                        aiRecommendationCard(spreadKey: key, reason: rec.reason)
                            .padding(.top, 16)
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // Spread grid
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(spreads) { spread in
                        spreadCard(spread)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 24)
                .opacity(contentOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                contentOpacity = 1.0
            }
        }
    }

    @ViewBuilder
    private func spreadCard(_ spread: Spread) -> some View {
        let isRecommended = state.aiRecommendation?.existingKey == spread.id

        Button {
            selectSpread(spread)
        } label: {
            VStack(spacing: 10) {
                // Spread shape preview with icon overlay
                ZStack {
                    SpreadLayoutView(
                        spreadKey: spread.id,
                        count: spread.positionCount,
                        accentColor: isRecommended ? theme.colors.accent : theme.colors.gold,
                        cardColor: isRecommended ? theme.colors.accent.opacity(0.35) : theme.colors.gold.opacity(0.2),
                        size: 72
                    )

                    // Icon in center
                    Text(spread.icon)
                        .font(.system(size: 20))
                        .opacity(0.45)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 76)
                .overlay(alignment: .topTrailing) {
                    if isRecommended {
                        Text(t("spreadSelector.aiRecommendBadge"))
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(theme.colors.accent)
                            .cornerRadius(4)
                            .offset(x: 2, y: -2)
                    }
                }

                VStack(spacing: 4) {
                    Text(t("spreads.\(spread.id).name"))
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundColor(theme.colors.foreground)
                        .lineLimit(1)

                    Text(t("spreadSelector.cardCount", ["count": "\(spread.positionCount)"]))
                        .font(.system(size: 10))
                        .foregroundColor(theme.colors.muted.opacity(0.6))

                    // Usage description
                    let whenToUse = t("spreads.\(spread.id).whenToUse")
                    if whenToUse != "spreads.\(spread.id).whenToUse" {
                        Text(whenToUse)
                            .font(.system(size: 9))
                            .foregroundColor(theme.colors.muted.opacity(0.5))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 16)
            .background(
                isRecommended
                    ? theme.colors.accent.opacity(0.04)
                    : theme.colors.surface
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isRecommended ? theme.colors.accent.opacity(0.25) : theme.colors.border.opacity(0.5),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: theme.colors.foreground.opacity(0.03), radius: 10, y: 3)
        }
    }

    // MARK: - AI Loading Card

    private var aiLoadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(theme.colors.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(t("spreadSelector.aiAnalyzing"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.colors.accent)
                Text(t("spreadSelector.aiAnalyzingHint"))
                    .font(.system(size: 11))
                    .foregroundColor(theme.colors.muted)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.colors.accent.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.colors.accent.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    // MARK: - AI Recommendation Card (existing spread)

    @ViewBuilder
    private func aiRecommendationCard(spreadKey: String, reason: String) -> some View {
        let trimmedKey = spreadKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let spread = spreads.first(where: { $0.id == trimmedKey })
            ?? spreads.first(where: { $0.id.lowercased() == trimmedKey.lowercased() })

        Button {
            if let spread {
                selectSpread(spread)
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.accent)
                    Text(t("spreadSelector.aiRecommendBadge"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.colors.accent)
                    Spacer()
                    if let spread {
                        Text(t("spreadSelector.cardCount", ["count": "\(spread.positionCount)"]))
                            .font(.system(size: 10))
                            .foregroundColor(theme.colors.muted)
                    }
                }

                Text(t("spreads.\(trimmedKey).name"))
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(theme.colors.foreground)

                // Reason from AI
                if !reason.isEmpty {
                    Text(reason)
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.muted)
                        .lineSpacing(3)
                }

                // Spread description
                let desc = t("spreads.\(trimmedKey).description")
                if desc != "spreads.\(trimmedKey).description" {
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.muted.opacity(0.7))
                        .lineSpacing(2)
                }

                // Position labels
                if let spread {
                    let positions = SpreadLoader.resolvePositions(
                        spreadKey: spread.id,
                        count: spread.positionCount,
                        using: { i18n.t($0) }
                    )
                    FlowLayout(spacing: 6) {
                        ForEach(Array(positions.enumerated()), id: \.offset) { _, pos in
                            Text(pos.label)
                                .font(.system(size: 10))
                                .foregroundColor(theme.colors.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(theme.colors.accent.opacity(0.08))
                                .cornerRadius(8)
                        }
                    }
                }

                // Tap to use button
                HStack {
                    Spacer()
                    Text(t("spreadSelector.useThis"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(theme.colors.accent)
                        .cornerRadius(18)
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(theme.colors.accent.opacity(0.04))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.colors.accent.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: theme.colors.accent.opacity(0.08), radius: 8, y: 2)
        }
    }

    @ViewBuilder
    private func customSpreadCard(_ custom: AISpreadRecommendation.CustomSpread, reason: String) -> some View {
        Button {
            selectCustomSpread(custom)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("✨ \(t("spreadSelector.aiCustomRecommend"))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.colors.accent)
                    Spacer()
                    Text(t("spreadSelector.cardCount", ["count": "\(custom.positions.count)"]))
                        .font(.system(size: 10))
                        .foregroundColor(theme.colors.muted)
                }

                Text(custom.name)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(theme.colors.foreground)

                FlowLayout(spacing: 6) {
                    ForEach(Array(custom.positions.enumerated()), id: \.offset) { _, pos in
                        Text(pos.label)
                            .font(.system(size: 10))
                            .foregroundColor(theme.colors.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(theme.colors.accent.opacity(0.08))
                            .cornerRadius(8)
                    }
                }

                Text(reason)
                    .font(.system(size: 11))
                    .foregroundColor(theme.colors.muted)
            }
            .padding(16)
            .background(theme.colors.accent.opacity(0.03))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.colors.accent.opacity(0.2), lineWidth: 0.5)
            )
        }
    }

    private func selectSpread(_ spread: Spread) {
        Haptic.selection()
        TarotAnalytics.logSpreadSelected(spread.id)
        state.activeSpread = spread
        state.activeSpreadKey = spread.id
        state.resolvedPositions = SpreadLoader.resolvePositions(
            spreadKey: spread.id,
            count: spread.positionCount,
            using: { i18n.t($0) }
        )
        withAnimation(.easeInOut(duration: 0.4)) {
            state.phase = .draw
        }
    }

    private func selectCustomSpread(_ custom: AISpreadRecommendation.CustomSpread) {
        Haptic.selection()
        let spread = Spread(id: "custom", icon: "✨", positionCount: custom.positions.count)
        state.activeSpread = spread
        state.activeSpreadKey = nil
        state.resolvedPositions = custom.positions
        withAnimation(.easeInOut(duration: 0.4)) {
            state.phase = .draw
        }
    }
}

// MARK: - Flow Layout for position chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
