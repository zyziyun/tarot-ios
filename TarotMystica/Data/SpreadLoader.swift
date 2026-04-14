import Foundation

/// Loads spreads from spreads.json config
enum SpreadLoader {

    static func loadAll(from config: DataLoader.SpreadsConfig) -> [Spread] {
        config.spreads.map { def in
            Spread(
                id: def.key,
                icon: def.icon,
                positionCount: def.positionCount
            )
        }
    }

    /// Resolve position labels from i18n for a given spread key
    static func resolvePositions(
        spreadKey: String,
        count: Int,
        using t: (String) -> String
    ) -> [SpreadPosition] {
        (0..<count).map { idx in
            SpreadPosition(
                label: t("spreads.\(spreadKey).pos\(idx).label"),
                description: t("spreads.\(spreadKey).pos\(idx).description")
            )
        }
    }
}
