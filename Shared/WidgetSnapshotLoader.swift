import Foundation

/// Откуда виджет берёт курсы: общий кэш приложения, а если его нет или он старый, сеть.
nonisolated struct WidgetSnapshotLoader: Sendable {
    /// Кэш старше этого возраста виджет пробует обновить, а при сбое всё равно показывает.
    static let staleAfter: TimeInterval = 6 * 3600

    let cache: CacheStore
    let provider: RatesProviding
    let now: @Sendable () -> Date

    init(cache: CacheStore, provider: RatesProviding, now: @escaping @Sendable () -> Date = Date.init) {
        self.cache = cache
        self.provider = provider
        self.now = now
    }

    func load() async -> RatesSnapshot? {
        let cached = cache.load(CachedRates.self, key: CacheKey.rates)
        if let cached, now().timeIntervalSince(cached.fetchedAt) <= Self.staleAfter {
            return cached.snapshot
        }
        do {
            let fresh = try await provider.fetch()
            cache.save(CachedRates(snapshot: fresh, fetchedAt: now()), key: CacheKey.rates)
            return fresh
        } catch {
            return cached?.snapshot
        }
    }
}
