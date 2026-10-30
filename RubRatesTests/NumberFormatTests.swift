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

    private func normalized(_ text: String) -> String {
        plain(text).replacing("\u{2212}", with: "-")
    }

    @Test func rateUsesTwoDecimalsFromOne() {
        #expect(normalized(RuFormat.rate(81.1255)) == "81,13")
        #expect(normalized(RuFormat.rate(12345.6)) == "12 345,60")
        #expect(RuFormat.rate(0) == "0,00")
    }

    @Test func rateKeepsSignificantDigitsBelowOne() {
        #expect(normalized(RuFormat.rate(0.00338)) == "0,00338")
        #expect(normalized(RuFormat.rate(0.0034012)) == "0,00340")
    }

    @Test func signedRateHasSign() {
        #expect(normalized(RuFormat.signedRate(0.00012)) == "+0,000120")
        #expect(normalized(RuFormat.signedRate(-0.00012)) == "-0,000120")
        #expect(normalized(RuFormat.signedRate(1.234)) == "+1,23")
        #expect(RuFormat.signedRate(0) == "0,00")
    }
}
