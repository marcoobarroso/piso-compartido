import Testing
@testable import RumisCore
import Foundation

@Suite("Format")
struct FormatTests {
    @Test("formats cents as euros with two decimals")
    func formatsCents() {
        let formatted = Format.formatCents(123_456)
        #expect(formatted.contains("1234,56"))
        #expect(formatted.contains("€"))
    }

    @Test("formats zero and negative amounts")
    func formatsZeroAndNegative() {
        #expect(Format.formatCents(0).contains("0,00"))
        #expect(Format.formatCents(-500).contains("5,00"))
        #expect(Format.formatCents(-500).contains("-"))
    }

    @Test("parses a YYYY-MM-DD string into the matching local date")
    func parsesDateOnly() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = Format.parseDateOnly("2026-03-15", calendar: calendar)
        let components = calendar.dateComponents([.year, .month, .day], from: try #require(date))
        #expect(components.year == 2026)
        #expect(components.month == 3)
        #expect(components.day == 15)
    }

    @Test("returns nil for malformed date strings")
    func rejectsMalformedDates() {
        #expect(Format.parseDateOnly("not-a-date") == nil)
        #expect(Format.parseDateOnly("2026-03") == nil)
        #expect(Format.parseDateOnly("") == nil)
    }

    @Test("isOverdue is true only for dates strictly before today")
    func isOverdue() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15, hour: 12))!
        #expect(Format.isOverdue("2026-03-14", calendar: calendar, now: now) == true)
        #expect(Format.isOverdue("2026-03-15", calendar: calendar, now: now) == false)
        #expect(Format.isOverdue("2026-03-16", calendar: calendar, now: now) == false)
    }

    @Test("isToday matches the calendar day regardless of time")
    func isToday() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15, hour: 23, minute: 59))!
        #expect(Format.isToday("2026-03-15", calendar: calendar, now: now) == true)
        #expect(Format.isToday("2026-03-14", calendar: calendar, now: now) == false)
    }

    @Test("daysLate is zero or negative for on-time completion, positive when late")
    func daysLate() {
        let calendar = Calendar(identifier: .gregorian)
        let dueDate = "2026-03-10"
        let onTime = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 9))!
        let early = calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 9))!
        let late = calendar.date(from: DateComponents(year: 2026, month: 3, day: 13, hour: 9))!

        #expect(Format.daysLate(dueDateStr: dueDate, completedAt: onTime, calendar: calendar) == 0)
        #expect(Format.daysLate(dueDateStr: dueDate, completedAt: early, calendar: calendar) < 0)
        #expect(Format.daysLate(dueDateStr: dueDate, completedAt: late, calendar: calendar) == 3)
    }

    @Test("formatRelativeTime buckets into minutes, hours, days, then a date")
    func formatRelativeTime() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        #expect(Format.formatRelativeTime(now, now: now) == "ahora mismo")
        #expect(Format.formatRelativeTime(now.addingTimeInterval(-5 * 60), now: now) == "hace 5 min")
        #expect(Format.formatRelativeTime(now.addingTimeInterval(-3 * 3600), now: now) == "hace 3 h")
        #expect(Format.formatRelativeTime(now.addingTimeInterval(-2 * 86_400), now: now) == "hace 2 d")
    }
}
