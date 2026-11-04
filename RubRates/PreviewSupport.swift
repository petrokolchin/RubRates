import Foundation

/// Заглушки источника курсов для `#Preview`.
struct StaticRatesProvider: RatesProviding {
    /// Несколько валют, в том числе с номиналами 100 и 10 000 (мелкий курс за единицу).
    static let sample = SampleRates.rates

    func fetch() async throws -> RatesSnapshot {
        RatesSnapshot(date: .now, rates: Self.sample)
    }
}

struct FailingRatesProvider: RatesProviding {
    func fetch() async throws -> RatesSnapshot { throw CBRError.badStatus(503) }
}

/// Первый запрос успешен, все следующие падают.
actor FlakyRatesProvider: RatesProviding {
    private var calls = 0

    func fetch() async throws -> RatesSnapshot {
        calls += 1
        if calls > 1 { throw CBRError.badStatus(503) }
        return try await StaticRatesProvider().fetch()
    }
}

/// Синтетическая история: плавная волна вокруг 80 по дню на каждый день периода.
struct StaticHistoryProvider: HistoryProviding {
    func fetch(id: String, from: Date, to: Date) async throws -> [RatePoint] {
        var points: [RatePoint] = []
        var day = from
        var index = 0.0
        while day <= to {
            points.append(RatePoint(date: day, value: 80 + 3 * sin(index / 6)))
            day = Calendar.current.date(byAdding: .day, value: 1, to: day)!
            index += 1
        }
        return points
    }
}

struct FailingHistoryProvider: HistoryProviding {
    func fetch(id: String, from: Date, to: Date) async throws -> [RatePoint] { throw CBRError.badStatus(503) }
}

extension CurrencySelection {
    /// Выбор для превью: отдельные настройки, настоящие не трогает.
    static func preview(_ codes: [String] = defaultCodes) -> CurrencySelection {
        let defaults = UserDefaults(suiteName: "RubRatesPreview")!
        defaults.set(codes, forKey: storageKey)
        return CurrencySelection(defaults: defaults)
    }
}
