import Testing
@testable import RumisCore

@Suite("MoneyParsing")
struct MoneyParsingTests {
    @Test("parses dot-decimal amounts")
    func parsesDotDecimal() {
        #expect(MoneyParsing.centsFromEuroString("12.34") == 1234)
        #expect(MoneyParsing.centsFromEuroString("0.5") == 50)
        #expect(MoneyParsing.centsFromEuroString("100") == 10_000)
    }

    @Test("parses comma-decimal amounts (Spanish keyboards)")
    func parsesCommaDecimal() {
        #expect(MoneyParsing.centsFromEuroString("12,34") == 1234)
        #expect(MoneyParsing.centsFromEuroString("0,5") == 50)
    }

    @Test("trims surrounding whitespace")
    func trimsWhitespace() {
        #expect(MoneyParsing.centsFromEuroString("  12,34  ") == 1234)
    }

    @Test("rejects empty, negative, and non-numeric input")
    func rejectsInvalidInput() {
        #expect(MoneyParsing.centsFromEuroString("") == nil)
        #expect(MoneyParsing.centsFromEuroString("   ") == nil)
        #expect(MoneyParsing.centsFromEuroString("-5") == nil)
        #expect(MoneyParsing.centsFromEuroString("abc") == nil)
    }

    @Test("rounds to the nearest cent instead of truncating")
    func roundsToNearestCent() {
        #expect(MoneyParsing.centsFromEuroString("1.006") == 101)
        #expect(MoneyParsing.centsFromEuroString("1.004") == 100)
    }

    @Test("formats cents back to a two-decimal euro string")
    func formatsEuroString() {
        #expect(MoneyParsing.euroString(fromCents: 1234) == "12.34")
        #expect(MoneyParsing.euroString(fromCents: 0) == "0.00")
        #expect(MoneyParsing.euroString(fromCents: 5) == "0.05")
    }

    @Test("round-trips through parse and format")
    func roundTrips() {
        let cents = 4250
        let text = MoneyParsing.euroString(fromCents: cents)
        #expect(MoneyParsing.centsFromEuroString(text) == cents)
    }
}
