import FirebaseAnalytics
import FirebaseCrashlytics

/// Lightweight analytics wrapper for key MVP events
enum TarotAnalytics {

    /// Log spread selection
    static func logSpreadSelected(_ spreadKey: String) {
        Analytics.logEvent("spread_selected", parameters: ["spread_key": spreadKey])
    }

    /// Log AI interpretation completed (or failed)
    static func logAIInterpretation(completed: Bool, provider: String) {
        Analytics.logEvent("ai_interpretation", parameters: [
            "completed": completed ? "true" : "false",
            "provider": provider,
        ])
    }

    /// Log local model selection
    static func logModelSelected(_ modelId: String) {
        Analytics.logEvent("model_selected", parameters: ["model_id": modelId])
    }

    /// Log follow-up chat usage
    static func logFollowUpChat() {
        Analytics.logEvent("followup_chat", parameters: nil)
    }

    /// Log non-fatal error for Crashlytics
    static func logError(_ error: Error, context: String) {
        Crashlytics.crashlytics().record(error: error, userInfo: ["context": context])
    }
}
