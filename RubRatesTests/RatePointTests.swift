import Foundation
import Testing
@testable import RubRates

struct RatePointTests {
    private func points(_ values: [Double]) -> [RatePoint] {
        values.enumerated().map { RatePoint(date: Date(timeIntervalSince1970: Double($0.offset) * 86_400), value: $0.element) }
    }

    @Test func changeRise() {
        #expect(PeriodChange.make(from: points([80, 84])) == PeriodChange(absolute: 4, percent: 5))
    }

    @Test func changeFall() {
        #expect(PeriodChange.make(from: points([80, 76])) == PeriodChange(absolute: -4, percent: -5))
    }

    @Test func changeZero() {
        #expect(PeriodChange.make(from: points([80, 80])) == PeriodChange(absolute: 0, percent: 0))
    }

    @Test func changeNeedsTwoPoints() {
        #expect(PeriodChange.make(from: []) == nil)
        #expect(PeriodChange.make(from: points([80])) == nil)
    }

    @Test func changeIgnoresMiddle() {
        #expect(PeriodChange.make(from: points([80, 200, 84]))?.absolute == 4)
    }

    @Test func changeNilWhenFirstIsZero() {
        #expect(PeriodChange.make(from: points([0, 5])) == nil)
    }
}
