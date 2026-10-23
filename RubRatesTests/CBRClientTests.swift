import Foundation
import Testing
@testable import RubRates

@Suite(.serialized)
struct CBRClientTests {
    @Test func parsesThreeCurrenciesInOrder() throws {
        let snapshot = try CBRClient.parse(Data(SampleResponses.daily.utf8))
        #expect(snapshot.rates.map(\.code) == ["USD", "CNY", "EUR"])
        #expect(snapshot.rates[0].value == 81.1255)
        #expect(snapshot.rates[0].previous == 81.9739)
    }

    @Test func parsesDate() throws {
        let snapshot = try CBRClient.parse(Data(SampleResponses.daily.utf8))
        let expected = ISO8601DateFormatter().date(from: "2026-10-23T11:30:00+03:00")
        #expect(snapshot.date == expected)
    }

    @Test func appliesNominal() throws {
        let snapshot = try CBRClient.parse(Data(SampleResponses.nominalTen.utf8))
        let cny = try #require(snapshot.rates.first { $0.code == "CNY" })
        #expect(abs(cny.value - 12.146) < 0.0001)
    }

    @Test func missingCurrencyThrows() {
        #expect(throws: CBRError.missingCurrency("CNY")) {
            try CBRClient.parse(Data(SampleResponses.withoutCNY.utf8))
        }
    }

    @Test func nonJSONBodyThrows() {
        #expect(throws: (any Error).self) {
            try CBRClient.parse(Data("<html>login</html>".utf8))
        }
    }

    @Test func fetchBypassesLocalCache() async throws {
        let client = CBRClient(session: StubURLProtocol.session(status: 200, body: Data(SampleResponses.daily.utf8)))
        _ = try await client.fetch()
        #expect(StubURLProtocol.lastRequest?.cachePolicy == .reloadIgnoringLocalCacheData)
    }

    @Test func badStatusThrows() async {
        let client = CBRClient(session: StubURLProtocol.session(status: 503, body: Data()))
        await #expect(throws: CBRError.badStatus(503)) {
            try await client.fetch()
        }
    }
}

/// Подменяет сеть: отдаёт заданный HTTP-статус и тело.
final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var status = 200
    nonisolated(unsafe) static var body = Data()
    nonisolated(unsafe) static var lastRequest: URLRequest?

    static func session(status: Int, body: Data) -> URLSession {
        self.status = status
        self.body = body
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
