import Foundation

/// Заглушки источника курсов для `#Preview`.
struct StaticRatesProvider: RatesProviding {
    /// Несколько валют, в том числе с номиналами 100 и 10 000 (мелкий курс за единицу).
    static let sample = [
        Rate(code: "USD", cbrID: "R01235", name: "Доллар США", value: 81.1255, previous: 81.9739, nominal: 1),
        Rate(code: "CNY", cbrID: "R01375", name: "Китайский юань", value: 12.146, previous: 12.2806, nominal: 1),
        Rate(code: "EUR", cbrID: "R01239", name: "Евро", value: 91.1364, previous: 91.1364, nominal: 1),
        Rate(code: "GBP", cbrID: "R01035", name: "Фунт стерлингов", value: 106.2, previous: 105.9, nominal: 1),
        Rate(code: "JPY", cbrID: "R01820", name: "Японских иен", value: 53.4, previous: 53.9, nominal: 100),
        Rate(code: "TRY", cbrID: "R01700J", name: "Турецких лир", value: 23.7, previous: 23.5, nominal: 10),
        Rate(code: "VND", cbrID: "R01150", name: "Вьетнамских донгов", value: 33.8, previous: 33.5, nominal: 10_000),
    ]

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
