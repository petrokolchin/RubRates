import SwiftUI

/// Конвертер: сумма в одной валюте и её эквиваленты во всех остальных.
struct ConverterView: View {
    let viewModel: RatesViewModel

    @State private var text = ""
    @State private var source: Currency = .rub
    @FocusState private var amountFocused: Bool

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Конвертер")
        }
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = viewModel.snapshot {
            List {
                Section {
                    TextField("Сумма", text: $text)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                        .focused($amountFocused)
                    Picker("Валюта", selection: $source) {
                        Text("₽").tag(Currency.rub)
                        ForEach(snapshot.rates) { Text($0.code).tag(Currency.foreign($0.code)) }
                    }
                    .pickerStyle(.segmented)
                }
                if let amount = CurrencyConverter.parse(text) {
                    Section {
                        ForEach(CurrencyConverter.convert(amount, from: source, using: snapshot.rates)) { item in
                            HStack {
                                Text(item.currency.code).font(.headline)
                                Spacer()
                                Text(RuFormat.number(item.amount)).font(.title3).monospacedDigit()
                            }
                        }
                    } footer: {
                        Text("По курсу ЦБ на \(snapshot.date.formatted(RuFormat.dateStyle))\(viewModel.refreshFailed ? ", офлайн" : "")")
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollBounceBehavior(.always)
            // У цифровой клавиатуры нет Return, а клавиатура закрывает панель вкладок.
            // Кнопка входит в раскладку экрана и поднимается над клавиатурой вместе с её safe area.
            .safeAreaInset(edge: .bottom) {
                if amountFocused {
                    Button("Готово") { amountFocused = false }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }
            }
        } else {
            RatesUnavailableView(viewModel: viewModel)
        }
    }
}

#Preview("Конвертер") {
    let viewModel = RatesViewModel(provider: StaticRatesProvider())
    ConverterView(viewModel: viewModel)
        .task { await viewModel.load() }
}

#Preview("Конвертер, ошибка") {
    let viewModel = RatesViewModel(provider: FailingRatesProvider())
    ConverterView(viewModel: viewModel)
        .task { await viewModel.load() }
}
