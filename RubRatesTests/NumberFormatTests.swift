import Foundation
import Testing
@testable import RubRates

struct NumberFormatTests {
    /// Группировку делают неразрывные и узкие пробелы; для сравнения приводим их к обычному.
    private func plain(_ text: String) -> String {
        String(text.map { $0.isWhitespace ? " " : $0 })
    }

    @Test func numberUsesRussianGroupingAndTwoDecimals() {
        #expect(plain(RuFormat.number(81125.5)) == "81 125,50")
        #expect(RuFormat.number(0) == "0,00")
    }

    @Test func signedNumberAlwaysShowsSign() {
        #expect(plain(RuFormat.signedNumber(1.234)).replacing("\u{2212}", with: "-") == "+1,23")
        #expect(plain(RuFormat.signedNumber(-1.234)).replacing("\u{2212}", with: "-") == "-1,23")
        #expect(RuFormat.signedNumber(0) == "0,00")
    }

    @Test func signedPercentHasOneDecimal() {
        #expect(plain(RuFormat.signedPercent(1.54)).replacing("\u{2212}", with: "-") == "+1,5%")
        #expect(plain(RuFormat.signedPercent(-1.54)).replacing("\u{2212}", with: "-") == "-1,5%")
    }

    @Test func updatedAtFormat() {
        let moscow = TimeZone(identifier: "Europe/Moscow")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = moscow
        let date = calendar.date(from: DateComponents(year: 2026, month: 10, day: 30, hour: 11, minute: 32))!
        let text = RuFormat.updatedAt(date, timeZone: moscow)
        #expect(text.contains("30"))
        #expect(text.contains("окт"))
        #expect(text.contains("11:32"))
        #expect(!text.contains("2026"))
    }
}
