import Foundation

/// Общий формат чисел для экранов: ru_RU, два знака после запятой, группировка тысяч.
nonisolated enum RuFormat {
    static func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)).locale(Locale(identifier: "ru_RU")))
    }

    /// Дата курса: «23 октября 2026 г.».
    static let dateStyle = Date.FormatStyle(date: .long, time: .omitted, locale: Locale(identifier: "ru_RU"))
}
