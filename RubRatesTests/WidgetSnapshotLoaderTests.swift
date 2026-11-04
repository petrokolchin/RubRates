import Foundation
import Testing
@testable import RubRates

struct WidgetSnapshotLoaderTests {
    private let now = Date(timeIntervalSince1970: 1_792_000_000)

    private func snapshot(_ value: Double) -> RatesSnapshot {
        RatesSnapshot(date: now, rates: [Rate(code: "USD", cbrID: "R01235", name: "Доллар", value: value, previous: value, nominal: 1)])
    }

    private func loader(cache: CacheStore, provider: FakeProvider) -> WidgetSnapshotLoader {
        WidgetSnapshotLoader(cache: cache, provider: provider, now: { now })
    }

    private func cached(_ value: Double, age: TimeInterval) -> MemoryCacheStore {
        let cache = MemoryCacheStore()
        cache.save(CachedRates(snapshot: snapshot(value), fetchedAt: now.addingTimeInterval(-age)), key: CacheKey.rates)
        return cache
    }

    @Test func freshCacheSkipsNetwork() async {
        let provider = FakeProvider([.success(snapshot(2))])
        let result = await loader(cache: cached(1, age: 3600), provider: provider).load()
        #expect(result == snapshot(1))
        #expect(await provider.callCount == 0)
    }

    @Test func missingCacheFetchesAndStores() async {
        let cache = MemoryCacheStore()
        let provider = FakeProvider([.success(snapshot(2))])
        let result = await loader(cache: cache, provider: provider).load()
        #expect(result == snapshot(2))
        #expect(cache.load(CachedRates.self, key: CacheKey.rates)?.snapshot == snapshot(2))
        #expect(cache.load(CachedRates.self, key: CacheKey.rates)?.fetchedAt == now)
    }

    @Test func staleCacheIsRefreshedWhenNetworkWorks() async {
        let provider = FakeProvider([.success(snapshot(2))])
        let result = await loader(cache: cached(1, age: WidgetSnapshotLoader.staleAfter + 1), provider: provider).load()
        #expect(result == snapshot(2))
    }

    @Test func staleCacheIsUsedWhenNetworkFails() async {
        let provider = FakeProvider([.failure(CBRError.badStatus(503))])
        let result = await loader(cache: cached(1, age: 3 * 86400), provider: provider).load()
        #expect(result == snapshot(1))
    }

    @Test func noCacheAndNoNetworkGivesNil() async {
        let provider = FakeProvider([.failure(CBRError.badStatus(503))])
        #expect(await loader(cache: MemoryCacheStore(), provider: provider).load() == nil)
    }
}
