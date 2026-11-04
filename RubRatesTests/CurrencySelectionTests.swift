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

    }

    @Test func duplicateSavedCodesAreDropped() {
        let defaults = makeDefaults()
        defaults.set(["USD", "EUR", "USD", "EUR", "GBP"], forKey: CurrencySelection.storageKey)
        #expect(CurrencySelection(defaults: defaults).codes == ["USD", "EUR", "GBP"])
    }

    @Test func fallsBackToDefaultsWhenNoSelectedCodeIsAvailable() {
        let defaults = makeDefaults()
        defaults.set(["XXX"], forKey: CurrencySelection.storageKey)
        let snapshot = RatesSnapshot(date: .now, rates: catalog)
        let selection = CurrencySelection(defaults: defaults)
        #expect(selection.rates(in: snapshot).map(\.code) == ["USD", "CNY", "EUR"])
        // Запасной список не перезаписывает сохранённый выбор.
        #expect(selection.codes == ["XXX"])
    }

    @Test func fallsBackToFirstRateWhenDefaultsAreAlsoMissing() {
        let defaults = makeDefaults()
        defaults.set(["XXX"], forKey: CurrencySelection.storageKey)
        let snapshot = RatesSnapshot(date: .now, rates: [rate("GBP", "Фунт стерлингов")])
        #expect(CurrencySelection(defaults: defaults).rates(in: snapshot).map(\.code) == ["GBP"])
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

    // MARK: Общее хранилище и перенос

    @Test func migratesLegacyWhenSharedEmpty() {
        let shared = makeDefaults(), legacy = makeDefaults()
        legacy.set(["GBP", "USD"], forKey: CurrencySelection.storageKey)
        let selection = CurrencySelection(defaults: shared, legacyDefaults: legacy)
        #expect(selection.codes == ["GBP", "USD"])
        #expect(shared.stringArray(forKey: CurrencySelection.storageKey) == ["GBP", "USD"])
    }

    @Test func doesNotOverwriteSharedWithLegacy() {
        let shared = makeDefaults(), legacy = makeDefaults()
        shared.set(["EUR"], forKey: CurrencySelection.storageKey)
        legacy.set(["GBP", "USD"], forKey: CurrencySelection.storageKey)
        #expect(CurrencySelection(defaults: shared, legacyDefaults: legacy).codes == ["EUR"])
        #expect(shared.stringArray(forKey: CurrencySelection.storageKey) == ["EUR"])
    }

    @Test func noLegacyAndNoSharedGivesDefaults() {
        let selection = CurrencySelection(defaults: makeDefaults(), legacyDefaults: makeDefaults())
        #expect(selection.codes == CurrencySelection.defaultCodes)
    }

    @Test func legacyJunkIsIgnored() {
        let shared = makeDefaults(), legacy = makeDefaults()
        legacy.set("junk", forKey: CurrencySelection.storageKey)
        let selection = CurrencySelection(defaults: shared, legacyDefaults: legacy)
        #expect(selection.codes == CurrencySelection.defaultCodes)
        #expect(shared.object(forKey: CurrencySelection.storageKey) == nil)
    }

    @Test func savedCodesMatchesInitRules() {
        let defaults = makeDefaults()
        defaults.set(["USD", "EUR", "USD"], forKey: CurrencySelection.storageKey)
        #expect(CurrencySelection.savedCodes(in: defaults) == ["USD", "EUR"])
        defaults.set("junk", forKey: CurrencySelection.storageKey)
        #expect(CurrencySelection.savedCodes(in: defaults) == CurrencySelection.defaultCodes)
    }

    @Test func staticRatesMatchesInstanceRates() {
        let snapshot = RatesSnapshot(date: .now, rates: catalog)
        #expect(CurrencySelection.rates(in: snapshot, codes: ["GBP", "XXX", "USD"]).map(\.code) == ["GBP", "USD"])
        #expect(CurrencySelection.rates(in: snapshot, codes: ["XXX"]).map(\.code) == ["USD", "CNY", "EUR"])
    }

    @Test func onChangeFiresOnAddRemoveMove() {
        let selection = CurrencySelection(defaults: makeDefaults())
        var count = 0
        selection.onChange = { count += 1 }
        selection.add("GBP")
        selection.add("GBP")
        selection.remove("CNY")
        selection.move(from: IndexSet(integer: 0), to: 2)
        #expect(count == 3)
    }
}
