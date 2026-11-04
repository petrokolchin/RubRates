import Foundation

/// Образцы курсов для превью и заглушки виджета.
nonisolated enum SampleRates {
    /// Несколько валют, в том числе с номиналами 100 и 10 000 (мелкий курс за единицу).
    static let rates = [
        Rate(code: "USD", cbrID: "R01235", name: "Доллар США", value: 81.1255, previous: 81.9739, nominal: 1),
        Rate(code: "CNY", cbrID: "R01375", name: "Китайский юань", value: 12.146, previous: 12.2806, nominal: 1),
        Rate(code: "EUR", cbrID: "R01239", name: "Евро", value: 91.1364, previous: 91.1364, nominal: 1),
        Rate(code: "GBP", cbrID: "R01035", name: "Фунт стерлингов", value: 106.2, previous: 105.9, nominal: 1),
        Rate(code: "JPY", cbrID: "R01820", name: "Японских иен", value: 53.4, previous: 53.9, nominal: 100),
        Rate(code: "TRY", cbrID: "R01700J", name: "Турецких лир", value: 23.7, previous: 23.5, nominal: 10),
        Rate(code: "VND", cbrID: "R01150", name: "Вьетнамских донгов", value: 33.8, previous: 33.5, nominal: 10_000),
    ]
}
