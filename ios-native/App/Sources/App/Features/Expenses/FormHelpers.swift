import Foundation
import RumisCore

// SplitMode and MoneyParsing now live in RumisCore (see
// RumisCore/Sources/RumisCore/MoneyParsing.swift) — tested there, used
// here unqualified via the `import RumisCore` above.

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
