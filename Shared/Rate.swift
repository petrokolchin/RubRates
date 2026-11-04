import Foundation

/// Курс одной валюты к рублю. `value` и `previous` хранятся за одну единицу валюты.
nonisolated struct Rate: Equatable, Identifiable, Codable {
    let code: String
    /// ID валюты в справочнике ЦБ (например, `R01235` для USD), нужен для запроса истории.
    let cbrID: String
    let name: String
    let value: Double
    let previous: Double

    var id: String { code }

    /// Изменение курса относительно предыдущего дня.
    var change: Double { value - previous }

    /// Изменение, округлённое так же, как показывается: до копеек при курсе от 1,
    /// до трёх значащих цифр при меньшем (иначе у мелких валют изменение всегда нулевое).
    var roundedChange: Double {
        if abs(value) >= 1 { return (change * 100).rounded() / 100 }
        return Double(String(format: "%.3g", change)) ?? 0
    }

    /// ЦБ отдаёт курс за `nominal` единиц (например, 100 иен), поэтому делим.
    init(code: String, cbrID: String, name: String, value: Double, previous: Double, nominal: Int) {
        self.code = code
        self.cbrID = cbrID
        self.name = name
        self.value = value / Double(nominal)
        self.previous = previous / Double(nominal)
    }
}

/// Курсы на одну дату.
nonisolated struct RatesSnapshot: Equatable, Codable {
    let date: Date
    let rates: [Rate]
}
