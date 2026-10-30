import SwiftUI

@main
struct RubRatesApp: App {
    @State private var viewModel = RatesViewModel(provider: CBRClient())
    private let history = CBRHistoryClient()

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: viewModel, history: history)
        }
    }
}
