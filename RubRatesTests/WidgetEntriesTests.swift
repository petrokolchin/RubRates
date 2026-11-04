import Foundation
import Testing
@testable import RubRates

struct WidgetEntriesTests {
    private func rate(_ code: String) -> Rate {
        Rate(code: code, cbrID: "R0", name: code, value: 80, previous: 79, nominal: 1)
    }

    private let date = Date(timeIntervalSince1970: 1_792_000_000)

    private func snapshot(_ codes: [String]) -> RatesSnapshot {
        RatesSnapshot(date: date, rates: codes.map(rate))
    }

    @Test func smallTakesFirstAvailableCurrency() {
        let content = WidgetEntries.content(size: .small, snapshot: snapshot(["USD", "GBP"]), codes: ["XXX", "GBP", "USD"])
        #expect(content == .rates(date: date, rates: [rate("GBP")]))
    }

    @Test func mediumTakesAtMostFourInSelectionOrder() {
        let all = ["USD", "CNY", "EUR", "GBP", "JPY", "TRY"]
        let content = WidgetEntries.content(size: .medium, snapshot: snapshot(all), codes: ["TRY", "JPY", "GBP", "EUR", "CNY", "USD"])
        #expect(content == .rates(date: date, rates: ["TRY", "JPY", "GBP", "EUR"].map(rate)))
    }

    @Test func missingSnapshotGivesNoData() {
        #expect(WidgetEntries.content(size: .medium, snapshot: nil, codes: ["USD"]) == .noData)
    }

    @Test func noMatchingCodesFallBackToDefaults() {
        let content = WidgetEntries.content(size: .medium, snapshot: snapshot(["EUR", "USD", "CNY", "GBP"]), codes: ["XXX"])
        #expect(content == .rates(date: date, rates: ["USD", "CNY", "EUR"].map(rate)))
    }

    @Test func singleAvailableRateInMediumHasNoPadding() {
        let content = WidgetEntries.content(size: .medium, snapshot: snapshot(["USD"]), codes: ["USD", "EUR"])
        #expect(content == .rates(date: date, rates: [rate("USD")]))
    }

    @Test func emptySnapshotGivesNoData() {
        #expect(WidgetEntries.content(size: .small, snapshot: snapshot([]), codes: ["USD"]) == .noData)
    }
}
