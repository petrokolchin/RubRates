import Foundation

/// Вкладки приложения.
nonisolated enum AppTab: Hashable {
    case rates, converter
}

/// Ссылка, по которой виджет открывает приложение на нужной вкладке.
nonisolated enum AppLink {
    static let ratesURL = URL(string: "rubrates://rates")!

    static func tab(for url: URL) -> AppTab? {
        url == ratesURL ? .rates : nil
    }
}
