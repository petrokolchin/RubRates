import SwiftUI
import WidgetKit

@main
struct RubRatesApp: App {
    @State private var viewModel: RatesViewModel
    @State private var selection: CurrencySelection
    private let history = CBRHistoryClient()
    private let cache: FileCacheStore

    init() {
        let cache = FileCacheStore.standard()
        self.cache = cache
        let selection = CurrencySelection(legacyDefaults: .standard)
        selection.onChange = { WidgetCenter.shared.reloadAllTimelines() }
        _selection = State(initialValue: selection)
        _viewModel = State(initialValue: RatesViewModel(
            provider: CBRClient(), cache: cache,
            onFreshData: { WidgetCenter.shared.reloadAllTimelines() }))
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: viewModel, history: history, cache: cache, selection: selection)
        }
    }
}
