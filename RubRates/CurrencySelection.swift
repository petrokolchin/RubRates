import Foundation
import Observation
import SwiftUI

/// «Мои валюты»: упорядоченный набор кодов валют, который показывают курсы и конвертер.
/// Хранится в `UserDefaults` (это настройка, а не кэш): каждое изменение сразу сохраняется.
@MainActor
@Observable
final class CurrencySelection {
    nonisolated static let defaultCodes = ["USD", "CNY", "EUR"]
    nonisolated static let storageKey = "selectedCurrencyCodes"

    private(set) var codes: [String]

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Не массив строк или пустой массив считаем «не сохранено».
        if let saved = defaults.stringArray(forKey: Self.storageKey), !saved.isEmpty {
            // Дубли в повреждённых настройках убираем, сохраняя порядок первых вхождений.
            var seen = Set<String>()
            codes = saved.filter { seen.insert($0).inserted }
        } else {
            codes = Self.defaultCodes
        }
    }

    func add(_ code: String) {
        guard !codes.contains(code) else { return }
        codes.append(code)
        save()
    }

    /// Последнюю валюту убрать нельзя: конвертеру и списку нужна хотя бы одна.
    func remove(_ code: String) {
        guard codes.count > 1, let index = codes.firstIndex(of: code) else { return }
        codes.remove(at: index)
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        codes.move(fromOffsets: source, toOffset: destination)
        save()
    }

    /// Курсы выбранных валют в выбранном порядке; кодов, которых нет в снимке, нет и в результате.
    /// Если не нашлось ни одной выбранной валюты, показываем валюты по умолчанию, а если и их нет,
    /// первую из снимка: экран не должен остаться пустым. Сохранённый выбор при этом не меняется.
    func rates(in snapshot: RatesSnapshot) -> [Rate] {
        let byCode = Dictionary(snapshot.rates.map { ($0.code, $0) }, uniquingKeysWith: { first, _ in first })
        let selected = codes.compactMap { byCode[$0] }
        if !selected.isEmpty { return selected }
        let defaults = Self.defaultCodes.compactMap { byCode[$0] }
        if !defaults.isEmpty { return defaults }
        return snapshot.rates.prefix(1).map { $0 }
    }

    /// Поиск по коду и названию без учёта регистра; пробелы по краям запроса не важны.
    nonisolated static func search(_ rates: [Rate], query: String) -> [Rate] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return rates }
        return rates.filter { $0.code.localizedCaseInsensitiveContains(query) || $0.name.localizedCaseInsensitiveContains(query) }
    }

    private func save() {
        defaults.set(codes, forKey: Self.storageKey)
    }
}
