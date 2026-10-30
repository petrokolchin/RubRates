import SwiftUI

/// Корень приложения: две вкладки на общих курсах и общем выборе валют. Курсы загружаются один раз здесь.
struct RootView: View {
    let viewModel: RatesViewModel
    let history: HistoryProviding
    let cache: CacheStore
    let selection: CurrencySelection

    var body: some View {
        TabView {
            ContentView(viewModel: viewModel, history: history, cache: cache, selection: selection)
                .tabItem { Label("Курсы", systemImage: "list.bullet") }
            ConverterView(viewModel: viewModel, selection: selection)
                .tabItem { Label("Конвертер", systemImage: "arrow.left.arrow.right") }
        }
        .task { await viewModel.load() }
    }
}
