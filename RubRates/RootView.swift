import SwiftUI

/// Корень приложения: две вкладки на общих курсах. Курсы загружаются один раз здесь.
struct RootView: View {
    let viewModel: RatesViewModel
    let history: HistoryProviding

    var body: some View {
        TabView {
            ContentView(viewModel: viewModel, history: history)
                .tabItem { Label("Курсы", systemImage: "list.bullet") }
            ConverterView(viewModel: viewModel)
                .tabItem { Label("Конвертер", systemImage: "arrow.left.arrow.right") }
        }
        .task { await viewModel.load() }
    }
}
