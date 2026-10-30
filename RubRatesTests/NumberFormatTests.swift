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
}
