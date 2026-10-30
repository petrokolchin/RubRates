import Foundation

/// Общий формат чисел для экранов: ru_RU, два знака после запятой, группировка тысяч.
nonisolated enum RuFormat {
    static func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)).locale(Locale(identifier: "ru_RU")))
    }

    /// Число с обязательным знаком для ненулевых значений: «+1,23», «-1,23», «0,00».
    static func signedNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)).sign(strategy: .automatic).locale(Locale(identifier: "ru_RU")))
            .withExplicitPlus(for: value)
    }

    /// Курс валюты: от 1 два знака после запятой (как `number`), меньше 1 три значащие цифры,
    /// иначе курс мелкой валюты (например, донга за единицу) превратился бы в «0,00».
    static func rate(_ value: Double) -> String {
        guard abs(value) < 1, value != 0 else { return number(value) }
        return value.formatted(.number.precision(.significantDigits(3)).locale(Locale(identifier: "ru_RU")))
    }

    /// То же со знаком: «+1,23», «+0,000120», «-0,000120»; ноль без знака.
    static func signedRate(_ value: Double) -> String {
        guard abs(value) < 1, value != 0 else { return signedNumber(value) }
        return rate(value).withExplicitPlus(for: value)
    }

    /// Процент с одним знаком после запятой и знаком: «+1,5%».
    static func signedPercent(_ value: Double) -> String {
        let body = value.formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "ru_RU")))
        return body.withExplicitPlus(for: value) + "%"
    }

    /// Время получения данных: «30 окт., 11:32».
    static func updatedAt(_ date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.timeZone = timeZone
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter.string(from: date)
    }

    /// Дата курса: «23 октября 2026 г.».
    static let dateStyle = Date.FormatStyle(date: .long, time: .omitted, locale: Locale(identifier: "ru_RU"))
}

private extension String {
    /// У положительных чисел ru_RU не пишет плюс, добавляем его сами.
    nonisolated func withExplicitPlus(for value: Double) -> String {
        value > 0 ? "+" + self : self
    }
}
