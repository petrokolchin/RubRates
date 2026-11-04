import Foundation
import Testing
@testable import RubRates

struct AppGroupTests {
    @Test func containerIsAvailableInSimulator() {
        #expect(AppGroup.containerURL() != nil)
    }

    @Test func sharedCacheDirectoryIsInsideContainer() throws {
        let container = try #require(AppGroup.containerURL())
        let directory = try #require(AppGroup.sharedCacheDirectory())
        #expect(directory.path.hasPrefix(container.path))
        #expect(directory.lastPathComponent == "RubRatesCache")
    }

    @Test func sharedDefaultsRoundTrip() {
        let key = "AppGroupTests-\(UUID().uuidString)"
        let defaults = AppGroup.sharedDefaults()
        defaults.set("value", forKey: key)
        defer { defaults.removeObject(forKey: key) }
        #expect(AppGroup.sharedDefaults().string(forKey: key) == "value")
    }
}
