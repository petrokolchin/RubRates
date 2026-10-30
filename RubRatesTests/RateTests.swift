import Testing
@testable import RubRates

struct RateTests {
    @Test func perUnitValueForNominalOne() {
        let rate = Rate(code: "USD", cbrID: "R01235", name: "Доллар США", value: 81.1255, previous: 81.9739, nominal: 1)
        #expect(rate.value == 81.1255)
        #expect(rate.previous == 81.9739)
    }

    @Test func perUnitValueDividesByNominal() {
        let rate = Rate(code: "JPY", cbrID: "R0", name: "Иена", value: 50, previous: 40, nominal: 10)
        #expect(rate.value == 5)
        #expect(rate.previous == 4)
        #expect(rate.change == 1)
    }

    @Test func changeIsNegativeWhenRateFell() {
        let rate = Rate(code: "USD", cbrID: "R01235", name: "Доллар США", value: 81.1255, previous: 81.9739, nominal: 1)
        #expect(abs(rate.change - (-0.8484)) < 0.0001)
    }

    @Test func changeIsZeroWhenUnchanged() {
        let rate = Rate(code: "EUR", cbrID: "R01239", name: "Евро", value: 91.1364, previous: 91.1364, nominal: 1)
        #expect(rate.change == 0)
    }

    @Test func roundedChangeIsZeroWhenChangeIsBelowOneKopeck() {
        let rate = Rate(code: "USD", cbrID: "R01235", name: "Доллар США", value: 81.1255, previous: 81.1215, nominal: 1)
        #expect(rate.roundedChange == 0)
    }

    @Test func roundedChangeKeepsTwoDecimals() {
        let rate = Rate(code: "USD", cbrID: "R01235", name: "Доллар США", value: 81.1255, previous: 81.9739, nominal: 1)
        #expect(rate.roundedChange == -0.85)
    }
}
