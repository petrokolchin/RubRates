import SwiftUI

/// Редактор «Мои валюты»: порядок и состав выбранных валют и список остальных для добавления.
struct CurrencyPickerView: View {
    let rates: [Rate]
    let selection: CurrencySelection

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Мои валюты") {
                    ForEach(selection.codes, id: \.self) { code in
                        row(code: code, name: rates.first { $0.code == code }?.name ?? "нет данных")
                            .deleteDisabled(selection.codes.count == 1)
                    }
                    .onMove { selection.move(from: $0, to: $1) }
                    .onDelete { offsets in
                        for code in offsets.map({ selection.codes[$0] }) { selection.remove(code) }
                    }
                }
                Section("Все валюты") {
                    ForEach(available) { rate in
                        Button { selection.add(rate.code) } label: {
                            HStack {
                                row(code: rate.code, name: rate.name)
                                Spacer()
                                Image(systemName: "plus.circle.fill").foregroundStyle(.green)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            // Перетаскивание работает только в режиме редактирования; он здесь нужен всегда.
            .environment(\.editMode, .constant(.active))
            .searchable(text: $query, prompt: "Код или название")
            .navigationTitle("Мои валюты")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    /// Невыбранные валюты, отфильтрованные поиском. Поиск не затрагивает «Мои валюты»:
    /// иначе индексы перетаскивания не совпали бы с порядком выбора.
    private var available: [Rate] {
        CurrencySelection.search(rates.filter { !selection.codes.contains($0.code) }, query: query)
    }

    private func row(code: String, name: String) -> some View {
        VStack(alignment: .leading) {
            Text(code).font(.headline)
            Text(name).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}

#Preview("Редактор") {
    CurrencyPickerView(rates: StaticRatesProvider.sample, selection: .preview(["USD", "GBP", "XXX"]))
}
