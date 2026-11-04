import Foundation

/// Период графика: `rawValue` — число дней.
nonisolated enum HistoryPeriod: Int, CaseIterable, Identifiable {
    case week = 7
    case month = 30
    case quarter = 90
    case year = 365

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .week: "7 дн"
        case .month: "30 дн"
        case .quarter: "90 дн"
        case .year: "Год"
        }
    }

    /// Начало периода: конец минус `rawValue` дней по календарю Москвы (даты ЦБ московские).
    func start(endingAt end: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Moscow")!
        return calendar.date(byAdding: .day, value: -rawValue, to: end)!
    }
}
