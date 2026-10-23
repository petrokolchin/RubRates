import SwiftUI

@main
struct RubRatesApp: App {
    @State private var viewModel = RatesViewModel(provider: CBRClient())

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .task { await viewModel.load() }
        }
    }
}
