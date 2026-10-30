import Foundation
import Testing
@testable import RubRates

struct CBRHistoryClientTests {
    private var moscow: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Moscow")!
        return calendar
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        moscow.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test func parsesRecords() throws {
        let points = try CBRHistoryClient.parse(SampleHistoryResponses.usdThreeDays)
        #expect(points == [
            RatePoint(date: day(2026, 10, 16), value: 83.76),
            RatePoint(date: day(2026, 10, 17), value: 83.6177),
            RatePoint(date: day(2026, 10, 20), value: 82.8504),
        ])
    }

    @Test func dividesByNominal() throws {
        let data = SampleHistoryResponses.xml([.init(date: "16.10.2026", nominal: 100, value: "5000,00")])
        #expect(try CBRHistoryClient.parse(data).map(\.value) == [50])
    }

    @Test func acceptsDotDecimal() throws {
        let data = SampleHistoryResponses.xml([.init(date: "16.10.2026", value: "83.76")])
        #expect(try CBRHistoryClient.parse(data).map(\.value) == [83.76])
    }

    @Test func sortsByDate() throws {
        let data = SampleHistoryResponses.xml([
            .init(date: "20.10.2026", value: "82,8504"),
            .init(date: "16.10.2026", value: "83,7600"),
            .init(date: "17.10.2026", value: "83,6177"),
        ])
        let points = try CBRHistoryClient.parse(data)
        #expect(points.map(\.date) == [day(2026, 10, 16), day(2026, 10, 17), day(2026, 10, 20)])
    }

    @Test func emptyRangeGivesEmptySeries() throws {
        #expect(try CBRHistoryClient.parse(SampleHistoryResponses.xml([])) == [])
    }

    @Test func brokenXMLThrows() {
        let broken = SampleHistoryResponses.usdThreeDays.prefix(120)
        #expect(throws: (any Error).self) { try CBRHistoryClient.parse(Data(broken)) }
    }

    @Test func missingValueThrows() {
        let data = SampleHistoryResponses.xml([.init(date: "16.10.2026", value: nil)])
        #expect(throws: CBRError.invalidResponse) { try CBRHistoryClient.parse(data) }
    }

    @Test func urlFormat() {
        let url = CBRHistoryClient.makeURL(id: "R01235", from: day(2026, 10, 16), to: day(2026, 10, 30))
        #expect(url.host() == "www.cbr.ru")
        let text = url.absoluteString
        #expect(text.contains("date_req1=16/10/2026"))
        #expect(text.contains("date_req2=30/10/2026"))
        #expect(text.contains("VAL_NM_RQ=R01235"))
    }
}
