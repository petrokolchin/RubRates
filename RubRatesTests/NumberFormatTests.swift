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
}
