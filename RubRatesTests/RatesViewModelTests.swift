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
        rates: [Rate(code: "USD", name: "Доллар США", value: 81.1255, previous: 81.9739, nominal: 1)]
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
}
