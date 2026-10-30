import Foundation

/// Масштаб оси Y графика курса.
nonisolated enum ChartScale {
    /// Диапазон по данным с запасом 10% и минимумом в полпроцента величины курса: запас в рублях
    /// (как было раньше) для курса за единицу меньше копейки уводил бы ось в минус и сплющивал линию.
    static func yDomain(low: Double, high: Double) -> ClosedRange<Double> {
        var pad = max((high - low) * 0.1, abs(high) * 0.005)
        if pad == 0 { pad = 1 }
        return (low - pad)...(high + pad)
    }
}
