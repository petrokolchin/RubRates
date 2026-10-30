import Foundation
import Testing
@testable import RubRates

/// Подменённый источник истории: ответы по очереди (последний повторяется), у каждого своя задержка.
actor FakeHistoryProvider: HistoryProviding {
    struct Call: Equatable {
        let id: String
        let from: Date
        let to: Date
    }

    private var steps: [(delay: Duration, result: Result<[RatePoint], Error>)]
    private(set) var calls: [Call] = []

    init(_ steps: [(delay: Duration, result: Result<[RatePoint], Error>)]) {
        self.steps = steps
    }

    init(_ results: [Result<[RatePoint], Error>]) {
        self.init(results.map { (.zero, $0) })
    }

    func fetch(id: String, from: Date, to: Date) async throws -> [RatePoint] {
        calls.append(Call(id: id, from: from, to: to))
        let step = steps.count > 1 ? steps.removeFirst() : steps[0]
        try await Task.sleep(for: step.delay)
        return try step.result.get()
    }
}

@MainActor
struct RateHistoryViewModelTests {
    private let end = Date(timeIntervalSince1970: 1_792_000_000)

    private func points(_ values: [Double]) -> [RatePoint] {
        values.enumerated().map { RatePoint(date: Date(timeIntervalSince1970: Double($0.offset) * 86_400), value: $0.element) }
    }

    private func makeViewModel(_ provider: FakeHistoryProvider) -> RateHistoryViewModel {
        RateHistoryViewModel(cbrID: "R01235", endDate: end, provider: provider)
    }

    @Test func successLoadsPoints() async {
        let series = points([80, 84])
        let viewModel = makeViewModel(FakeHistoryProvider([.success(series)]))
        await viewModel.load()
        #expect(viewModel.state == .loaded(series))
        #expect(viewModel.change == PeriodChange(absolute: 4, percent: 5))
    }

    @Test func failureSetsFailed() async {
        let viewModel = makeViewModel(FakeHistoryProvider([.failure(CBRError.badStatus(503))]))
        await viewModel.load()
        #expect(viewModel.state == .failed)
        #expect(viewModel.change == nil)
    }

    @Test func retryAfterFailure() async {
        let series = points([80, 84])
        let viewModel = makeViewModel(FakeHistoryProvider([.failure(CBRError.badStatus(503)), .success(series)]))
        await viewModel.load()
        await viewModel.load()
        #expect(viewModel.state == .loaded(series))
    }

    @Test func loadUsesPeriodRange() async {
        let provider = FakeHistoryProvider([.success(points([80, 84]))])
        let viewModel = makeViewModel(provider)
        viewModel.period = .week
        await viewModel.load()
        #expect(await provider.calls == [
            .init(id: "R01235", from: HistoryPeriod.week.start(endingAt: end), to: end),
        ])
    }

    @Test func staleResultDoesNotOverwrite() async throws {
        let weekSeries = points([1, 2])
        let yearSeries = points([80, 90, 100])
        let provider = FakeHistoryProvider([
            (delay: .milliseconds(300), result: .success(weekSeries)),
            (delay: .zero, result: .success(yearSeries)),
        ])
        let viewModel = makeViewModel(provider)
        viewModel.period = .week
        let slow = Task { await viewModel.load() }
        try await Task.sleep(for: .milliseconds(50))
        viewModel.period = .year
        await viewModel.load()
        await slow.value
        #expect(viewModel.state == .loaded(yearSeries))
    }

    @Test func singlePointHasNoChange() async {
        let series = points([80])
        let viewModel = makeViewModel(FakeHistoryProvider([.success(series)]))
        await viewModel.load()
        #expect(viewModel.state == .loaded(series))
        #expect(viewModel.change == nil)
    }

    // MARK: кэш

    private let fixedNow = Date(timeIntervalSince1970: 1_792_100_000)
    private let cachedFetchedAt = Date(timeIntervalSince1970: 1_792_000_000)

    private func makeViewModel(_ provider: FakeHistoryProvider, cache: CacheStore) -> RateHistoryViewModel {
        RateHistoryViewModel(cbrID: "R01235", endDate: end, provider: provider, cache: cache, now: { fixedNow })
    }

    private func cacheWith(_ series: [RatePoint], period: HistoryPeriod = .month) -> MemoryCacheStore {
        let cache = MemoryCacheStore()
        cache.save(CachedHistory(points: series, fetchedAt: cachedFetchedAt), key: CacheKey.history(cbrID: "R01235", period: period))
        return cache
    }

    @Test func cachedSeriesShownBeforeNetwork() async throws {
        let cached = points([70, 71])
        let provider = FakeHistoryProvider([(delay: .milliseconds(300), result: .success(points([80, 84])))])
        let viewModel = makeViewModel(provider, cache: cacheWith(cached))
        let loading = Task { await viewModel.load() }
        try await Task.sleep(for: .milliseconds(50))
        #expect(viewModel.state == .loaded(cached))
        await loading.value
    }

    @Test func successReplacesAndWritesCache() async {
        let fresh = points([80, 84])
        let cache = cacheWith(points([70, 71]))
        let viewModel = makeViewModel(FakeHistoryProvider([.success(fresh)]), cache: cache)
        await viewModel.load()
        #expect(viewModel.state == .loaded(fresh))
        #expect(viewModel.cachedAt == nil)
        let stored = cache.load(CachedHistory.self, key: CacheKey.history(cbrID: "R01235", period: .month))
        #expect(stored == CachedHistory(points: fresh, fetchedAt: fixedNow))
    }

    @Test func failureWithCacheKeepsSeries() async {
        let cached = points([70, 71])
        let viewModel = makeViewModel(
            FakeHistoryProvider([.failure(CBRError.badStatus(503))]), cache: cacheWith(cached))
        await viewModel.load()
        #expect(viewModel.state == .loaded(cached))
        #expect(viewModel.cachedAt == cachedFetchedAt)
    }

    @Test func failureWithoutCacheFails() async {
        let viewModel = makeViewModel(
            FakeHistoryProvider([.failure(CBRError.badStatus(503))]), cache: MemoryCacheStore())
        await viewModel.load()
        #expect(viewModel.state == .failed)
        #expect(viewModel.cachedAt == nil)
    }

    @Test func freshSuccessClearsOfflineNote() async {
        let fresh = points([80, 84])
        let viewModel = makeViewModel(
            FakeHistoryProvider([.failure(CBRError.badStatus(503)), .success(fresh)]),
            cache: cacheWith(points([70, 71])))
        await viewModel.load()
        #expect(viewModel.cachedAt == cachedFetchedAt)
        await viewModel.load()
        #expect(viewModel.state == .loaded(fresh))
        #expect(viewModel.cachedAt == nil)
    }

    @Test func differentPeriodsUseDifferentKeys() async {
        let cache = MemoryCacheStore()
        let viewModel = makeViewModel(FakeHistoryProvider([.success(points([80, 84]))]), cache: cache)
        viewModel.period = .week
        await viewModel.load()
        viewModel.period = .year
        await viewModel.load()
        #expect(cache.load(CachedHistory.self, key: CacheKey.history(cbrID: "R01235", period: .week)) != nil)
        #expect(cache.load(CachedHistory.self, key: CacheKey.history(cbrID: "R01235", period: .year)) != nil)
        #expect(cache.load(CachedHistory.self, key: CacheKey.history(cbrID: "R01235", period: .month)) == nil)
    }

    @Test func reloadSamePeriodIsSilent() async throws {
        let first = points([80, 84])
        let provider = FakeHistoryProvider([
            (delay: .zero, result: .success(first)),
            (delay: .milliseconds(300), result: .success(points([81, 85]))),
        ])
        let viewModel = makeViewModel(provider, cache: NullCacheStore())
        await viewModel.load()
        let reload = Task { await viewModel.load() }
        try await Task.sleep(for: .milliseconds(50))
        #expect(viewModel.state == .loaded(first))
        await reload.value
    }

    @Test func periodChangeWithoutCacheShowsLoading() async throws {
        let provider = FakeHistoryProvider([
            (delay: .zero, result: .success(points([80, 84]))),
            (delay: .milliseconds(300), result: .success(points([81, 85]))),
        ])
        let viewModel = makeViewModel(provider, cache: MemoryCacheStore())
        await viewModel.load()
        viewModel.period = .week
        let reload = Task { await viewModel.load() }
        try await Task.sleep(for: .milliseconds(50))
        #expect(viewModel.state == .loading)
        await reload.value
    }
}
