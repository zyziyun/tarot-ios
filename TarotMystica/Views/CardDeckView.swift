import SwiftUI

struct CardDeckView: View {
    @Environment(AppState.self) private var state
    @Environment(LocalizationManager.self) private var i18n
    @Environment(ThemeManager.self) private var theme

    let allCards: [TarotCard]
    let reversalChance: Double

    @State private var shuffledDeck: [TarotCard] = []
    @State private var drawnCards: [DrawnCard] = []
    @State private var isShuffling = false
    @State private var shuffled = false
    @State private var isDrawing = false

    // Shuffle animation state (10 cards like web)
    @State private var shufflePhase = 0
    @State private var shuffleCardX: [CGFloat] = Array(repeating: 0, count: 10)
    @State private var shuffleCardY: [CGFloat] = Array(repeating: 0, count: 10)
    @State private var shuffleCardAngle: [Double] = Array(repeating: 0, count: 10)
    @State private var shuffleCardScale: [CGFloat] = Array(repeating: 1, count: 10)

    // Card reveal overlay
    @State private var revealCard: DrawnCard?
    @State private var revealVisible = false
    @State private var revealFlipped = false

    // Pulse animation for card stack
    @State private var pulseScale: CGFloat = 1.0

    // Card enlarge overlay (for allDrawnSummary)
    @State private var enlargedCard: DrawnCard?

    // Bottom drawer
    @State private var drawerExpanded = false

    private var totalNeeded: Int {
        state.activeSpread?.positionCount ?? 1
    }

    private var allDrawn: Bool {
        drawnCards.count >= totalNeeded
    }

    private func t(_ key: String, _ params: [String: String] = [:]) -> String {
        i18n.t(key, params: params)
    }

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                header

                if !shuffled {
                    Spacer()
                    shuffleSection
                    Spacer()
                } else if !allDrawn {
                    // Immersive draw mode
                    Spacer()
                    drawFocusSection
                    Spacer()
                } else {
                    // All drawn — show summary
                    allDrawnSummary
                }
            }

            // Bottom drawer for drawn cards (visible during drawing)
            if !drawnCards.isEmpty && !allDrawn {
                drawnCardsDrawer
            }

            // Fullscreen card reveal overlay
            if revealVisible, let card = revealCard {
                cardRevealOverlay(card)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .onAppear {
            shuffledDeck = allCards.shuffled()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) { state.phase = .choose }
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
            Text(spreadName)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundColor(theme.colors.foreground)
            Spacer()
            // Progress indicator (show current draw number, not completed count)
            Text("\(min(drawnCards.count + (revealVisible ? 1 : 0), totalNeeded))/\(totalNeeded)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.colors.muted)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Shuffle (web-style multi-phase animation)

    private var shuffleSection: some View {
        VStack(spacing: 24) {
            ZStack {
                ForEach(0..<10, id: \.self) { i in
                    cardBackView()
                        .frame(width: 120, height: 185)
                        .scaleEffect(shuffleCardScale[i])
                        .rotationEffect(.degrees(shuffleCardAngle[i]))
                        .offset(x: shuffleCardX[i], y: shuffleCardY[i])
                        .zIndex(Double(i))
                }
            }
            .frame(height: 300)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isShuffling = true
                runShuffleAnimation()
            }
        }
    }

    private func runShuffleAnimation() {
        // Phase 1: Spread out in a fan
        Haptic.shuffleTick()
        withAnimation(.easeOut(duration: 0.5)) {
            for i in 0..<10 {
                shuffleCardX[i] = CGFloat(i - 4) * 28
                shuffleCardY[i] = -abs(CGFloat(i) - 4.5) * 8
                shuffleCardAngle[i] = Double(i - 4) * 6
                shuffleCardScale[i] = 0.92
            }
        }

        // Phase 2: Split left/right
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Haptic.shuffleTick()
            withAnimation(.easeInOut(duration: 0.6)) {
                for i in 0..<10 {
                    let isLeft = i < 5
                    shuffleCardX[i] = isLeft ? -80 : 80
                    shuffleCardY[i] = CGFloat(i % 5) * 6 - 12
                    shuffleCardAngle[i] = isLeft ? -5 : 5
                    shuffleCardScale[i] = 0.95
                }
            }
        }

        // Phase 3: Riffle together
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            Haptic.shuffleTick()
            withAnimation(.easeInOut(duration: 0.5)) {
                for i in 0..<10 {
                    let isLeft = i < 5
                    let localIdx = isLeft ? i : i - 5
                    let interleaved = isLeft ? localIdx * 2 : localIdx * 2 + 1
                    shuffleCardX[i] = CGFloat(interleaved - 4) * 4
                    shuffleCardY[i] = CGFloat(interleaved) * 3 - 14
                    shuffleCardAngle[i] = 0
                    shuffleCardScale[i] = 0.97
                }
            }
        }

        // Phase 4: Stack together
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            Haptic.shuffleComplete()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                for i in 0..<10 {
                    shuffleCardX[i] = 0
                    shuffleCardY[i] = 0
                    shuffleCardAngle[i] = 0
                    shuffleCardScale[i] = 1.0
                }
            }
        }

        // Complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                shuffled = true
                isShuffling = false
            }
        }
    }

    // MARK: - Immersive Draw Focus

    private var drawFocusSection: some View {
        VStack(spacing: 28) {
            // Current position info
            VStack(spacing: 8) {
                // Spread mini-map showing which position we're drawing
                if let key = state.activeSpreadKey {
                    SpreadLayoutView(
                        spreadKey: key,
                        count: totalNeeded,
                        accentColor: theme.colors.accent,
                        cardColor: theme.colors.muted.opacity(0.12),
                        highlightIndex: drawnCards.count,
                        size: 80
                    )
                    .padding(.bottom, 8)
                }

                Text(t("deck.drawInstruction", ["n": "\(drawnCards.count + 1)"]))
                    .font(.system(size: 13))
                    .foregroundColor(theme.colors.muted)

                Text(currentPositionLabel)
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundColor(theme.colors.foreground)
            }

            // Tap to draw — large card stack
            Button {
                drawCard()
            } label: {
                ZStack {
                    ForEach(0..<min(4, totalNeeded - drawnCards.count), id: \.self) { offset in
                        cardBackView()
                            .frame(width: 160, height: 248)
                            .offset(x: CGFloat(offset) * 2, y: CGFloat(-offset) * 3)
                            .opacity(1.0 - Double(offset) * 0.08)
                    }
                }
                .shadow(color: theme.colors.gold.opacity(0.12), radius: 28, y: 12)
            }
            .disabled(isDrawing)
            .scaleEffect(isDrawing ? 0.96 : pulseScale)
            .animation(.spring(response: 0.3), value: isDrawing)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    pulseScale = 1.03
                }
            }

            Text(t("deck.tapToDraw"))
                .font(.system(size: 12))
                .foregroundColor(theme.colors.muted.opacity(0.5))
        }
    }

    // MARK: - Bottom Drawer (drawn cards thumbnails)

    private var drawnCardsDrawer: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                // Drag handle
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        drawerExpanded.toggle()
                    }
                } label: {
                    VStack(spacing: 6) {
                        Capsule()
                            .fill(theme.colors.muted.opacity(0.3))
                            .frame(width: 36, height: 4)

                        Text(t("deck.cardsDrawn", ["count": "\(drawnCards.count)"]))
                            .font(.system(size: 11))
                            .foregroundColor(theme.colors.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                    .contentShape(Rectangle())
                }

                if drawerExpanded {
                    // Expanded: show card list
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(Array(drawnCards.enumerated()), id: \.element.id) { idx, drawn in
                                HStack(spacing: 12) {
                                    cardImage(drawn.card.image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 44, height: 68)
                                        .rotationEffect(drawn.reversed ? .degrees(180) : .zero)
                                        .cornerRadius(4)

                                    VStack(alignment: .leading, spacing: 3) {
                                        if idx < state.resolvedPositions.count {
                                            Text(state.resolvedPositions[idx].label)
                                                .font(.system(size: 10))
                                                .foregroundColor(theme.colors.muted)
                                        }
                                        HStack(spacing: 5) {
                                            Text(cardName(drawn.card))
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(theme.colors.foreground)
                                            if drawn.reversed {
                                                Text(t("deck.reversed"))
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 1)
                                                    .background(theme.colors.accentPink.opacity(0.8))
                                                    .cornerRadius(3)
                                            }
                                        }
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    .frame(maxHeight: 240)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    // Collapsed: horizontal thumbnail strip
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(drawnCards) { drawn in
                                cardImage(drawn.card.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 36, height: 56)
                                    .rotationEffect(drawn.reversed ? .degrees(180) : .zero)
                                    .cornerRadius(4)
                                    .shadow(color: theme.colors.gold.opacity(0.1), radius: 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                }
            }
            .background(
                theme.colors.surface
                    .shadow(.drop(color: theme.colors.foreground.opacity(0.06), radius: 12, y: -4))
            )
            .cornerRadius(20, corners: [.topLeft, .topRight])
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: - All Drawn Summary

    private var allDrawnSummary: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Spread layout overview
                if let key = state.activeSpreadKey {
                    SpreadLayoutView(
                        spreadKey: key,
                        count: totalNeeded,
                        accentColor: theme.colors.accent,
                        cardColor: theme.colors.accent.opacity(0.25),
                        size: 100
                    )
                    .padding(.top, 24)
                }

                VStack(spacing: 6) {
                    Text(t("deck.allDrawn"))
                        .font(.system(size: 16, weight: .light, design: .serif))
                        .foregroundColor(theme.colors.foreground)

                    Text(t("deck.allDrawnHint"))
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.muted.opacity(0.6))
                }

                // Card list (tap to enlarge)
                VStack(spacing: 12) {
                    ForEach(Array(drawnCards.enumerated()), id: \.element.id) { idx, drawn in
                        Button {
                            enlargedCard = drawn
                        } label: {
                            HStack(spacing: 14) {
                                cardImage(drawn.card.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 64, height: 100)
                                    .rotationEffect(drawn.reversed ? .degrees(180) : .zero)
                                    .cornerRadius(6)
                                    .shadow(color: theme.colors.gold.opacity(0.12), radius: 8, y: 3)

                                VStack(alignment: .leading, spacing: 5) {
                                    if idx < state.resolvedPositions.count {
                                        Text(state.resolvedPositions[idx].label)
                                            .font(.system(size: 11))
                                            .foregroundColor(theme.colors.muted)
                                    }
                                    HStack(spacing: 6) {
                                        Text(cardName(drawn.card))
                                            .font(.system(size: 15, weight: .medium, design: .serif))
                                            .foregroundColor(theme.colors.foreground)
                                        if drawn.reversed {
                                            Text(t("deck.reversed"))
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(theme.colors.accentPink.opacity(0.8))
                                                .cornerRadius(4)
                                        }
                                    }
                                    Text(drawn.reversed ? cardText(drawn.card, "reversed") : cardText(drawn.card, "upright"))
                                        .font(.system(size: 11))
                                        .foregroundColor(theme.colors.muted)
                                        .lineLimit(2)
                                }
                                Spacer()

                                Image(systemName: "magnifyingglass.circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(theme.colors.muted.opacity(0.4))
                            }
                            .padding(.horizontal, 20)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Primary AI Reading button
                Button {
                    Haptic.primaryAction()
                    state.drawnCards = drawnCards
                    withAnimation(.easeInOut(duration: 0.4)) {
                        state.phase = .result
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .medium))
                        Text(t("deck.viewAIReading"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [theme.colors.accent, theme.colors.accent.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                    .shadow(color: theme.colors.accent.opacity(0.3), radius: 16, y: 6)
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .overlay {
            // Card enlarge overlay
            if let card = enlargedCard {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture { enlargedCard = nil }

                    VStack(spacing: 16) {
                        cardImage(card.card.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .rotationEffect(card.reversed ? .degrees(180) : .zero)
                            .frame(maxWidth: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: theme.colors.gold.opacity(0.3), radius: 20, y: 8)

                        Text(cardName(card.card))
                            .font(.system(size: 20, weight: .regular, design: .serif))
                            .foregroundColor(.white)

                        if card.reversed {
                            Text(t("deck.reversed"))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.colors.accentPink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(theme.colors.accentPink.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
                .transition(.opacity)
                .zIndex(50)
            }
        }
    }

    // MARK: - Card Reveal Overlay

    @ViewBuilder
    private func cardRevealOverlay(_ drawn: DrawnCard) -> some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { dismissRevealAndAddCard() }

            VStack(spacing: 16) {
                // Position label — prominent
                if drawn.id < state.resolvedPositions.count {
                    Text(state.resolvedPositions[drawn.id].label)
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.15))
                        .cornerRadius(12)
                }

                // Card — no background, just image + mask
                ZStack {
                    if revealFlipped {
                        cardImage(drawn.card.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .rotationEffect(drawn.reversed ? .degrees(180) : .zero)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: theme.colors.gold.opacity(0.35), radius: 24, y: 10)
                    } else {
                        cardBackView()
                            .frame(width: 220, height: 346)
                    }
                }
                .frame(maxWidth: 260)
                .rotation3DEffect(
                    .degrees(revealFlipped ? 0 : 180),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )

                // Card info
                if revealFlipped {
                    VStack(spacing: 8) {
                        Text(cardName(drawn.card))
                            .font(.system(size: 22, weight: .regular, design: .serif))
                            .foregroundColor(.white)

                        if drawn.reversed {
                            Text(t("deck.reversed"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(theme.colors.accentPink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(theme.colors.accentPink.opacity(0.2))
                                .cornerRadius(8)
                        }

                        // Card meaning
                        Text(drawn.reversed ? cardText(drawn.card, "reversed") : cardText(drawn.card, "upright"))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, 40)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                    Text(t("common.tapToContinue"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.1))
                        .cornerRadius(16)
                        .padding(.top, 8)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                Haptic.cardFlip()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                    revealFlipped = true
                }
            }
        }
    }

    private func dismissReveal() {
        withAnimation(.easeOut(duration: 0.25)) {
            revealVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            revealCard = nil
            revealFlipped = false
        }
    }

    // MARK: - Card Back

    @ViewBuilder
    private func cardBackView() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: theme.cardBack.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.colors.gold.opacity(0.3), lineWidth: 1)
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.colors.gold.opacity(0.2), lineWidth: 0.5)
                .padding(6)
            Text(theme.cardBack.symbolCharacter)
                .font(.system(size: 24))
                .foregroundColor(theme.cardBack.symbolColor)
        }
    }

    // MARK: - Helpers

    private func cardImage(_ filename: String) -> Image {
        let name = filename.replacingOccurrences(of: ".webp", with: "")
        if let path = Bundle.main.path(forResource: name, ofType: "webp"),
           let uiImage = UIImage(contentsOfFile: path) {
            return Image(uiImage: uiImage)
        }
        if let path = Bundle.main.path(forResource: filename, ofType: nil),
           let uiImage = UIImage(contentsOfFile: path) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "rectangle.portrait")
    }

    private var spreadName: String {
        guard let key = state.activeSpreadKey else { return "" }
        return t("spreads.\(key).name")
    }

    private var currentPositionLabel: String {
        let idx = drawnCards.count
        guard idx < state.resolvedPositions.count else { return "" }
        return state.resolvedPositions[idx].label
    }

    private func cardName(_ card: TarotCard) -> String {
        t("cards.\(card.id).name")
    }

    private func cardText(_ card: TarotCard, _ field: String) -> String {
        t("cards.\(card.id).\(field)")
    }

    private func drawCard() {
        guard !isDrawing, drawnCards.count < totalNeeded else { return }
        isDrawing = true
        Haptic.cardDraw()

        let idx = drawnCards.count
        guard idx < shuffledDeck.count else { isDrawing = false; return }
        let card = shuffledDeck[idx]
        let reversed = Double.random(in: 0...1) < reversalChance
        let drawn = DrawnCard(id: idx, card: card, reversed: reversed)

        // Show fullscreen reveal
        revealCard = drawn
        revealFlipped = false
        withAnimation(.easeOut(duration: 0.3)) {
            revealVisible = true
        }

        // Auto-dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if revealCard?.id == drawn.id && revealVisible {
                dismissReveal()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    drawnCards.append(drawn)
                }
                if drawnCards.count >= totalNeeded {
                    Haptic.allCardsDrawn()
                }
                isDrawing = false
            }
        }
    }

    private func dismissRevealAndAddCard() {
        guard let card = revealCard else { return }
        dismissReveal()
        if !drawnCards.contains(where: { $0.id == card.id }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    drawnCards.append(card)
                }
                if drawnCards.count >= totalNeeded {
                    Haptic.allCardsDrawn()
                }
                isDrawing = false
            }
        }
    }
}

// MARK: - Corner Radius Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
