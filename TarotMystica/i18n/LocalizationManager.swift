import Foundation

@Observable
final class LocalizationManager {
    private(set) var locale: String = "en"
    private var strings: [String: Any] = [:]
    private static let supportedLocales = ["en", "zh", "fr", "es"]

    init() {
        // Load saved locale, fallback to system language
        if let saved = UserDefaults.standard.string(forKey: "selectedLocale"),
           Self.supportedLocales.contains(saved) {
            locale = saved
        } else {
            let preferred = Locale.preferredLanguages.first ?? "en"
            let lang = String(preferred.prefix(2))
            locale = Self.supportedLocales.contains(lang) ? lang : "en"
        }
        loadStrings()
    }

    func setLocale(_ newLocale: String) {
        guard Self.supportedLocales.contains(newLocale), newLocale != locale else { return }
        locale = newLocale
        UserDefaults.standard.set(newLocale, forKey: "selectedLocale")
        loadStrings()
    }

    /// Translate key path like "hero.title" → nested JSON value
    func t(_ keyPath: String, params: [String: String] = [:]) -> String {
        let keys = keyPath.split(separator: ".").map(String.init)
        var current: Any = strings

        for key in keys {
            guard let dict = current as? [String: Any],
                  let next = dict[key] else {
                return keyPath  // fallback: return key itself
            }
            current = next
        }

        guard var result = current as? String else {
            return keyPath
        }

        // Simple parameter substitution: {paramName} → value
        for (key, value) in params {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }

        // Strip ICU single-quote escaping for literal braces
        result = result.replacingOccurrences(of: "'{", with: "{")
        result = result.replacingOccurrences(of: "}'", with: "}")

        return result
    }

    private func loadStrings() {
        guard let url = Bundle.main.url(forResource: locale, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            #if DEBUG
            print("[i18n] Failed to load \(locale).json from bundle")
            #endif
            strings = [:]
            return
        }
        strings = json
    }
}
