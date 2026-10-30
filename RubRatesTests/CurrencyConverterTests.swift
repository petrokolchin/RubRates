import Foundation
import Testing
@testable import RubRates

struct CurrencyConverterTests {
    private static func rate(_ code: String, _ value: Double) -> Rate {
        Rate(code: code, cbrID: "R0", name: code, value: value, previous: value, nominal: 1)
    }

    private let rates = [
        CurrencyConverterTests.rate("USD", 80),
        CurrencyConverterTests.rate("EUR", 100),
        CurrencyConverterTests.rate("CNY", 10),
    ]

    @Test func rubToForeign() {
        let result = CurrencyConverter.convert(1000, from: .rub, using: rates)
        #expect(result == [
            Conversion(currency: .foreign("USD"), amount: 12.5),
            Conversion(currency: .foreign("EUR"), amount: 10),
            Conversion(currency: .foreign("CNY"), amount: 100),
        ])
    }

    @Test func foreignToRubAndOthers() {
        let result = CurrencyConverter.convert(10, from: .foreign("USD"), using: rates)
        #expect(result == [
            Conversion(currency: .rub, amount: 800),
            Conversion(currency: .foreign("EUR"), amount: 8),
            Conversion(currency: .foreign("CNY"), amount: 80),
        ])
    }

    @Test func zeroAmountGivesZeros() {
        let result = CurrencyConverter.convert(0, from: .rub, using: rates)
        #expect(result.count == rates.count)
        #expect(result.allSatisfy { $0.amount == 0 })
    }

    @Test func hugeAmountStaysFinite() {
        let result = CurrencyConverter.convert(1e15, from: .foreign("USD"), using: rates)
        #expect(!result.isEmpty)
        #expect(result.allSatisfy { $0.amount.isFinite })
    }

    @Test func unknownSourceGivesEmpty() {
        #expect(CurrencyConverter.convert(5, from: .foreign("GBP"), using: rates) == [])
    }

    @Test func zeroRateIsSkipped() {
        let result = CurrencyConverter.convert(
            1000, from: .rub, using: [Self.rate("USD", 80), Self.rate("XXX", 0)])
        #expect(result == [Conversion(currency: .foreign("USD"), amount: 12.5)])
    }

    @Test(arguments: [
        ("12,5", 12.5), ("12.5", 12.5), ("1 000,5", 1000.5), ("1\u{00A0}000,5", 1000.5),
        ("0", 0), ("1000", 1000),
    ])
    func parsesValidInput(text: String, expected: Double) {
        #expect(CurrencyConverter.parse(text) == expected)
    }

    @Test func hugeDigitStringIsRejected() {
        #expect(CurrencyConverter.parse(String(repeating: "9", count: 400)) == nil)
    }

    @Test func amountAboveLimitIsRejected() {
        #expect(CurrencyConverter.parse("1000000000000000") == 1e15)
        #expect(CurrencyConverter.parse("1000000000000001") == nil)
    }

    @Test(arguments: ["", "   ", "abc", "1.2.3", "1,2,3", "1.000,5", "-5", "1e5", "inf", "nan", ","])
    func rejectsInvalidInput(text: String) {
        #expect(CurrencyConverter.parse(text) == nil)
    }
}
