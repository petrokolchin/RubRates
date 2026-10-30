import Foundation

/// Курс одной валюты к рублю. `value` и `previous` хранятся за одну единицу валюты.
nonisolated struct Rate: Equatable, Identifiable {
    let code: String
    /// ID валюты в справочнике ЦБ (например, `R01235` для USD), нужен для запроса истории.
    let cbrID: String
    let name: String
    let value: Double
    let previous: Double

    var id: String { code }

    /// Изменение курса относительно предыдущего дня.
    var change: Double { value - previous }

    /// Изменение, округлённое до копеек: именно оно показывается на экране.
    var roundedChange: Double { (change * 100).rounded() / 100 }

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
nonisolated struct RatesSnapshot: Equatable {
    let date: Date
    let rates: [Rate]
}
