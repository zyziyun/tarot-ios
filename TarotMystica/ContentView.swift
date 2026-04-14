import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var state
    @Environment(LLMService.self) private var llm
    @Environment(LocalizationManager.self) private var i18n

    let allCards: [TarotCard]
    let allSpreads: [Spread]
    let reversalChance: Double

    var body: some View {
        ZStack {
            switch state.phase {
            case .hero:
                HeroView()
                    .transition(.opacity)

            case .question:
                QuestionView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

            case .choose:
                SpreadSelectorView(spreads: allSpreads)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

            case .draw:
                CardDeckView(allCards: allCards, reversalChance: reversalChance)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

            case .result:
                ReadingResultView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: state.phase)
        .onChange(of: state.phase) { _, newPhase in
            // Start recommendation early — when leaving question page
            if newPhase == .choose && state.aiRecommendation == nil {
                triggerRecommendation()
            }
        }
        .onChange(of: state.question) { _, newQuestion in
            // Pre-trigger recommendation as soon as question is set
            if !newQuestion.isEmpty && llm.isReady {
                triggerRecommendation()
            }
        }
    }

    private func triggerRecommendation() {
        guard llm.isReady, !state.question.isEmpty else { return }
        state.isRecommending = true

        Task {
            let spreadInfo = allSpreads.map { spread in
                let positions = SpreadLoader.resolvePositions(
                    spreadKey: spread.id,
                    count: spread.positionCount,
                    using: { i18n.t($0) }
                ).map(\.label)
                return (key: spread.id, name: i18n.t("spreads.\(spread.id).name"), positions: positions)
            }

            let result = await llm.recommendSpread(
                question: state.question,
                spreads: spreadInfo,
                locale: i18n.locale,
                t: { key, params in i18n.t(key, params: params) }
            )

            await MainActor.run {
                state.aiRecommendation = result
                state.isRecommending = false
            }
        }
    }
}
