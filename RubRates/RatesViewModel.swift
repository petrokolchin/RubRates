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

    init(provider: RatesProviding, cache: CacheStore = MemoryCacheStore(), now: @escaping () -> Date = Date.init) {
        self.provider = provider
        self.cache = cache
        self.now = now
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
        } catch {
            refreshFailed = true
        }
    }
}
