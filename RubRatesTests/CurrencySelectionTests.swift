import Foundation
import SwiftUI
import Testing
@testable import RubRates

@MainActor
struct CurrencySelectionTests {
    /// Изолированные настройки на один тест.
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "RubRatesTests-\(UUID().uuidString)")!
    }

    private func rate(_ code: String, _ name: String) -> Rate {
        Rate(code: code, cbrID: "R0", name: name, value: 80, previous: 80, nominal: 1)
    }

    private var catalog: [Rate] {
        [rate("USD", "Доллар США"), rate("CNY", "Китайский юань"), rate("EUR", "Евро"), rate("GBP", "Фунт стерлингов")]
    }

    @Test func defaultsWhenEmpty() {
        #expect(CurrencySelection(defaults: makeDefaults()).codes == ["USD", "CNY", "EUR"])
    }

    @Test func addAppends() {
        let selection = CurrencySelection(defaults: makeDefaults())
        selection.add("GBP")
        #expect(selection.codes == ["USD", "CNY", "EUR", "GBP"])
    }

    @Test func addIgnoresDuplicate() {
        let selection = CurrencySelection(defaults: makeDefaults())
        selection.add("USD")
        #expect(selection.codes == ["USD", "CNY", "EUR"])
    }

    @Test func removeRemoves() {
        let selection = CurrencySelection(defaults: makeDefaults())
        selection.remove("CNY")
        #expect(selection.codes == ["USD", "EUR"])
    }

    @Test func removeLastIsIgnored() {
        let selection = CurrencySelection(defaults: makeDefaults())
        selection.remove("USD")
        selection.remove("CNY")
        selection.remove("EUR")
        #expect(selection.codes == ["EUR"])
    }

    @Test func moveReorders() {
        let selection = CurrencySelection(defaults: makeDefaults())
        selection.move(from: IndexSet(integer: 2), to: 0)
        #expect(selection.codes == ["EUR", "USD", "CNY"])
    }

    @Test func persistsAcrossInstances() {
        let defaults = makeDefaults()
        let first = CurrencySelection(defaults: defaults)
        first.add("TRY")
        first.remove("CNY")
        #expect(CurrencySelection(defaults: defaults).codes == ["USD", "EUR", "TRY"])
    }

    @Test(arguments: [("junk" as Any), ([1, 2] as Any), ([String]() as Any)])
    func corruptedDataFallsBack(value: Any) {
        let defaults = makeDefaults()
        defaults.set(value, forKey: CurrencySelection.storageKey)
        #expect(CurrencySelection(defaults: defaults).codes == CurrencySelection.defaultCodes)
    }

    @Test func ratesFollowSelectionOrder() {
        let defaults = makeDefaults()
        defaults.set(["GBP", "USD"], forKey: CurrencySelection.storageKey)
        let snapshot = RatesSnapshot(date: .now, rates: catalog)
        #expect(CurrencySelection(defaults: defaults).rates(in: snapshot).map(\.code) == ["GBP", "USD"])
    }

    @Test func ratesSkipMissingCodes() {
        let defaults = makeDefaults()
        defaults.set(["USD", "XXX"], forKey: CurrencySelection.storageKey)
        let snapshot = RatesSnapshot(date: .now, rates: catalog)
        #expect(CurrencySelection(defaults: defaults).rates(in: snapshot).map(\.code) == ["USD"])

        defaults.set(["XXX"], forKey: CurrencySelection.storageKey)
        #expect(CurrencySelection(defaults: defaults).rates(in: snapshot) == [])
    }

    @Test func searchByCodeAndName() {
        #expect(CurrencySelection.search(catalog, query: "usd").map(\.code) == ["USD"])
        #expect(CurrencySelection.search(catalog, query: "USD").map(\.code) == ["USD"])
        #expect(CurrencySelection.search(catalog, query: "доллар").map(\.code) == ["USD"])
        #expect(CurrencySelection.search(catalog, query: "ДОЛЛАР").map(\.code) == ["USD"])
        #expect(CurrencySelection.search(catalog, query: "  юань ").map(\.code) == ["CNY"])
    }

    @Test func searchEdgeCases() {
        #expect(CurrencySelection.search(catalog, query: "").count == catalog.count)
        #expect(CurrencySelection.search(catalog, query: "   ").count == catalog.count)
        #expect(CurrencySelection.search(catalog, query: "нет такой") == [])
    }
}
