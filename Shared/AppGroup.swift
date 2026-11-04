import Foundation

/// Общая с виджетом папка и настройки (App Group). Если группа недоступна (нет entitlement),
/// всё работает как раньше: `UserDefaults.standard` и папка в `Caches` приложения.
nonisolated enum AppGroup {
    static let identifier = "group.test.RubRates"

    static func containerURL(_ manager: FileManager = .default) -> URL? {
        manager.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    /// Настройки, общие для приложения и виджета; `.standard`, если контейнера нет.
    static func sharedDefaults() -> UserDefaults {
        guard containerURL() != nil, let defaults = UserDefaults(suiteName: identifier) else { return .standard }
        return defaults
    }

    /// Папка кэша в контейнере группы; `nil`, если группа недоступна.
    static func sharedCacheDirectory() -> URL? {
        containerURL()?.appending(path: "RubRatesCache")
    }
}
