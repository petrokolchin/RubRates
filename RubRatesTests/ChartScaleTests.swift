import Testing
@testable import RubRates

struct ChartScaleTests {
    @Test func tinyRatesStayPositiveAndVisible() {
        // Донг: курс за единицу около 0,0034 ₽; запас в 0,5 ₽ давал ось с минусом и плоскую линию.
        let domain = ChartScale.yDomain(low: 0.0031, high: 0.0035)
        #expect(domain.lowerBound > 0)
        #expect(domain.lowerBound < 0.0031)
        #expect(domain.upperBound > 0.0035)
        #expect(domain.upperBound - domain.lowerBound < 0.002)
    }

    @Test func smallRateKeepsItsRange() {
        // Иена: около 0,53 ₽.
        let domain = ChartScale.yDomain(low: 0.51, high: 0.54)
        #expect(domain.lowerBound > 0.4)
        #expect(domain.upperBound < 0.65)
    }

    @Test func flatSeriesGetsNonZeroHeight() {
        let tiny = ChartScale.yDomain(low: 0.0034, high: 0.0034)
        #expect(tiny.upperBound > tiny.lowerBound)
        #expect(tiny.lowerBound > 0)
        let usd = ChartScale.yDomain(low: 80, high: 80)
        #expect(usd.lowerBound > 79)
        #expect(usd.upperBound < 81)
    }

    @Test func ordinaryRangeGetsTenPercentPadding() {
        let domain = ChartScale.yDomain(low: 70, high: 90)
        #expect(domain.lowerBound == 68)
        #expect(domain.upperBound == 92)
    }

    @Test func allZeroSeriesDoesNotCollapse() {
        let domain = ChartScale.yDomain(low: 0, high: 0)
        #expect(domain.upperBound > domain.lowerBound)
    }
}
