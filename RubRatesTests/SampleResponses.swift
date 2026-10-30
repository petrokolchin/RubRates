import Foundation

/// Образцы ответа `daily_json.js` (значения от 2026-10-23).
enum SampleResponses {
    /// ID валют ЦБ, как в настоящем ответе.
    private static let ids = ["USD": "R01235", "CNY": "R01375", "EUR": "R01239", "JPY": "R01820"]

    private static func valute(_ code: String, _ name: String, nominal: Int, value: Double, previous: Double) -> String {
        """
        "\(code)": {"ID": "\(ids[code] ?? "R0")", "NumCode": "000", "CharCode": "\(code)", "Nominal": \(nominal), \
        "Name": "\(name)", "Value": \(value), "Previous": \(previous)}
        """
    }

    private static func response(_ valutes: [String]) -> String {
        """
        {"Date": "2026-10-23T11:30:00+03:00", "PreviousDate": "2026-10-22T11:30:00+03:00", \
        "Valute": {\(valutes.joined(separator: ","))}}
        """
    }

    private static let usd = valute("USD", "Доллар США", nominal: 1, value: 81.1255, previous: 81.9739)
    private static let eur = valute("EUR", "Евро", nominal: 1, value: 91.1364, previous: 91.9337)
    private static let jpy = valute("JPY", "Японских иен", nominal: 100, value: 53.4, previous: 53.9)

    static let daily = response([
        usd, jpy,
        valute("CNY", "Китайский юань", nominal: 1, value: 12.146, previous: 12.2806),
        eur,
    ])

    static let nominalTen = response([
        usd,
        valute("CNY", "Китайский юань", nominal: 10, value: 121.46, previous: 122.806),
        eur,
    ])

    static let emptyValutes = response([])
}
