import SwiftUI

/// Корень приложения: две вкладки на общих курсах и общем выборе валют. Курсы загружаются один раз здесь.
struct RootView: View {
    let viewModel: RatesViewModel
    let history: HistoryProviding
    let cache: CacheStore
    let selection: CurrencySelection

    @State private var tab: AppTab = .rates

    var body: some View {
        TabView(selection: $tab) {
            ContentView(viewModel: viewModel, history: history, cache: cache, selection: selection)
                .tabItem { Label("Курсы", systemImage: "list.bullet") }
                .tag(AppTab.rates)
            ConverterView(viewModel: viewModel, selection: selection)
                .tabItem { Label("Конвертер", systemImage: "arrow.left.arrow.right") }
                .tag(AppTab.converter)
        }
        .onOpenURL { url in
            if let target = AppLink.tab(for: url) { tab = target }
        }
        .task { await viewModel.load() }
    }
}
