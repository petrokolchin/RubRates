import Foundation
import Observation

/// Состояние экрана: последние загруженные курсы и признаки загрузки и сбоя.
/// При создании подхватывает сохранённые курсы, чтобы приложение работало без сети.
@MainActor
@Observable
final class RatesViewModel {
    private(set) var snapshot: RatesSnapshot?
    private(set) var isLoading = false
    private(set) var refreshFailed = false
    /// Когда получен текущий снимок (из сети или из кэша).
    private(set) var lastUpdated: Date?

    private let provider: RatesProviding
    private let cache: CacheStore
    private let now: () -> Date
    /// Вызывается после успешной загрузки и сохранения в кэш (например, чтобы обновить виджет).
    private let onFreshData: () -> Void

    init(provider: RatesProviding, cache: CacheStore = MemoryCacheStore(), now: @escaping () -> Date = Date.init,
         onFreshData: @escaping () -> Void = {}) {
        self.provider = provider
        self.cache = cache
        self.now = now
        self.onFreshData = onFreshData
        if let cached = cache.load(CachedRates.self, key: CacheKey.rates) {
            snapshot = cached.snapshot
            lastUpdated = cached.fetchedAt
        }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let fresh = try await provider.fetch()
            let fetchedAt = now()
            snapshot = fresh
            lastUpdated = fetchedAt
            refreshFailed = false
            cache.save(CachedRates(snapshot: fresh, fetchedAt: fetchedAt), key: CacheKey.rates)
            onFreshData()
        } catch {
            refreshFailed = true
        }
    }
}
