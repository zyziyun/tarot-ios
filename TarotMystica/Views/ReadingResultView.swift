import SwiftUI
import SwiftData
import Photos
import AVKit

struct ReadingResultView: View {
    @Environment(AppState.self) private var state
    @Environment(LLMService.self) private var llm
    @Environment(LocalizationManager.self) private var i18n
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext

    @State private var expandedIdx: Int?
    @State private var aiInterpretation = ""
    @State private var aiRequested = false
    @State private var showShareSheet = false
    @State private var posterImage: UIImage?
    @State private var showPosterPreview = false
    @State private var activeTab: ResultTab = .aiReading
    @State private var showResetConfirm = false
    @State private var enlargedCardInResult: DrawnCard?

    @State private var showFollowUpChat = false
    @State private var savedToJournal = false
    @State private var showVideoGenerator = false

    @State private var videoGenState: VideoGenState = .idle
    @State private var videoProgress: Float = 0
    @State private var videoURL: URL?
    @State private var videoPlayer: AVPlayer?
    @State private var videoSavedToPhotos = false
    @State private var showVideoShareSheet = false

    private enum VideoGenState {
        case idle, generating, done, error(String)
    }

    private enum ResultTab {
        case cards, aiReading
    }

    private func t(_ key: String, _ params: [String: String] = [:]) -> String {
        i18n.t(key, params: params)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        headerSection

                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            Section {
                                if activeTab == .aiReading {
                                    aiReadingContent
                                } else {
                                    cardsContent
                                }

                                Color.clear.frame(height: 1).id("bottom")
                                Spacer().frame(height: 24)
                            } header: {
                                segmentedControl
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        theme.colors.background
                                            .ignoresSafeArea(edges: .top)
                                    }
                                    .shadow(color: theme.colors.foreground.opacity(0.04), radius: 2, y: 2)
                            }
                        }
                    }
                }
                .onChange(of: aiInterpretation) { _, _ in
                    if llm.isGenerating {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }

            bottomBar
        }
        .overlay {
            if showPosterPreview, let img = posterImage {
                posterPreviewOverlay(img)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .overlay {
            if showVideoGenerator {
                videoGeneratorOverlay
                    .transition(.opacity)
                    .zIndex(101)
            }
        }
        .sheet(isPresented: $showFollowUpChat) {
            FollowUpChatView(
                question: state.question,
                spreadName: spreadName,
                aiInterpretation: aiInterpretation,
                originalMessages: buildOriginalMessages(),
                cardDescriptions: buildCardDescriptions()
            )
            .environment(llm)
            .environment(i18n)
            .environment(theme)
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = posterImage {
                ShareSheet(items: [img])
            }
        }
        .alert(t("result.resetConfirmTitle"), isPresented: $showResetConfirm) {
            Button(t("hero.cancel"), role: .cancel) { }
            Button(t("result.resetConfirm"), role: .destructive) {
                state.reset()
            }
        } message: {
            Text(t("result.resetConfirmMessage"))
        }
        .task {
            await requestAI()
        }
        .onDisappear {}
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            if let key = state.activeSpreadKey, state.drawnCards.count > 1 {
                SpreadLayoutView(
                    spreadKey: key,
                    count: state.activeSpread?.positionCount ?? state.drawnCards.count,
                    accentColor: theme.colors.accent,
                    cardColor: theme.colors.accent.opacity(0.2),
                    size: 56
                )
            }

            if !spreadName.isEmpty {
                Text(spreadName)
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .foregroundColor(theme.colors.foreground)
            }

            if !state.question.isEmpty {
                Text("「\(state.question)」")
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.muted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 32)
            }

            cardStrip
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Segmented Control

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            tabButton(title: t("result.aiReadingTab"), icon: "sparkles", tab: .aiReading)
            tabButton(title: t("result.cardsTab", ["count": "\(state.drawnCards.count)"]), icon: "rectangle.portrait.on.rectangle.portrait", tab: .cards)
        }
        .background(theme.colors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.colors.border.opacity(0.5), lineWidth: 0.5)
        )
        .padding(.horizontal, 20)
    }

    private func tabButton(title: String, icon: String, tab: ResultTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                activeTab = tab
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(activeTab == tab ? .white : theme.colors.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(activeTab == tab ? theme.colors.accent : Color.clear)
            .cornerRadius(10)
            .padding(2)
        }
    }

    // MARK: - Fixed Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 10) {
            Button {
                Haptic.warning()
                showResetConfirm = true
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15))
                    .foregroundColor(theme.colors.muted)
                    .frame(width: 44, height: 44)
                    .background(theme.colors.surface)
                    .cornerRadius(22)
                    .overlay(
                        Circle()
                            .stroke(theme.colors.border.opacity(0.5), lineWidth: 0.5)
                    )
            }

            Button {
                saveToJournal()
            } label: {
                Image(systemName: savedToJournal ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 15))
                    .foregroundColor(savedToJournal ? theme.colors.accent : theme.colors.muted)
                    .frame(width: 44, height: 44)
                    .background(savedToJournal ? theme.colors.accent.opacity(0.08) : theme.colors.surface)
                    .cornerRadius(22)
                    .overlay(
                        Circle()
                            .stroke(
                                savedToJournal ? theme.colors.accent.opacity(0.3) : theme.colors.border.opacity(0.5),
                                lineWidth: 0.5
                            )
                    )
            }
            .disabled(savedToJournal || aiInterpretation.isEmpty)

            if !aiInterpretation.isEmpty {
                Button {
                    showVideoGenerator = true
                } label: {
                    Image(systemName: "video.badge.plus")
                        .font(.system(size: 15))
                        .foregroundColor(theme.colors.muted)
                        .frame(width: 44, height: 44)
                        .background(theme.colors.surface)
                        .cornerRadius(22)
                        .overlay(
                            Circle()
                                .stroke(theme.colors.border.opacity(0.5), lineWidth: 0.5)
                        )
                }
            }

            Button {
                generateAndShare()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .medium))
                    Text(t("common.share"))
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(theme.colors.accent)
                .cornerRadius(22)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            theme.colors.background
                .shadow(.drop(color: theme.colors.foreground.opacity(0.05), radius: 8, y: -2))
        )
    }

    // MARK: - AI Reading Tab

    private var aiReadingContent: some View {
        VStack(spacing: 0) {
            aiContentSection
                .padding(.horizontal, 20)
                .padding(.top, 16)

            if !aiInterpretation.isEmpty && !llm.isGenerating {
                Button {
                    Haptic.primaryAction()
                    TarotAnalytics.logFollowUpChat()
                    showFollowUpChat = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 14))
                        Text(t("chat.followUp"))
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(theme.colors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(theme.colors.accent.opacity(0.06))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(theme.colors.accent.opacity(0.2), lineWidth: 0.5)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            Spacer().frame(height: 24)
        }
    }

    private var cardStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(state.drawnCards.enumerated()), id: \.element.id) { idx, drawn in
                    VStack(spacing: 5) {
                        cardImage(drawn.card.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 52, height: 80)
                            .rotationEffect(drawn.reversed ? .degrees(180) : .zero)
                            .cornerRadius(4)
                            .shadow(color: theme.colors.gold.opacity(0.1), radius: 3)

                        Text(idx < state.resolvedPositions.count ? state.resolvedPositions[idx].label : "")
                            .font(.system(size: 9))
                            .foregroundColor(theme.colors.muted)
                            .lineLimit(1)
                            .frame(width: 56)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var aiContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(llm.isReady ? Color.green : theme.colors.muted.opacity(0.5))
                    .frame(width: 6, height: 6)

                Text(t("result.aiDeepReading"))
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundColor(theme.colors.foreground)

                if llm.isGenerating {
                    Text(t("result.thinking"))
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.accent)
                }

                Spacer()
            }

            Rectangle()
                .fill(theme.colors.border.opacity(0.3))
                .frame(height: 0.5)

            if !aiInterpretation.isEmpty {
                MarkdownText(aiInterpretation, theme: theme)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let error = llm.error {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.8))
                    Button(t("result.retry")) {
                        aiRequested = false
                        Task { await requestAI() }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.colors.accent)
                }
            } else if !llm.config.configured {
                Text(t("result.aiNotConfigured"))
                    .font(.system(size: 13))
                    .foregroundColor(theme.colors.muted)
                    .padding(.vertical, 20)
            } else if llm.isGenerating {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(t("result.generating"))
                        .font(.system(size: 13))
                        .foregroundColor(theme.colors.muted)
                }
                .padding(.vertical, 20)
            } else {
                Text(t("result.aiLoadingHint"))
                    .font(.system(size: 13))
                    .foregroundColor(theme.colors.muted)
                    .padding(.vertical, 20)
            }
        }
        .padding(16)
        .background(theme.colors.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.colors.border.opacity(0.5), lineWidth: 0.5)
        )
    }

    // MARK: - Helper builders for chat view

    private func buildCardDescriptions() -> [PromptBuilder.CardDescription] {
        state.drawnCards.enumerated().map { idx, drawn in
            PromptBuilder.CardDescription(
                name: cardName(drawn.card),
                position: idx < state.resolvedPositions.count ? state.resolvedPositions[idx].label : "",
                reversed: drawn.reversed,
                uprightMeaning: cardText(drawn.card, "upright"),
                reversedMeaning: cardText(drawn.card, "reversed"),
                description: cardText(drawn.card, "description"),
                loveMeaning: cardText(drawn.card, "love"),
                careerMeaning: cardText(drawn.card, "career"),
                keywords: cardText(drawn.card, "keywords")
            )
        }
    }

    private func buildOriginalMessages() -> [APIExecutor.Message] {
        PromptBuilder.interpretationMessages(
            question: state.question,
            spreadName: spreadName,
            cards: buildCardDescriptions(),
            style: llm.config.interpretationStyle,
            locale: i18n.locale,
            t: { key, params in i18n.t(key, params: params) }
        )
    }

    // MARK: - Cards Tab

    private var cardsContent: some View {
        VStack(spacing: 12) {
            ForEach(Array(state.drawnCards.enumerated()), id: \.element.id) { idx, drawn in
                cardRow(idx: idx, drawn: drawn)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Card Row

    @ViewBuilder
    private func cardRow(idx: Int, drawn: DrawnCard) -> some View {
        let isExpanded = expandedIdx == idx

        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedIdx = isExpanded ? nil : idx
                }
            } label: {
                HStack(spacing: 12) {
                    cardImage(drawn.card.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 68)
                        .rotationEffect(drawn.reversed ? .degrees(180) : .zero)
                        .cornerRadius(4)
                        .shadow(color: theme.colors.gold.opacity(0.1), radius: 4)

                    VStack(alignment: .leading, spacing: 4) {
                        if idx < state.resolvedPositions.count {
                            Text(state.resolvedPositions[idx].label)
                                .font(.system(size: 11))
                                .foregroundColor(theme.colors.muted)
                        }

                        HStack(spacing: 6) {
                            Text(cardName(drawn.card))
                                .font(.system(size: 14, weight: .medium, design: .serif))
                                .foregroundColor(theme.colors.foreground)

                            Text(drawn.reversed ? t("result.reversed") : t("result.upright"))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(drawn.reversed ? theme.colors.accentPink.opacity(0.8) : theme.colors.accent.opacity(0.6))
                                .cornerRadius(4)
                        }

                        Text(drawn.reversed ? cardText(drawn.card, "reversed") : cardText(drawn.card, "upright"))
                            .font(.system(size: 11))
                            .foregroundColor(theme.colors.muted)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.muted)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                expandedDetails(drawn: drawn, idx: idx)
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(theme.colors.surface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.colors.border.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: theme.colors.foreground.opacity(0.02), radius: 6, y: 2)
    }

    @ViewBuilder
    private func expandedDetails(drawn: DrawnCard, idx: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if idx < state.resolvedPositions.count {
                VStack(alignment: .leading, spacing: 4) {
                    Text(t("result.positionMeaning"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.colors.accent)
                    Text(state.resolvedPositions[idx].description)
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.muted)
                }
            }

            Divider()

            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.system(size: 10))
                    .foregroundColor(theme.colors.gold)
                Text(t("result.interpretation"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(theme.colors.gold)
            }

            Text(cardText(drawn.card, "description"))
                .font(.system(size: 12))
                .foregroundColor(theme.colors.foreground.opacity(0.8))
                .lineSpacing(4)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(t("result.upright"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(theme.colors.accent)
                    Text(cardText(drawn.card, "upright"))
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(t("result.reversed"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(theme.colors.accentPink)
                    Text(cardText(drawn.card, "reversed"))
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(t("result.love"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(theme.colors.accentPink)
                    Text(cardText(drawn.card, "love"))
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(t("result.career"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(theme.colors.gold)
                    Text(cardText(drawn.card, "career"))
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            let keywords = cardKeywords(drawn.card)
            if !keywords.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(keywords, id: \.self) { keyword in
                        Text(keyword)
                            .font(.system(size: 10))
                            .foregroundColor(theme.colors.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(theme.colors.accent.opacity(0.06))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - AI Request

    private func saveToJournal() {
        guard !aiInterpretation.isEmpty, !savedToJournal else { return }

        let savedCards = state.drawnCards.enumerated().map { idx, drawn in
            SavedCard(
                cardId: drawn.card.id,
                position: idx < state.resolvedPositions.count ? state.resolvedPositions[idx].label : "",
                reversed: drawn.reversed
            )
        }

        let entry = ReadingEntry(
            question: state.question,
            spreadKey: state.activeSpreadKey,
            spreadName: spreadName,
            interpretation: aiInterpretation,
            cards: savedCards,
            locale: i18n.locale,
            style: llm.config.interpretationStyle.rawValue
        )

        modelContext.insert(entry)
        savedToJournal = true
        Haptic.aiComplete()
    }

    private func requestAI() async {
        guard !aiRequested, llm.isReady else { return }
        aiRequested = true

        let cards = state.drawnCards.enumerated().map { idx, drawn in
            PromptBuilder.CardDescription(
                name: cardName(drawn.card),
                position: idx < state.resolvedPositions.count ? state.resolvedPositions[idx].label : "",
                reversed: drawn.reversed,
                uprightMeaning: cardText(drawn.card, "upright"),
                reversedMeaning: cardText(drawn.card, "reversed"),
                description: cardText(drawn.card, "description"),
                loveMeaning: cardText(drawn.card, "love"),
                careerMeaning: cardText(drawn.card, "career"),
                keywords: cardText(drawn.card, "keywords")
            )
        }

        let result = await llm.interpretReading(
            question: state.question,
            spreadName: spreadName,
            cards: cards,
            locale: i18n.locale,
            t: { key, params in i18n.t(key, params: params) },
            onToken: { text in
                aiInterpretation = Self.cleanAIOutput(text)
            }
        )
        let provider = llm.config.mode == .local ? "local" : llm.config.apiProvider
        TarotAnalytics.logAIInterpretation(completed: result != nil, provider: provider)
        if result != nil {
            Haptic.aiComplete()
        }
    }

    // MARK: - Clean AI Output

    /// Strip code fences, stray backticks, and other artifacts from local model output
    private static func cleanAIOutput(_ text: String) -> String {
        var s = text
        // Remove code fences (```...``` or ``` alone)
        s = s.replacingOccurrences(of: "```markdown", with: "")
        s = s.replacingOccurrences(of: "```json", with: "")
        s = s.replacingOccurrences(of: "```text", with: "")
        s = s.replacingOccurrences(of: "```", with: "")
        // Remove stray backticks
        s = s.replacingOccurrences(of: "`", with: "")
        return s
    }

    // MARK: - Helpers

    private var spreadName: String {
        guard let key = state.activeSpreadKey else { return "" }
        return t("spreads.\(key).name")
    }

    private func cardName(_ card: TarotCard) -> String {
        t("cards.\(card.id).name")
    }

    private func cardText(_ card: TarotCard, _ field: String) -> String {
        t("cards.\(card.id).\(field)")
    }

    private func cardKeywords(_ card: TarotCard) -> [String] {
        let raw = t("cards.\(card.id).keywords")
        if raw == "cards.\(card.id).keywords" { return [] }
        if raw.hasPrefix("[") {
            guard let data = raw.data(using: .utf8),
                  let arr = try? JSONSerialization.jsonObject(with: data) as? [String] else {
                return []
            }
            return arr
        }
        return raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func cardImage(_ filename: String) -> Image {
        let name = filename.replacingOccurrences(of: ".webp", with: "")
        if let path = Bundle.main.path(forResource: name, ofType: "webp"),
           let uiImage = UIImage(contentsOfFile: path) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "rectangle.portrait")
    }

    /// Strip markdown formatting for TTS
    private func stripMarkdown(_ text: String) -> String {
        var clean = text
        // Remove headings markers
        clean = clean.replacingOccurrences(of: "### ", with: "")
        clean = clean.replacingOccurrences(of: "## ", with: "")
        clean = clean.replacingOccurrences(of: "# ", with: "")
        // Remove bold/italic
        clean = clean.replacingOccurrences(of: "**", with: "")
        clean = clean.replacingOccurrences(of: "*", with: "")
        // Remove dividers
        clean = clean.replacingOccurrences(of: "---", with: "")
        clean = clean.replacingOccurrences(of: "***", with: "")
        // Remove bullet markers
        clean = clean.replacingOccurrences(of: "- ", with: "")
        return clean
    }

    // MARK: - Share

    private func generateAndShare() {
        posterImage = PosterRenderer.render(
            question: state.question,
            spreadName: spreadName,
            spreadKey: state.activeSpreadKey,
            drawnCards: state.drawnCards,
            positions: state.resolvedPositions,
            aiReading: aiInterpretation,
            cardNameFn: { cardName($0) },
            cardTextFn: { cardText($0, $1) }
        )
        withAnimation(.easeOut(duration: 0.25)) {
            showPosterPreview = true
        }
    }

    @ViewBuilder
    private func posterPreviewOverlay(_ img: UIImage) -> some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showPosterPreview = false
                    }
                }

            VStack(spacing: 20) {
                ScrollView {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.3), radius: 24, y: 8)
                }
                .frame(maxHeight: 520)
                .padding(.horizontal, 28)

                HStack(spacing: 16) {
                    Button {
                        saveImageToPhotos(img)
                        withAnimation(.easeOut(duration: 0.2)) {
                            showPosterPreview = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 14))
                            Text(t("common.save"))
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.2))
                        .cornerRadius(24)
                    }

                    Button {
                        showPosterPreview = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showShareSheet = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                            Text(t("common.share"))
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(theme.colors.accent)
                        .cornerRadius(24)
                    }
                }

                Text(t("common.tapToContinue"))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Video Generator Overlay

    private var videoGeneratorOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    // Only allow dismiss when idle or done
                    switch videoGenState {
                    case .idle, .done, .error:
                        withAnimation(.easeOut(duration: 0.25)) {
                            showVideoGenerator = false
                        }
                    default: break
                    }
                }

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showVideoGenerator = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                switch videoGenState {
                case .idle:
                    videoIdleContent
                case .generating:
                    videoGeneratingContent
                case .done:
                    videoDoneContent
                case .error(let msg):
                    videoErrorContent(msg)
                }
            }
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.1, green: 0.07, blue: 0.14))
                    .shadow(color: .black.opacity(0.4), radius: 32, y: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
            )
        }
    }

    private var videoIdleContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack")
                .font(.system(size: 40))
                .foregroundColor(theme.colors.gold.opacity(0.5))
                .padding(.top, 8)

            Text("Generate Video")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(.white)

            Text("Create a 15-second video of\nyour reading to share")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("TikTok  ·  Instagram  ·  WeChat")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.25))

            Button {
                Task { await generateVideo() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13))
                    Text("Generate")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(theme.colors.accent)
                .cornerRadius(24)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private var videoGeneratingContent: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 16)

            ProgressView(value: videoProgress)
                .progressViewStyle(.linear)
                .tint(theme.colors.accent)
                .frame(maxWidth: 200)

            Text("\(Int(videoProgress * 100))%")
                .font(.system(size: 28, weight: .light, design: .monospaced))
                .foregroundColor(.white)

            Text("Rendering your reading...")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.45))

            Spacer().frame(height: 24)
        }
    }

    private var videoDoneContent: some View {
        VStack(spacing: 14) {
            if let player = videoPlayer {
                VideoPlayer(player: player)
                    .frame(width: 180, height: 320)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.4), radius: 16)
                    .onAppear { player.play() }
                    .padding(.top, 4)
            }

            HStack(spacing: 10) {
                Button {
                    saveVideoToPhotos()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: videoSavedToPhotos ? "checkmark" : "square.and.arrow.down")
                            .font(.system(size: 12))
                        Text(videoSavedToPhotos ? "Saved" : "Save")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(20)
                }
                .disabled(videoSavedToPhotos)

                Button {
                    showVideoShareSheet = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 12))
                        Text("Share")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(theme.colors.accent)
                    .cornerRadius(20)
                }
                .sheet(isPresented: $showVideoShareSheet) {
                    if let url = videoURL {
                        ShareSheet(items: [url])
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }

    private func videoErrorContent(_ msg: String) -> some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 16)

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.orange)

            Text(msg)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button("Try Again") {
                Task { await generateVideo() }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(theme.colors.accent)

            Spacer().frame(height: 24)
        }
    }

    @MainActor
    private func generateVideo() async {
        videoGenState = .generating
        videoProgress = 0

        let storyboard = VideoStoryboard.create(
            question: state.question,
            spreadName: spreadName,
            spreadKey: state.activeSpreadKey,
            drawnCards: state.drawnCards,
            positions: state.resolvedPositions,
            aiReading: aiInterpretation,
            cardNameFn: { cardName($0) }
        )

        do {
            let composer = VideoComposer(storyboard: storyboard)
            let url = try await composer.generate { p in
                self.videoProgress = p
            }
            self.videoProgress = 1.0
            self.videoURL = url
            self.videoPlayer = AVPlayer(url: url)
            self.videoPlayer?.actionAtItemEnd = .none
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: self.videoPlayer?.currentItem,
                queue: .main
            ) { _ in
                self.videoPlayer?.seek(to: .zero)
                self.videoPlayer?.play()
            }
            videoGenState = .done
        } catch {
            videoGenState = .error(error.localizedDescription)
        }
    }

    private func saveVideoToPhotos() {
        guard let url = videoURL else { return }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { success, _ in
                DispatchQueue.main.async {
                    if success { videoSavedToPhotos = true }
                }
            }
        }
    }

    // MARK: - Save to Photos

    private func saveImageToPhotos(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                default:
                    #if DEBUG
                    print("[Photos] Permission denied")
                    #endif
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
