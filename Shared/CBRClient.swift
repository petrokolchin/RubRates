import Foundation

/// Источник курсов. Протокол нужен, чтобы в тестах подменять сеть.
nonisolated protocol RatesProviding: Sendable {
    func fetch() async throws -> RatesSnapshot
}

nonisolated enum CBRError: Error, Equatable {
    case badStatus(Int)
    case invalidResponse
}

/// Единственное место с сетью: загружает курсы ЦБ РФ и разбирает JSON.
nonisolated struct CBRClient: RatesProviding {
    static let url = URL(string: "https://www.cbr-xml-daily.ru/daily_json.js")!

    private let session: URLSession
    private let timeout: TimeInterval?

    /// `timeout` — тайм-аут запроса в секундах; `nil` оставляет системный (60 с). Виджету нужен короткий.
    init(session: URLSession = .shared, timeout: TimeInterval? = nil) {
        self.session = session
        self.timeout = timeout
    }

    func fetch() async throws -> RatesSnapshot {
        // Сервер разрешает кэшировать ответ на 2 часа; обновление должно ходить в сеть.
        var request = URLRequest(url: Self.url, cachePolicy: .reloadIgnoringLocalCacheData)
        if let timeout { request.timeoutInterval = timeout }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CBRError.invalidResponse }
        guard http.statusCode == 200 else { throw CBRError.badStatus(http.statusCode) }
        return try Self.parse(data)
    }

    static func parse(_ data: Data) throws -> RatesSnapshot {
        let body = try JSONDecoder().decode(Body.self, from: data)
        guard let date = ISO8601DateFormatter().date(from: body.date) else {
            throw CBRError.invalidResponse
        }
        // Порядок ключей JSON декодер не гарантирует, поэтому сортируем по коду: порядок стабилен.
        // Валюту с номиналом 0 или меньше пропускаем: деление на него дало бы бесконечность.
        let rates = body.valute.filter { $0.value.nominal > 0 }.sorted { $0.key < $1.key }.map { code, v in
            Rate(code: code, cbrID: v.id, name: v.name, value: v.value, previous: v.previous, nominal: v.nominal)
        }
        guard !rates.isEmpty else { throw CBRError.invalidResponse }
        return RatesSnapshot(date: date, rates: rates)
    }

    // Форма JSON ЦБ; нужны только эти поля.
    private struct Body: Decodable {
        let date: String
        let valute: [String: Valute]

        enum CodingKeys: String, CodingKey {
            case date = "Date"
            case valute = "Valute"
        }
    }

    private struct Valute: Decodable {
        let id: String
        let name: String
        let nominal: Int
        let value: Double
        let previous: Double

        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case name = "Name"
            case nominal = "Nominal"
            case value = "Value"
            case previous = "Previous"
        }
    }
}
