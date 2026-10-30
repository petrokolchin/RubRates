import Foundation

/// Хранилище кэша «по ключу». Кэш необязательный: любая ошибка считается «кэша нет»,
/// поэтому методы ничего не бросают.
nonisolated protocol CacheStore: Sendable {
    func load<T: Codable>(_ type: T.Type, key: String) -> T?
    func save<T: Codable>(_ value: T, key: String)
}

/// Курсы и время их получения.
nonisolated struct CachedRates: Codable, Equatable {
    let snapshot: RatesSnapshot
    let fetchedAt: Date
}

/// Ряд истории за один период и время его получения.
nonisolated struct CachedHistory: Codable, Equatable {
    let points: [RatePoint]
    let fetchedAt: Date
}

nonisolated enum CacheKey {
    static let rates = "rates"

    static func history(cbrID: String, period: HistoryPeriod) -> String {
        "history-\(cbrID)-\(period.rawValue)"
    }
}

/// Значение вместе с версией формата: файл другой версии не читается.
private nonisolated struct Envelope<Value: Codable>: Codable {
    let version: Int
    let value: Value
}

/// Кэш в JSON-файлах: по файлу `<ключ>.json` в папке `directory`.
nonisolated struct FileCacheStore: CacheStore {
    static let formatVersion = 1

    let directory: URL

    init(directory: URL) {
        self.directory = directory
    }

    /// Папка `Caches/RubRatesCache` приложения: систему не пугает её очистка, данные восстановимы.
    static func standard() -> FileCacheStore {
        FileCacheStore(directory: URL.cachesDirectory.appending(path: "RubRatesCache"))
    }

    func load<T: Codable>(_ type: T.Type, key: String) -> T? {
        guard let data = try? Data(contentsOf: file(for: key)),
              let envelope = try? JSONDecoder().decode(Envelope<T>.self, from: data),
              envelope.version == Self.formatVersion
        else { return nil }
        return envelope.value
    }

    func save<T: Codable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(Envelope(version: Self.formatVersion, value: value)) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: file(for: key), options: .atomic)
    }

    private func file(for key: String) -> URL {
        directory.appending(path: "\(key).json")
    }
}

/// Кэш в памяти для тестов и превью. Хранит закодированный JSON, как и файловый.
nonisolated final class MemoryCacheStore: CacheStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Data] = [:]

    init() {}

    func load<T: Codable>(_ type: T.Type, key: String) -> T? {
        lock.withLock { storage[key] }.flatMap { try? JSONDecoder().decode(Envelope<T>.self, from: $0).value }
    }

    func save<T: Codable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(Envelope(version: FileCacheStore.formatVersion, value: value)) else { return }
        lock.withLock { storage[key] = data }
    }
}
