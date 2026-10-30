import Foundation

/// Заглушки источника курсов для `#Preview`.
struct StaticRatesProvider: RatesProviding {
    func fetch() async throws -> RatesSnapshot {
        RatesSnapshot(date: .now, rates: [
            Rate(code: "USD", cbrID: "R01235", name: "Доллар США", value: 81.1255, previous: 81.9739, nominal: 1),
            Rate(code: "CNY", cbrID: "R01375", name: "Китайский юань", value: 12.146, previous: 12.2806, nominal: 1),
            Rate(code: "EUR", cbrID: "R01239", name: "Евро", value: 91.1364, previous: 91.1364, nominal: 1),
        ])
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
