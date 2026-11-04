import SwiftUI

/// Вёрстка виджета: одна валюта (small), до четырёх строк (medium) или заглушка.
/// Лежит в `Shared`, чтобы её можно было показать и проверить внутри приложения.
struct WidgetRatesView: View {
    let content: WidgetContent
    let size: WidgetSize

    var body: some View {
        switch content {
        case .noData:
            Text("Откройте приложение")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .rates(let date, let rates):
            switch size {
            case .small:
                if let rate = rates.first { small(rate) }
            case .medium:
                medium(date: date, rates: rates)
            }
        }
    }

    private func small(_ rate: Rate) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(rate.code).font(.headline)
            Text(rate.name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            Spacer(minLength: 0)
            Text(RuFormat.rate(rate.value))
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            RateChangeLabel(rate: rate)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func medium(date: Date, rates: [Rate]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("На \(date.formatted(RuFormat.dateStyle))")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(rates) { rate in
                HStack(spacing: 8) {
                    Text(rate.code).font(.headline)
                    Spacer()
                    Text(RuFormat.rate(rate.value)).font(.body).monospacedDigit()
                    RateChangeLabel(rate: rate)
                        .font(.caption)
                        .frame(minWidth: 76, alignment: .trailing)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview("Small", traits: .sizeThatFitsLayout) {
    WidgetRatesView(content: .rates(date: .now, rates: Array(SampleRates.rates.prefix(1))), size: .small)
        .padding().frame(width: 158, height: 158)
}

#Preview("Medium", traits: .sizeThatFitsLayout) {
    WidgetRatesView(content: .rates(date: .now, rates: Array(SampleRates.rates.prefix(4))), size: .medium)
        .padding().frame(width: 338, height: 158)
}

#Preview("Нет данных", traits: .sizeThatFitsLayout) {
    WidgetRatesView(content: .noData, size: .small).padding().frame(width: 158, height: 158)
}
