import Foundation
import Observation

/// Состояние экрана истории: выбранный период и загруженный ряд курса.
@MainActor
@Observable
final class RateHistoryViewModel {
    enum State: Equatable {
        case loading
        case loaded([RatePoint])
        case failed
    }

    var period: HistoryPeriod = .month
    private(set) var state: State = .loading
    /// Время получения показанного ряда, если обновить его не удалось (офлайн); иначе `nil`.
    private(set) var cachedAt: Date?

    private let cbrID: String
    private let endDate: Date
    private let provider: HistoryProviding
    private let cache: CacheStore
    private let now: () -> Date

    /// За какой период и когда получен ряд, который сейчас на экране.
    private var shownPeriod: HistoryPeriod?
    private var shownFetchedAt: Date?

    init(cbrID: String, endDate: Date, provider: HistoryProviding,
         cache: CacheStore = MemoryCacheStore(), now: @escaping () -> Date = Date.init) {
        self.cbrID = cbrID
        self.endDate = endDate
        self.provider = provider
        self.cache = cache
        self.now = now
    }

    /// Изменение за период; есть только у загруженного ряда из двух и более точек.
    var change: PeriodChange? {
        guard case .loaded(let points) = state else { return nil }
        return PeriodChange.make(from: points)
    }

    /// Загружает ряд за текущий период. Сохранённый ряд показывается сразу, обновление идёт в фоне;
    /// если ряд за этот период уже на экране, индикатор загрузки не включается.
    /// Если за время ожидания период сменили (или задачу отменили), результат устарел
    /// и состояние не меняется.
    func load() async {
        let requested = period
        let key = CacheKey.history(cbrID: cbrID, period: requested)
        if let cached = cache.load(CachedHistory.self, key: key) {
            state = .loaded(cached.points)
            shownPeriod = requested
            shownFetchedAt = cached.fetchedAt
            cachedAt = nil
        } else if shownPeriod != requested {
            state = .loading
            shownPeriod = nil
            shownFetchedAt = nil
            cachedAt = nil
        }
        do {
            let points = try await provider.fetch(id: cbrID, from: requested.start(endingAt: endDate), to: endDate)
            guard requested == period, !Task.isCancelled else { return }
            let fetchedAt = now()
            state = .loaded(points)
            shownPeriod = requested
            shownFetchedAt = fetchedAt
            cachedAt = nil
            cache.save(CachedHistory(points: points, fetchedAt: fetchedAt), key: key)
        } catch {
            guard requested == period, !Task.isCancelled, !(error is CancellationError) else { return }
            if shownPeriod == requested, case .loaded = state {
                cachedAt = shownFetchedAt
            } else {
                state = .failed
                cachedAt = nil
            }
        }
    }
}
