import SwiftUI

struct ContentView: View {
    let viewModel: RatesViewModel

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
                    ForEach(snapshot.rates) { RateRow(rate: $0) }
                } header: {
                    Text("На \(snapshot.date.formatted(Self.dateStyle))")
                }
            }
            .refreshable { await viewModel.load() }
        } else {
            RatesUnavailableView(viewModel: viewModel)
        }
    }

    private static let dateStyle = Date.FormatStyle(date: .long, time: .omitted, locale: Locale(identifier: "ru_RU"))
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
    let viewModel = RatesViewModel(provider: StaticRatesProvider())
    ContentView(viewModel: viewModel)
        .task { await viewModel.load() }
}

#Preview("Нет данных, ошибка") {
    let viewModel = RatesViewModel(provider: FailingRatesProvider())
    ContentView(viewModel: viewModel)
        .task { await viewModel.load() }
}

#Preview("Есть данные, обновление не удалось") {
    let viewModel = RatesViewModel(provider: FlakyRatesProvider())
    ContentView(viewModel: viewModel)
        .task {
            await viewModel.load()
            try? await Task.sleep(for: .seconds(1))
            await viewModel.load()
        }
}
