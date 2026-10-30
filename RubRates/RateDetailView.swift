import Charts
import SwiftUI

/// Экран валюты: текущий курс и график динамики за выбранный период.
struct RateDetailView: View {
    let rate: Rate

    @State private var viewModel: RateHistoryViewModel
    @State private var selectedDate: Date?

    init(rate: Rate, endDate: Date, provider: HistoryProviding, cache: CacheStore) {
        self.rate = rate
        _viewModel = State(initialValue: RateHistoryViewModel(cbrID: rate.cbrID, endDate: endDate, provider: provider, cache: cache))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                Picker("Период", selection: $viewModel.period) {
                    ForEach(HistoryPeriod.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                chartArea
                offlineNote
                changeLabel
            }
            .padding()
        }
        .navigationTitle(rate.code)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: viewModel.period) {
            selectedDate = nil
            await viewModel.load()
        }
    }

    private var header: some View {
        VStack(alignment: .leading) {
            Text(rate.name).font(.subheadline).foregroundStyle(.secondary)
            Text("\(RuFormat.rate(rate.value)) ₽").font(.largeTitle).bold().monospacedDigit()
        }
    }

    @ViewBuilder
    private var chartArea: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 240)
        case .failed:
            ContentUnavailableView {
                Label("Не удалось загрузить историю", systemImage: "wifi.slash")
            } actions: {
                Button("Повторить") { Task { await viewModel.load() } }
            }
            .frame(minHeight: 240)
        case .loaded(let points) where points.count < 2:
            ContentUnavailableView("Недостаточно данных за период", systemImage: "chart.line.flattrend.xyaxis")
                .frame(minHeight: 240)
        case .loaded(let points):
            chart(points)
        }
    }

    private func chart(_ points: [RatePoint]) -> some View {
        let values = points.map(\.value)
        let low = values.min()!, high = values.max()!
        // Ось Y по диапазону данных, а не от нуля, иначе линия выглядит плоской.
        let pad = max((high - low) * 0.1, 0.5)
        let selected = selectedPoint(in: points)
        return Chart {
            ForEach(points) { point in
                LineMark(x: .value("Дата", point.date), y: .value("Курс", point.value))
                    .interpolationMethod(.monotone)
            }
            if let selected {
                RuleMark(x: .value("Дата", selected.date))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        VStack(alignment: .leading) {
                            Text(selected.date.formatted(RuFormat.dateStyle)).font(.caption2).foregroundStyle(.secondary)
                            Text("\(RuFormat.rate(selected.value)) ₽").font(.caption).bold().monospacedDigit()
                        }
                        .padding(6)
                        .background(.background.secondary, in: .rect(cornerRadius: 8))
                    }
                PointMark(x: .value("Дата", selected.date), y: .value("Курс", selected.value))
            }
        }
        .chartYScale(domain: (low - pad)...(high + pad))
        .chartXSelection(value: $selectedDate)
        // Подписи оси дат (месяцы) по-русски, как и остальной интерфейс.
        .environment(\.locale, Locale(identifier: "ru_RU"))
        .frame(height: 240)
    }

    /// Точка ряда, ближайшая к пальцу.
    private func selectedPoint(in points: [RatePoint]) -> RatePoint? {
        guard let selectedDate else { return nil }
        return points.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }

    /// Подпись под графиком, когда показан сохранённый ряд, а обновить его не удалось.
    @ViewBuilder
    private var offlineNote: some View {
        if let cachedAt = viewModel.cachedAt {
            Text("Нет связи, показаны сохранённые данные от \(RuFormat.updatedAt(cachedAt))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var changeLabel: some View {
        if let change = viewModel.change {
            let color: Color = change.absolute > 0 ? .green : (change.absolute < 0 ? .red : .secondary)
            VStack(alignment: .leading) {
                Text("Изменение за период").font(.caption).foregroundStyle(.secondary)
                Text("\(RuFormat.signedRate(change.absolute, like: rate.value)) ₽ (\(RuFormat.signedPercent(change.percent)))")
                    .font(.title3).monospacedDigit().foregroundStyle(color)
            }
        }
    }
}

#Preview("График") {
    NavigationStack {
        RateDetailView(
            rate: Rate(code: "USD", cbrID: "R01235", name: "Доллар США", value: 81.1255, previous: 81.9739, nominal: 1),
            endDate: .now, provider: StaticHistoryProvider(), cache: MemoryCacheStore())
    }
}

#Preview("Ошибка") {
    NavigationStack {
        RateDetailView(
            rate: Rate(code: "USD", cbrID: "R01235", name: "Доллар США", value: 81.1255, previous: 81.9739, nominal: 1),
            endDate: .now, provider: FailingHistoryProvider(), cache: MemoryCacheStore())
    }
}
