import SwiftUI

@main
struct RubRatesApp: App {
    @State private var viewModel: RatesViewModel
    @State private var selection = CurrencySelection()
    private let history = CBRHistoryClient()
    private let cache: FileCacheStore

    init() {
        let cache = FileCacheStore.standard()
        self.cache = cache
        _viewModel = State(initialValue: RatesViewModel(provider: CBRClient(), cache: cache))
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: viewModel, history: history, cache: cache, selection: selection)
        }
    }
}
