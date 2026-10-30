import Foundation
import Testing
@testable import RubRates

struct HistoryPeriodTests {
    private var moscow: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Moscow")!
        return calendar
    }

    @Test func rawValues() {
        #expect(HistoryPeriod.allCases.map(\.rawValue) == [7, 30, 90, 365])
    }

    @Test func titles() {
        #expect(HistoryPeriod.allCases.map(\.title) == ["7 дн", "30 дн", "90 дн", "Год"])
    }

    @Test func startSubtractsDays() {
        let end = moscow.date(from: DateComponents(year: 2026, month: 10, day: 30, hour: 12))!
        #expect(HistoryPeriod.week.start(endingAt: end) == moscow.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: 12)))
        #expect(HistoryPeriod.month.start(endingAt: end) == moscow.date(from: DateComponents(year: 2026, month: 9, day: 30, hour: 12)))
    }
}
