import Foundation

/// Валюта конвертера: рубль или иностранная валюта с кодом ЦБ.
nonisolated enum Currency: Hashable, Identifiable {
    case rub
    case foreign(String)

    var code: String {
        switch self {
        case .rub: "RUB"
        case .foreign(let code): code
        }
    }

    var id: String { code }
}

/// Сумма в одной из валют, результат конвертации.
nonisolated struct Conversion: Equatable, Identifiable {
    let currency: Currency
    let amount: Double

    var id: String { currency.id }
}

/// Чистая логика конвертера: разбор ввода и пересчёт через рубль.
nonisolated enum CurrencyConverter {
    /// Верхняя граница суммы: гарантирует конечные результаты конвертации.
    static let maxAmount = 1e15

    /// Разбирает введённую сумму. Принимает запятую и точку, игнорирует пробелы.
    /// Всё, что не похоже на обычное неотрицательное число, даёт `nil`; суммы больше `maxAmount` тоже,
    /// иначе очень длинный ввод дал бы `inf` в результатах.
    static func parse(_ text: String) -> Double? {
        let compact = text.filter { !$0.isWhitespace }
        let normalized = compact.replacing(",", with: ".")
        guard normalized.contains(where: \.isASCIIDigit),
              normalized.allSatisfy({ $0.isASCIIDigit || $0 == "." }),
              normalized.count(where: { $0 == "." }) <= 1
        else { return nil }
        guard let value = Double(normalized), value <= maxAmount else { return nil }
        return value
    }

    /// Эквиваленты суммы во всех валютах, кроме исходной: сначала рубль, затем курсы по порядку.
    /// Если исходной валюты нет среди курсов, результат пустой. Курсы с нулевым значением пропускаются.
    static func convert(_ amount: Double, from source: Currency, using rates: [Rate]) -> [Conversion] {
        let rubles: Double
        switch source {
        case .rub:
            rubles = amount
        case .foreign(let code):
            guard let rate = rates.first(where: { $0.code == code }) else { return [] }
            rubles = amount * rate.value
        }

        var result: [Conversion] = []
        if source != .rub {
            result.append(Conversion(currency: .rub, amount: rubles))
        }
        for rate in rates where rate.value > 0 && .foreign(rate.code) != source {
            result.append(Conversion(currency: .foreign(rate.code), amount: rubles / rate.value))
        }
        return result
    }
}

private extension Character {
    nonisolated var isASCIIDigit: Bool { ("0"..."9").contains(self) }
}
