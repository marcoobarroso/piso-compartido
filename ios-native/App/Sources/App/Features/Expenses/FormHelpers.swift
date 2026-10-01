import Foundation
import RumisCore

/// Equal vs. exact-amounts split, matching add-expense-form.tsx's two modes.
enum SplitMode: String, CaseIterable {
    case equal, custom
}

/// Parses/formats the euro-denominated text fields used across the expense
/// forms. Money is always Int cents internally per project convention —
/// this is the one place that bridges user-typed decimal strings (comma or
/// dot) to/from cents.
enum MoneyParsing {
    static func centsFromEuroString(_ text: String) -> Int? {
        let normalized = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard !normalized.isEmpty, let value = Double(normalized), value.isFinite, value >= 0 else { return nil }
        return Int((value * 100).rounded())
    }

    static func euroString(fromCents cents: Int) -> String {
        String(format: "%.2f", Double(cents) / 100)
    }
}

/// Builds the "YYYY-MM-DD" string the `expenses.expense_date` column (and
/// RumisCore.Format.parseDateOnly) expects, in the user's local calendar
/// day — not ISO8601 with a time/timezone, which would shift the date.
enum ExpenseDateFormat {
    private static let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = .current
        return df
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }
}

/// Validation + share-building for the add-expense form: a custom split
/// must sum to exactly the total before it's considered valid, mirroring
/// app/actions/expenses.ts's addExpense check.
enum ExpenseFormValidation {
    static func isValid(
        description: String,
        amountText: String,
        splitMode: SplitMode,
        participantIds: Set<UUID>,
        customShareText: [UUID: String],
        members: [HouseholdMember]
    ) -> Bool {
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard let totalCents = MoneyParsing.centsFromEuroString(amountText), totalCents > 0 else { return false }

        switch splitMode {
        case .equal:
            return !participantIds.isEmpty
        case .custom:
            let entered = members.reduce(0) { $0 + (MoneyParsing.centsFromEuroString(customShareText[$1.userId] ?? "") ?? 0) }
            return entered == totalCents
        }
    }

    static func buildShares(
        splitMode: SplitMode,
        totalCents: Int,
        participantIds: Set<UUID>,
        customShareText: [UUID: String],
        members: [HouseholdMember]
    ) -> [ExpenseShareInput] {
        switch splitMode {
        case .equal:
            let ids = members.filter { participantIds.contains($0.userId) }.map { $0.userId.uuidString }
            return DebtSimplify.splitEqually(amountCents: totalCents, userIds: ids)
        case .custom:
            return members.compactMap { member in
                let cents = MoneyParsing.centsFromEuroString(customShareText[member.userId] ?? "") ?? 0
                guard cents > 0 else { return nil }
                return ExpenseShareInput(userId: member.userId.uuidString, shareCents: cents)
            }
        }
    }
}
