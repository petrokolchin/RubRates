import Foundation
import Testing
@testable import RubRates

struct AppLinkTests {
    @Test func widgetURLOpensRatesTab() {
        #expect(AppLink.tab(for: AppLink.ratesURL) == .rates)
    }

    @Test func unknownURLsAreIgnored() {
        #expect(AppLink.tab(for: URL(string: "https://example.com")!) == nil)
        #expect(AppLink.tab(for: URL(string: "rubrates://unknown")!) == nil)
    }
}
