import Foundation

public struct ExpenseInput: Equatable, Sendable {
    public let paidBy: String
    public let amountCents: Int

    public init(paidBy: String, amountCents: Int) {
        self.paidBy = paidBy
        self.amountCents = amountCents
    }
}

public struct ExpenseShareInput: Equatable, Sendable {
    public let userId: String
    public let shareCents: Int

    public init(userId: String, shareCents: Int) {
        self.userId = userId
        self.shareCents = shareCents
    }
}

public struct SettlementInput: Equatable, Sendable {
    public let fromUserId: String
    public let toUserId: String
    public let amountCents: Int

    public init(fromUserId: String, toUserId: String, amountCents: Int) {
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.amountCents = amountCents
    }
}

public struct Transaction: Equatable, Sendable {
    public let from: String
    public let to: String
    public let amountCents: Int

    public init(from: String, to: String, amountCents: Int) {
        self.from = from
        self.to = to
        self.amountCents = amountCents
    }
}

/// Net balance per user, insertion-ordered like the JS `Map` it mirrors so
/// `simplifyDebts` breaks ties the same way the web app does.
public struct Balances: Sendable {
    public private(set) var order: [String] = []
    private var values: [String: Int] = [:]

    public init() {}

    public init(_ pairs: [(String, Int)]) {
        for (userId, amountCents) in pairs {
            add(userId, amountCents)
        }
    }

    public mutating func add(_ userId: String, _ delta: Int) {
        if values[userId] == nil {
            order.append(userId)
            values[userId] = 0
        }
        values[userId]! += delta
    }

    public func get(_ userId: String) -> Int? {
        values[userId]
    }

    public var entries: [(userId: String, amountCents: Int)] {
        order.map { ($0, values[$0]!) }
    }
}

public enum DebtSimplify {
    /// Splits an amount equally among users using integer cents only, giving the
    /// leftover cents (from the division remainder) to the first users in the
    /// list so the shares always sum back to exactly amountCents.
    public static func splitEqually(amountCents: Int, userIds: [String]) -> [ExpenseShareInput] {
        let n = userIds.count
        let base = amountCents / n
        let remainder = amountCents - base * n

        return userIds.enumerated().map { i, userId in
            ExpenseShareInput(userId: userId, shareCents: base + (i < remainder ? 1 : 0))
        }
    }

    /// Rescales shares to a new total while preserving each user's relative
    /// proportion, using the largest-remainder method so the result always sums
    /// back to exactly newTotalCents (integer cents only, no floats leaking out).
    public static func scaleShares(shares: [ExpenseShareInput], newTotalCents: Int) -> [ExpenseShareInput] {
        let oldTotal = shares.reduce(0) { $0 + $1.shareCents }
        if oldTotal == 0 {
            return splitEqually(amountCents: newTotalCents, userIds: shares.map { $0.userId })
        }

        struct Floored {
            let userId: String
            var shareCents: Int
            let remainder: Double
        }

        var floored: [Floored] = shares.map { s in
            let exact = Double(s.shareCents * newTotalCents) / Double(oldTotal)
            let flooredValue = Int(exact.rounded(.down))
            return Floored(userId: s.userId, shareCents: flooredValue, remainder: exact - Double(flooredValue))
        }

        let allocated = floored.reduce(0) { $0 + $1.shareCents }
        let remaining = newTotalCents - allocated

        if remaining > 0 {
            let orderByRemainder = floored.indices.sorted { floored[$0].remainder > floored[$1].remainder }
            for i in 0..<remaining {
                let idx = orderByRemainder[i % orderByRemainder.count]
                floored[idx].shareCents += 1
            }
        }

        return floored.map { ExpenseShareInput(userId: $0.userId, shareCents: $0.shareCents) }
    }

    /// Net balance per user: positive means the household owes them money,
    /// negative means they owe the household money.
    public static func computeBalances(
        expenses: [ExpenseInput],
        shares: [ExpenseShareInput],
        settlements: [SettlementInput]
    ) -> Balances {
        var balances = Balances()

        for expense in expenses {
            balances.add(expense.paidBy, expense.amountCents)
        }
        for share in shares {
            balances.add(share.userId, -share.shareCents)
        }
        for settlement in settlements {
            balances.add(settlement.fromUserId, settlement.amountCents)
            balances.add(settlement.toUserId, -settlement.amountCents)
        }

        return balances
    }

    /// Greedy debtor/creditor matching: reduces "who owes what" to at most n-1
    /// transactions by always settling the largest debtor against the largest
    /// creditor first.
    public static func simplifyDebts(_ balances: Balances) -> [Transaction] {
        struct Party { let userId: String; var amountCents: Int }

        var debtors: [Party] = []
        var creditors: [Party] = []

        for (userId, amountCents) in balances.entries {
            if amountCents < 0 {
                debtors.append(Party(userId: userId, amountCents: -amountCents))
            } else if amountCents > 0 {
                creditors.append(Party(userId: userId, amountCents: amountCents))
            }
        }

        debtors.sort { $0.amountCents > $1.amountCents }
        creditors.sort { $0.amountCents > $1.amountCents }

        var transactions: [Transaction] = []
        var i = 0
        var j = 0

        while i < debtors.count && j < creditors.count {
            let amount = min(debtors[i].amountCents, creditors[j].amountCents)

            if amount > 0 {
                transactions.append(Transaction(from: debtors[i].userId, to: creditors[j].userId, amountCents: amount))
            }

            debtors[i].amountCents -= amount
            creditors[j].amountCents -= amount

            if debtors[i].amountCents == 0 { i += 1 }
            if creditors[j].amountCents == 0 { j += 1 }
        }

        return transactions
    }
}
