import SwiftUI

/// Что показывать, пока курсов нет: индикатор загрузки или ошибку с кнопкой «Повторить».
struct RatesUnavailableView: View {
    let viewModel: RatesViewModel

    var body: some View {
        if viewModel.refreshFailed {
            ContentUnavailableView {
                Label("Не удалось загрузить курсы", systemImage: "wifi.slash")
            } actions: {
                Button("Повторить") { Task { await viewModel.load() } }
            }
        } else {
            ProgressView()
        }
    }
}
