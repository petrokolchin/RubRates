import Foundation
import Observation

/// Состояние экрана: последние загруженные курсы и признаки загрузки и сбоя.
@MainActor
@Observable
final class RatesViewModel {
    private(set) var snapshot: RatesSnapshot?
    private(set) var isLoading = false
    private(set) var refreshFailed = false

    private let provider: RatesProviding

    init(provider: RatesProviding) {
        self.provider = provider
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            snapshot = try await provider.fetch()
            refreshFailed = false
        } catch {
            refreshFailed = true
        }
    }
}
