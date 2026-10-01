import Foundation

/// Mirrors lib/format.ts.
public enum Format {
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_ES")
        formatter.currencyCode = "EUR"
        return formatter
    }()

    public static func formatCents(_ amountCents: Int) -> String {
        let amount = NSDecimalNumber(value: amountCents).dividing(by: 100)
        return currencyFormatter.string(from: amount) ?? "\(amount)\u{20ac}"
    }

    /// Parses a "YYYY-MM-DD" date column as a local date, avoiding the UTC
    /// midnight shift that naive ISO parsing introduces.
    public static func parseDateOnly(_ dateStr: String, calendar: Calendar = .current) -> Date? {
        let parts = dateStr.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        return calendar.date(from: components)
    }

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter
    }()

    /// Inverse of `parseDateOnly` — formats a `Date` as the "YYYY-MM-DD"
    /// string the `expenses.expense_date`/`chore_assignments.due_date`
    /// columns expect, in the device's local calendar day.
    public static func dateOnlyString(from date: Date) -> String {
        dateOnlyFormatter.string(from: date)
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter
    }()

    public static func formatDate(_ dateStr: String) -> String {
        guard let date = parseDateOnly(dateStr) else { return dateStr }
        return shortDateFormatter.string(from: date)
    }

    public static func isOverdue(_ dateStr: String, calendar: Calendar = .current, now: Date = Date()) -> Bool {
        guard let date = parseDateOnly(dateStr, calendar: calendar) else { return false }
        return date < calendar.startOfDay(for: now)
    }

    public static func isToday(_ dateStr: String, calendar: Calendar = .current, now: Date = Date()) -> Bool {
        guard let date = parseDateOnly(dateStr, calendar: calendar) else { return false }
        return calendar.isDate(date, inSameDayAs: now)
    }

    /// How many days late a chore was completed: 0 or negative means on time
    /// (completed on or before its due date), positive means that many days
    /// late.
    public static func daysLate(dueDateStr: String, completedAt: Date, calendar: Calendar = .current) -> Int {
        guard let due = parseDateOnly(dueDateStr, calendar: calendar) else { return 0 }
        let completedDay = calendar.startOfDay(for: completedAt)
        let seconds = completedDay.timeIntervalSince(due)
        return Int((seconds / 86_400).rounded())
    }

    public static func formatRelativeTime(_ date: Date, now: Date = Date()) -> String {
        let diffMinutes = Int((now.timeIntervalSince(date) / 60).rounded())

        if diffMinutes < 1 { return "ahora mismo" }
        if diffMinutes < 60 { return "hace \(diffMinutes) min" }

        let diffHours = Int((Double(diffMinutes) / 60).rounded())
        if diffHours < 24 { return "hace \(diffHours) h" }

        let diffDays = Int((Double(diffHours) / 24).rounded())
        if diffDays < 7 { return "hace \(diffDays) d" }

        return shortDateFormatter.string(from: date)
    }
}
