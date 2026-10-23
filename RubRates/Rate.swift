import Foundation

/// Курс одной валюты к рублю. `value` и `previous` хранятся за одну единицу валюты.
struct Rate: Equatable, Identifiable {
    let code: String
    let name: String
    let value: Double
    let previous: Double

    var id: String { code }

    /// Изменение курса относительно предыдущего дня.
    var change: Double { value - previous }

    /// ЦБ отдаёт курс за `nominal` единиц (например, 100 иен), поэтому делим.
    init(code: String, name: String, value: Double, previous: Double, nominal: Int) {
        self.code = code
        self.name = name
        self.value = value / Double(nominal)
        self.previous = previous / Double(nominal)
    }
}

/// Курсы на одну дату.
struct RatesSnapshot: Equatable {
    let date: Date
    let rates: [Rate]
}
