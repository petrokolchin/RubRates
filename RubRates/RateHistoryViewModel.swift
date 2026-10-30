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

    private let cbrID: String
    private let endDate: Date
    private let provider: HistoryProviding

    init(cbrID: String, endDate: Date, provider: HistoryProviding) {
        self.cbrID = cbrID
        self.endDate = endDate
        self.provider = provider
    }

    /// Изменение за период; есть только у загруженного ряда из двух и более точек.
    var change: PeriodChange? {
        guard case .loaded(let points) = state else { return nil }
        return PeriodChange.make(from: points)
    }

    /// Загружает ряд за текущий период. Если за время ожидания период сменили
    /// (или задачу отменили), результат устарел и состояние не меняется.
    func load() async {
        let requested = period
        state = .loading
        do {
            let points = try await provider.fetch(id: cbrID, from: requested.start(endingAt: endDate), to: endDate)
            guard requested == period, !Task.isCancelled else { return }
            state = .loaded(points)
        } catch {
            guard requested == period, !Task.isCancelled, !(error is CancellationError) else { return }
            state = .failed
        }
    }
}
