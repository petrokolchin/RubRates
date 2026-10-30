import Foundation

/// Источник истории курса. Протокол нужен, чтобы в тестах подменять сеть.
nonisolated protocol HistoryProviding: Sendable {
    func fetch(id: String, from: Date, to: Date) async throws -> [RatePoint]
}

/// Загружает динамику курса из официального XML ЦБ РФ и разбирает его.
nonisolated struct CBRHistoryClient: HistoryProviding {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch(id: String, from: Date, to: Date) async throws -> [RatePoint] {
        let request = URLRequest(url: Self.makeURL(id: id, from: from, to: to), cachePolicy: .reloadIgnoringLocalCacheData)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CBRError.invalidResponse }
        guard http.statusCode == 200 else { throw CBRError.badStatus(http.statusCode) }
        return try Self.parse(data)
    }

    static func makeURL(id: String, from: Date, to: Date) -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = moscow
        formatter.dateFormat = "dd/MM/yyyy"
        var components = URLComponents(string: "https://www.cbr.ru/scripts/XML_dynamic.asp")!
        components.queryItems = [
            URLQueryItem(name: "date_req1", value: formatter.string(from: from)),
            URLQueryItem(name: "date_req2", value: formatter.string(from: to)),
            URLQueryItem(name: "VAL_NM_RQ", value: id),
        ]
        return components.url!
    }

    /// Точки по возрастанию даты; курс за одну единицу (`Value / Nominal`).
    static func parse(_ data: Data) throws -> [RatePoint] {
        let parser = XMLParser(data: data)
        let collector = Collector()
        parser.delegate = collector
        guard parser.parse(), !collector.failed else {
            throw collector.failed ? CBRError.invalidResponse : (parser.parserError ?? CBRError.invalidResponse)
        }
        return collector.points.sorted { $0.date < $1.date }
    }

    private static let moscow = TimeZone(identifier: "Europe/Moscow")!

    /// Собирает `<Record Date="…"><Nominal>…</Nominal><Value>…</Value></Record>`.
    private final class Collector: NSObject, XMLParserDelegate {
        private(set) var points: [RatePoint] = []
        private(set) var failed = false

        private let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = CBRHistoryClient.moscow
            formatter.dateFormat = "dd.MM.yyyy"
            return formatter
        }()

        private var date: String?
        private var nominal = ""
        private var value = ""
        private var element = ""

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                    qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
            element = elementName
            if elementName == "Record" {
                date = attributeDict["Date"]
                nominal = ""
                value = ""
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            switch element {
            case "Nominal": nominal += string
            case "Value": value += string
            default: break
            }
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                    qualifiedName qName: String?) {
            element = ""
            guard elementName == "Record" else { return }
            let number = value.trimmingCharacters(in: .whitespaces).replacing(",", with: ".")
            guard let date, let day = dateFormatter.date(from: date),
                  let nominal = Int(nominal.trimmingCharacters(in: .whitespaces)), nominal > 0,
                  let perNominal = Double(number)
            else {
                failed = true
                parser.abortParsing()
                return
            }
            points.append(RatePoint(date: day, value: perNominal / Double(nominal)))
        }
    }
}
