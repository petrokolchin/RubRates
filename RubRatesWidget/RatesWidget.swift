import SwiftUI
import WidgetKit

struct RatesEntry: TimelineEntry {
    let date: Date
    let snapshot: RatesSnapshot?
    let codes: [String]
}

/// Берёт курсы из общего кэша приложения (или из сети) и выбранные валюты из общих настроек.
struct RatesProvider: TimelineProvider {
    /// Как часто просить систему обновить виджет: курс ЦБ меняется раз в день.
    static let refreshInterval: TimeInterval = 3 * 3600

    func placeholder(in context: Context) -> RatesEntry { Self.sampleEntry }

    func getSnapshot(in context: Context, completion: @escaping (RatesEntry) -> Void) {
        completion(context.isPreview ? Self.sampleEntry : Self.entry(snapshot: Self.cachedSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RatesEntry>) -> Void) {
        Task {
            let loader = WidgetSnapshotLoader(cache: FileCacheStore.standard(), provider: CBRClient())
            let entry = Self.entry(snapshot: await loader.load())
            completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(Self.refreshInterval))))
        }
    }

    private static var sampleEntry: RatesEntry {
        RatesEntry(date: .now, snapshot: RatesSnapshot(date: .now, rates: SampleRates.rates), codes: CurrencySelection.defaultCodes)
    }

    private static func entry(snapshot: RatesSnapshot?) -> RatesEntry {
        RatesEntry(date: .now, snapshot: snapshot, codes: CurrencySelection.savedCodes(in: AppGroup.sharedDefaults()))
    }

    private static func cachedSnapshot() -> RatesSnapshot? {
        FileCacheStore.standard().load(CachedRates.self, key: CacheKey.rates)?.snapshot
    }
}

struct RatesWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RatesEntry

    var body: some View {
        let size: WidgetSize = family == .systemSmall ? .small : .medium
        WidgetRatesView(content: WidgetEntries.content(size: size, snapshot: entry.snapshot, codes: entry.codes), size: size)
    }
}

struct RatesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RatesWidget", provider: RatesProvider()) { entry in
            RatesWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Курсы ЦБ")
        .description("Курсы валют из списка «Мои валюты».")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
