import SwiftUI
import SwiftData
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct TarotMysticaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State private var appState = AppState()
    @State private var i18n = LocalizationManager()
    @State private var theme = ThemeManager()
    @State private var llm: LLMService

    private let allCards: [TarotCard]
    private let allSpreads: [Spread]
    private let reversalChance: Double
    private let modelContainer: ModelContainer

    init() {
        // Load shared config
        let cardsConfig = DataLoader.loadCards()
        let spreadsConfig = DataLoader.loadSpreads()
        let providersConfig = DataLoader.loadProviders()

        // Generate cards and spreads
        allCards = CardGenerator.generate(from: cardsConfig)
        allSpreads = SpreadLoader.loadAll(from: spreadsConfig)
        reversalChance = cardsConfig.reversalChance

        // Initialize LLM service
        _llm = State(initialValue: LLMService(providersConfig: providersConfig))

        // SwiftData with migration plan
        let schema = Schema([ReadingEntry.self])
        let config = ModelConfiguration(schema: schema)
        modelContainer = (try? ModelContainer(for: schema, migrationPlan: ReadingMigrationPlan.self, configurations: [config]))
            ?? (try! ModelContainer(for: ReadingEntry.self))
    }

    var body: some Scene {
        WindowGroup {
            SplashView {
                AnyView(
                    ZStack {
                        theme.colors.background
                            .ignoresSafeArea()
                        ContentView(
                            allCards: allCards,
                            allSpreads: allSpreads,
                            reversalChance: reversalChance
                        )
                    }
                )
            }
            .environment(appState)
            .environment(i18n)
            .environment(theme)
            .environment(llm)
            .modelContainer(modelContainer)
            .preferredColorScheme(.light)
        }
    }
}
