import Foundation

/// Курс за одну единицу валюты на конкретную дату.
nonisolated struct RatePoint: Equatable, Identifiable, Codable {
    let date: Date
    let value: Double

    var id: Date { date }
}

/// Изменение курса за период: разница последней и первой точки и процент от первой.
nonisolated struct PeriodChange: Equatable {
    let absolute: Double
    let percent: Double

    /// `nil`, если точек меньше двух или первое значение равно нулю (процент не определён).
    static func make(from points: [RatePoint]) -> PeriodChange? {
        guard let first = points.first, let last = points.last, points.count >= 2, first.value != 0 else {
            return nil
        }
        let absolute = last.value - first.value
        return PeriodChange(absolute: absolute, percent: absolute / first.value * 100)
    }
}
