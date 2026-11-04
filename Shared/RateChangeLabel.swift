import SwiftUI

/// Изменение курса за день: «▲ 0,19» зелёным, «▼ 0,19» красным, ноль серым.
/// Общая для списка курсов и виджета.
struct RateChangeLabel: View {
    let rate: Rate

    var body: some View {
        let rounded = rate.roundedChange
        if rounded == 0 {
            Text(RuFormat.number(0)).font(.subheadline).foregroundStyle(.secondary)
        } else {
            let up = rounded > 0
            Text("\(up ? "▲" : "▼") \(RuFormat.rate(abs(rounded), like: rate.value))")
                .font(.subheadline)
                .foregroundStyle(up ? .green : .red)
                .accessibilityLabel("\(up ? "Выросло" : "Снизилось") на \(RuFormat.rate(abs(rounded), like: rate.value))")
        }
    }
}
