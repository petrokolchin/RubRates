import SwiftUI

struct ContentView: View {
    let viewModel: RatesViewModel
    let history: HistoryProviding

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Курс ЦБ РФ")
        }
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = viewModel.snapshot {
            List {
                if viewModel.refreshFailed {
                    Label("Не удалось обновить", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
                Section {
                    ForEach(snapshot.rates) { rate in
                        NavigationLink {
                            RateDetailView(rate: rate, endDate: snapshot.date, provider: history)
                        } label: {
                            RateRow(rate: rate)
                        }
                    }
                } header: {
                    Text("На \(snapshot.date.formatted(RuFormat.dateStyle))")
                }
            }
            .refreshable { await viewModel.load() }
        } else {
            RatesUnavailableView(viewModel: viewModel)
        }
    }
}

private struct RateRow: View {
    let rate: Rate

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(rate.code).font(.headline)
                Text(rate.name).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(RuFormat.number(rate.value)).font(.title3).monospacedDigit()
                changeLabel
            }
        }
    }

    @ViewBuilder
    private var changeLabel: some View {
        let rounded = rate.roundedChange
        if rounded == 0 {
            Text(RuFormat.number(0)).font(.subheadline).foregroundStyle(.secondary)
        } else {
            let up = rounded > 0
            Text("\(up ? "▲" : "▼") \(RuFormat.number(abs(rounded)))")
                .font(.subheadline)
                .foregroundStyle(up ? .green : .red)
                .accessibilityLabel("\(up ? "Выросло" : "Снизилось") на \(RuFormat.number(abs(rounded)))")
        }
    }
}

#Preview("Курсы") {
    RootView(viewModel: RatesViewModel(provider: StaticRatesProvider()), history: StaticHistoryProvider())
}

#Preview("Нет данных, ошибка") {
    RootView(viewModel: RatesViewModel(provider: FailingRatesProvider()), history: StaticHistoryProvider())
}

#Preview("Есть данные, обновление не удалось") {
    let viewModel = RatesViewModel(provider: FlakyRatesProvider())
    RootView(viewModel: viewModel, history: StaticHistoryProvider())
        .task {
            try? await Task.sleep(for: .seconds(1))
            await viewModel.load()
        }
}
