import SwiftUI

struct ContentView: View {
    let viewModel: RatesViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Курс ЦБ РФ")
        }
        .task { await viewModel.load() }
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
        } else if viewModel.refreshFailed {
            ContentUnavailableView {
                Label("Не удалось загрузить курсы", systemImage: "wifi.slash")
            } actions: {
                Button("Повторить") { Task { await viewModel.load() } }
            }
        } else {
            ProgressView()
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
                Text(Self.format(rate.value)).font(.title3).monospacedDigit()
                changeLabel
            }
        }
    }

    @ViewBuilder
    private var changeLabel: some View {
        let rounded = (rate.change * 100).rounded() / 100
        if rounded == 0 {
            Text(Self.format(0)).font(.subheadline).foregroundStyle(.secondary)
        } else {
            let up = rounded > 0
            Text("\(up ? "▲" : "▼") \(Self.format(abs(rounded)))")
                .font(.subheadline)
                .foregroundStyle(up ? .green : .red)
                .accessibilityLabel("\(up ? "Выросло" : "Снизилось") на \(Self.format(abs(rounded)))")
        }
    }

    private static func format(_ number: Double) -> String {
        number.formatted(.number.precision(.fractionLength(2)).locale(Locale(identifier: "ru_RU")))
    }
}

private struct StaticRatesProvider: RatesProviding {
    func fetch() async throws -> RatesSnapshot {
        RatesSnapshot(date: .now, rates: [
            Rate(code: "USD", name: "Доллар США", value: 81.1255, previous: 81.9739, nominal: 1),
            Rate(code: "CNY", name: "Китайский юань", value: 12.146, previous: 12.2806, nominal: 1),
            Rate(code: "EUR", name: "Евро", value: 91.1364, previous: 91.1364, nominal: 1),
        ])
    }
}

#Preview {
    ContentView(viewModel: RatesViewModel(provider: StaticRatesProvider()))
}
