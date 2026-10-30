import Foundation
import Testing
@testable import RubRates

struct CacheStoreTests {
    private let rates = CachedRates(
        snapshot: RatesSnapshot(
            date: Date(timeIntervalSince1970: 1_792_000_000.5),
            rates: [
                Rate(code: "USD", cbrID: "R01235", name: "Доллар США", value: 81.1255, previous: 81.9739, nominal: 1),
                Rate(code: "CNY", cbrID: "R01375", name: "Юань", value: 12.146, previous: 12.2806, nominal: 1),
                Rate(code: "EUR", cbrID: "R01239", name: "Евро", value: 91.1364, previous: 91.1364, nominal: 1),
            ]),
        fetchedAt: Date(timeIntervalSince1970: 1_792_003_600.25))

    private let history = CachedHistory(
        points: [
            RatePoint(date: Date(timeIntervalSince1970: 1_791_000_000), value: 80.5),
            RatePoint(date: Date(timeIntervalSince1970: 1_791_086_400), value: 81.25),
            RatePoint(date: Date(timeIntervalSince1970: 1_791_172_800), value: 79.75),
        ],
        fetchedAt: Date(timeIntervalSince1970: 1_792_003_600))

    /// Временная папка, которая удаляется после теста.
    private func withTempDirectory(_ body: (URL) throws -> Void) rethrows {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RubRatesCacheTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(directory)
    }

    @Test func roundTripRates() {
        withTempDirectory { directory in
            let store = FileCacheStore(directory: directory)
            store.save(rates, key: "rates")
            #expect(store.load(CachedRates.self, key: "rates") == rates)
        }
    }

    @Test func roundTripHistory() {
        withTempDirectory { directory in
            let store = FileCacheStore(directory: directory)
            store.save(history, key: "history-R01235-30")
            #expect(store.load(CachedHistory.self, key: "history-R01235-30") == history)
        }
    }

    @Test func missingKeyGivesNil() {
        withTempDirectory { directory in
            #expect(FileCacheStore(directory: directory).load(CachedRates.self, key: "rates") == nil)
        }
    }

    @Test func corruptedFileGivesNil() throws {
        try withTempDirectory { directory in
            let store = FileCacheStore(directory: directory)
            store.save(rates, key: "rates")
            let file = directory.appending(path: "rates.json")

            try Data("{не json".utf8).write(to: file)
            #expect(store.load(CachedRates.self, key: "rates") == nil)

            store.save(rates, key: "rates")
            let whole = try Data(contentsOf: file)
            try whole.prefix(whole.count / 2).write(to: file)
            #expect(store.load(CachedRates.self, key: "rates") == nil)
        }
    }

    @Test func otherVersionGivesNil() throws {
        try withTempDirectory { directory in
            let store = FileCacheStore(directory: directory)
            store.save(rates, key: "rates")
            let file = directory.appending(path: "rates.json")
            var text = try String(contentsOf: file, encoding: .utf8)
            text = text.replacing("\"version\":\(FileCacheStore.formatVersion)", with: "\"version\":\(FileCacheStore.formatVersion + 1)")
            try Data(text.utf8).write(to: file)
            #expect(store.load(CachedRates.self, key: "rates") == nil)
        }
    }

    @Test func saveOverwrites() {
        withTempDirectory { directory in
            let store = FileCacheStore(directory: directory)
            store.save(history, key: "history")
            let newer = CachedHistory(points: [], fetchedAt: Date(timeIntervalSince1970: 1_800_000_000))
            store.save(newer, key: "history")
            #expect(store.load(CachedHistory.self, key: "history") == newer)
        }
    }

    @Test func unwritableDirectoryDoesNotThrow() throws {
        try withTempDirectory { base in
            try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
            let blocker = base.appending(path: "file")
            try Data("x".utf8).write(to: blocker)
            let store = FileCacheStore(directory: blocker.appending(path: "inner"))
            store.save(rates, key: "rates")
            #expect(store.load(CachedRates.self, key: "rates") == nil)
        }
    }

    @Test func keysAreIndependent() {
        withTempDirectory { directory in
            let store = FileCacheStore(directory: directory)
            store.save(rates, key: "rates")
            store.save(history, key: "history")
            #expect(store.load(CachedRates.self, key: "rates") == rates)
            #expect(store.load(CachedHistory.self, key: "history") == history)
        }
    }

    @Test func memoryStoreRoundTrip() {
        let store = MemoryCacheStore()
        store.save(rates, key: "rates")
        #expect(store.load(CachedRates.self, key: "rates") == rates)
        #expect(store.load(CachedRates.self, key: "other") == nil)
    }

    @Test func historyKeyFormat() {
        #expect(CacheKey.history(cbrID: "R01235", period: .month) == "history-R01235-30")
        #expect(CacheKey.rates == "rates")
    }
}
