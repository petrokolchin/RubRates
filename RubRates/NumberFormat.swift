import Foundation

/// Общий формат чисел для экранов: ru_RU, два знака после запятой, группировка тысяч.
nonisolated enum RuFormat {
    static func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)).locale(Locale(identifier: "ru_RU")))
    }

    /// Число с обязательным знаком для ненулевых значений: «+1,23», «-1,23», «0,00».
    static func signedNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)).sign(strategy: .automatic).locale(Locale(identifier: "ru_RU")))
            .withExplicitPlus(for: value)
    }

    /// Процент с одним знаком после запятой и знаком: «+1,5%».
    static func signedPercent(_ value: Double) -> String {
        let body = value.formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "ru_RU")))
        return body.withExplicitPlus(for: value) + "%"
    }

    /// Дата курса: «23 октября 2026 г.».
    static let dateStyle = Date.FormatStyle(date: .long, time: .omitted, locale: Locale(identifier: "ru_RU"))
}

private extension String {
    /// У положительных чисел ru_RU не пишет плюс, добавляем его сами.
    nonisolated func withExplicitPlus(for value: Double) -> String {
        value > 0 ? "+" + self : self
    }
}
