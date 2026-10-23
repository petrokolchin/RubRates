import Foundation

/// Источник курсов. Протокол нужен, чтобы в тестах подменять сеть.
nonisolated protocol RatesProviding: Sendable {
    func fetch() async throws -> RatesSnapshot
}

nonisolated enum CBRError: Error, Equatable {
    case badStatus(Int)
    case invalidResponse
    case missingCurrency(String)
}

/// Единственное место с сетью: загружает курсы ЦБ РФ и разбирает JSON.
nonisolated struct CBRClient: RatesProviding {
    static let url = URL(string: "https://www.cbr-xml-daily.ru/daily_json.js")!
    static let currencies = ["USD", "CNY", "EUR"]

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch() async throws -> RatesSnapshot {
        let (data, response) = try await session.data(from: Self.url)
        guard let http = response as? HTTPURLResponse else { throw CBRError.invalidResponse }
        guard http.statusCode == 200 else { throw CBRError.badStatus(http.statusCode) }
        return try Self.parse(data)
    }

    static func parse(_ data: Data) throws -> RatesSnapshot {
        let body = try JSONDecoder().decode(Body.self, from: data)
        guard let date = ISO8601DateFormatter().date(from: body.date) else {
            throw CBRError.invalidResponse
        }
        let rates = try currencies.map { code in
            guard let v = body.valute[code] else { throw CBRError.missingCurrency(code) }
            return Rate(code: code, name: v.name, value: v.value, previous: v.previous, nominal: v.nominal)
        }
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
        let name: String
        let nominal: Int
        let value: Double
        let previous: Double

        enum CodingKeys: String, CodingKey {
            case name = "Name"
            case nominal = "Nominal"
            case value = "Value"
            case previous = "Previous"
        }
    }
}
