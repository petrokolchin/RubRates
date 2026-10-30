import SwiftUI

/// Корень приложения: две вкладки на общих курсах. Курсы загружаются один раз здесь.
struct RootView: View {
    let viewModel: RatesViewModel
    let history: HistoryProviding
    let cache: CacheStore

    var body: some View {
        TabView {
            ContentView(viewModel: viewModel, history: history, cache: cache)
                .tabItem { Label("Курсы", systemImage: "list.bullet") }
            ConverterView(viewModel: viewModel)
                .tabItem { Label("Конвертер", systemImage: "arrow.left.arrow.right") }
        }
        .task { await viewModel.load() }
    }
}
