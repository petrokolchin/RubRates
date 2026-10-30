import Foundation
import Testing
@testable import RubRates

/// Подменённый источник: отдаёт заданные результаты по очереди (последний повторяется).
actor FakeProvider: RatesProviding {
    private var results: [Result<RatesSnapshot, Error>]
    private let delay: Duration
    private(set) var callCount = 0

    init(_ results: [Result<RatesSnapshot, Error>], delay: Duration = .zero) {
        self.results = results
        self.delay = delay
    }

    func fetch() async throws -> RatesSnapshot {
        callCount += 1
        try await Task.sleep(for: delay)
        let result = results.count > 1 ? results.removeFirst() : results[0]
        return try result.get()
    }
}

@MainActor
struct RatesViewModelTests {
    private let snapshot = RatesSnapshot(
        date: Date(timeIntervalSince1970: 0),
        rates: [Rate(code: "USD", cbrID: "R01235", name: "Доллар США", value: 81.1255, previous: 81.9739, nominal: 1)]
    )

    @Test func successSetsSnapshot() async {
        let viewModel = RatesViewModel(provider: FakeProvider([.success(snapshot)]))
        await viewModel.load()
        #expect(viewModel.snapshot == snapshot)
        #expect(viewModel.refreshFailed == false)
        #expect(viewModel.isLoading == false)
    }

    @Test func failureWithoutDataLeavesSnapshotNil() async {
        let viewModel = RatesViewModel(provider: FakeProvider([.failure(CBRError.badStatus(503))]))
        await viewModel.load()
        #expect(viewModel.snapshot == nil)
        #expect(viewModel.refreshFailed == true)
        #expect(viewModel.isLoading == false)
    }

    @Test func failureKeepsOldSnapshot() async {
        let viewModel = RatesViewModel(provider: FakeProvider([.success(snapshot), .failure(CBRError.badStatus(503))]))
        await viewModel.load()
        await viewModel.load()
        #expect(viewModel.snapshot == snapshot)
        #expect(viewModel.refreshFailed == true)
    }

    @Test func successAfterFailureClearsFlag() async {
        let viewModel = RatesViewModel(provider: FakeProvider([.failure(CBRError.badStatus(503)), .success(snapshot)]))
        await viewModel.load()
        await viewModel.load()
        #expect(viewModel.snapshot == snapshot)
        #expect(viewModel.refreshFailed == false)
    }

    @Test func loadWhileLoadingIsIgnored() async {
        let provider = FakeProvider([.success(snapshot)], delay: .milliseconds(200))
        let viewModel = RatesViewModel(provider: provider)
        async let first: Void = viewModel.load()
        async let second: Void = viewModel.load()
        _ = await (first, second)
        #expect(await provider.callCount == 1)
    }

    // MARK: кэш

    private let fixedNow = Date(timeIntervalSince1970: 1_792_100_000)
    private let cachedAt = Date(timeIntervalSince1970: 1_792_000_000)

    private var cachedSnapshot: RatesSnapshot {
        RatesSnapshot(
            date: Date(timeIntervalSince1970: 1_791_900_000),
            rates: [Rate(code: "USD", cbrID: "R01235", name: "Доллар США", value: 70, previous: 71, nominal: 1)]
        )
    }

    private func cacheWithRates() -> MemoryCacheStore {
        let cache = MemoryCacheStore()
        cache.save(CachedRates(snapshot: cachedSnapshot, fetchedAt: cachedAt), key: CacheKey.rates)
        return cache
    }

    @Test func cachedSnapshotAvailableImmediately() {
        let viewModel = RatesViewModel(provider: FakeProvider([.success(snapshot)]), cache: cacheWithRates())
        #expect(viewModel.snapshot == cachedSnapshot)
        #expect(viewModel.lastUpdated == cachedAt)
    }

    @Test func successWritesCacheAndSetsLastUpdated() async {
        let cache = MemoryCacheStore()
        let viewModel = RatesViewModel(provider: FakeProvider([.success(snapshot)]), cache: cache, now: { fixedNow })
        await viewModel.load()
        #expect(viewModel.lastUpdated == fixedNow)
        #expect(cache.load(CachedRates.self, key: CacheKey.rates) == CachedRates(snapshot: snapshot, fetchedAt: fixedNow))
    }

    @Test func failureKeepsCachedSnapshot() async {
        let viewModel = RatesViewModel(
            provider: FakeProvider([.failure(CBRError.badStatus(503))]), cache: cacheWithRates(), now: { fixedNow })
        await viewModel.load()
        #expect(viewModel.snapshot == cachedSnapshot)
        #expect(viewModel.refreshFailed == true)
        #expect(viewModel.lastUpdated == cachedAt)
    }

    @Test func successAfterFailureWithCacheClearsFlag() async {
        let viewModel = RatesViewModel(
            provider: FakeProvider([.failure(CBRError.badStatus(503)), .success(snapshot)]),
            cache: cacheWithRates(), now: { fixedNow })
        await viewModel.load()
        await viewModel.load()
        #expect(viewModel.snapshot == snapshot)
        #expect(viewModel.refreshFailed == false)
        #expect(viewModel.lastUpdated == fixedNow)
    }

    @Test func noCacheAndFailureHasNoSnapshot() async {
        let viewModel = RatesViewModel(provider: FakeProvider([.failure(CBRError.badStatus(503))]), cache: MemoryCacheStore())
        await viewModel.load()
        #expect(viewModel.snapshot == nil)
        #expect(viewModel.refreshFailed == true)
        #expect(viewModel.lastUpdated == nil)
    }

    @Test func unwritableCacheDoesNotBreakLoad() async {
        let viewModel = RatesViewModel(provider: FakeProvider([.success(snapshot)]), cache: NullCacheStore())
        await viewModel.load()
        #expect(viewModel.snapshot == snapshot)
    }
}

/// Кэш, который ничего не сохраняет и ничего не отдаёт (как недоступная папка).
struct NullCacheStore: CacheStore {
    func load<T: Codable>(_ type: T.Type, key: String) -> T? { nil }
    func save<T: Codable>(_ value: T, key: String) {}
}
