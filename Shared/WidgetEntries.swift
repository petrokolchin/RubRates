import Foundation

/// Размер виджета и сколько валют в нём помещается.
nonisolated enum WidgetSize: Equatable {
    case small, medium

    var maxRows: Int {
        switch self {
        case .small: 1
        case .medium: 4
        }
    }
}

/// Что показывает виджет: курсы на дату или заглушку «нет данных».
nonisolated enum WidgetContent: Equatable {
    case rates(date: Date, rates: [Rate])
    case noData
}

nonisolated enum WidgetEntries {
    /// Выбранные валюты в выбранном порядке, не больше, чем помещается в `size`.
    /// Если выбранных нет в курсах, берутся валюты по умолчанию (см. `CurrencySelection.rates(in:codes:)`).
    static func content(size: WidgetSize, snapshot: RatesSnapshot?, codes: [String]) -> WidgetContent {
        guard let snapshot else { return .noData }
        let rates = CurrencySelection.rates(in: snapshot, codes: codes).prefix(size.maxRows)
        guard !rates.isEmpty else { return .noData }
        return .rates(date: snapshot.date, rates: Array(rates))
    }
}
