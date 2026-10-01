import Testing
@testable import RumisCore

@Suite("splitEqually")
struct SplitEquallyTests {
    @Test("splits evenly when it divides cleanly")
    func splitsEvenly() {
        let shares = DebtSimplify.splitEqually(amountCents: 300, userIds: ["a", "b", "c"])
        #expect(shares == [
            ExpenseShareInput(userId: "a", shareCents: 100),
            ExpenseShareInput(userId: "b", shareCents: 100),
            ExpenseShareInput(userId: "c", shareCents: 100),
        ])
    }

    @Test("gives leftover cents to the first users and always sums to the total")
    func leftoverCents() {
        let shares = DebtSimplify.splitEqually(amountCents: 1000, userIds: ["a", "b", "c"])
        #expect(shares == [
            ExpenseShareInput(userId: "a", shareCents: 334),
            ExpenseShareInput(userId: "b", shareCents: 333),
            ExpenseShareInput(userId: "c", shareCents: 333),
        ])
        #expect(shares.reduce(0) { $0 + $1.shareCents } == 1000)
    }
}

@Suite("scaleShares")
struct ScaleSharesTests {
    @Test("keeps an equal split equal when the total changes")
    func equalSplitStaysEqual() {
        let shares = DebtSimplify.scaleShares(
            shares: [
                ExpenseShareInput(userId: "a", shareCents: 1000),
                ExpenseShareInput(userId: "b", shareCents: 1000),
            ],
            newTotalCents: 3000
        )
        #expect(shares == [
            ExpenseShareInput(userId: "a", shareCents: 1500),
            ExpenseShareInput(userId: "b", shareCents: 1500),
        ])
    }

    @Test("preserves a custom, uneven split's proportions")
    func unevenSplitProportionsPreserved() {
        // a paid 3x what b did (75/25 split), total goes from 4000 to 2000
        let shares = DebtSimplify.scaleShares(
            shares: [
                ExpenseShareInput(userId: "a", shareCents: 3000),
                ExpenseShareInput(userId: "b", shareCents: 1000),
            ],
            newTotalCents: 2000
        )
        #expect(shares == [
            ExpenseShareInput(userId: "a", shareCents: 1500),
            ExpenseShareInput(userId: "b", shareCents: 500),
        ])
    }

    @Test("always sums back to exactly the new total despite rounding")
    func sumsBackExactlyDespiteRounding() {
        let shares = DebtSimplify.scaleShares(
            shares: [
                ExpenseShareInput(userId: "a", shareCents: 100),
                ExpenseShareInput(userId: "b", shareCents: 100),
                ExpenseShareInput(userId: "c", shareCents: 100),
            ],
            newTotalCents: 1000
        )
        #expect(shares.reduce(0) { $0 + $1.shareCents } == 1000)
    }

    @Test("falls back to an equal split if the old total was zero")
    func fallsBackWhenOldTotalZero() {
        let shares = DebtSimplify.scaleShares(
            shares: [
                ExpenseShareInput(userId: "a", shareCents: 0),
                ExpenseShareInput(userId: "b", shareCents: 0),
            ],
            newTotalCents: 1000
        )
        #expect(shares.reduce(0) { $0 + $1.shareCents } == 1000)
    }
}

@Suite("computeBalances")
struct ComputeBalancesTests {
    @Test("nets out who paid vs who owes, ignoring the payer's own share")
    func netsOutPaidVsOwed() {
        // A pays 3000 for a shared expense split equally among A, B, C (1000 each)
        let balances = DebtSimplify.computeBalances(
            expenses: [ExpenseInput(paidBy: "a", amountCents: 3000)],
            shares: [
                ExpenseShareInput(userId: "a", shareCents: 1000),
                ExpenseShareInput(userId: "b", shareCents: 1000),
                ExpenseShareInput(userId: "c", shareCents: 1000),
            ],
            settlements: []
        )

        #expect(balances.get("a") == 2000)
        #expect(balances.get("b") == -1000)
        #expect(balances.get("c") == -1000)
    }

    @Test("applies settlements to move balances toward zero")
    func settlementsMoveTowardZero() {
        let balances = DebtSimplify.computeBalances(
            expenses: [ExpenseInput(paidBy: "a", amountCents: 2000)],
            shares: [
                ExpenseShareInput(userId: "a", shareCents: 1000),
                ExpenseShareInput(userId: "b", shareCents: 1000),
            ],
            settlements: [SettlementInput(fromUserId: "b", toUserId: "a", amountCents: 1000)]
        )

        #expect(balances.get("a") == 0)
        #expect(balances.get("b") == 0)
    }
}

@Suite("simplifyDebts")
struct SimplifyDebtsTests {
    @Test("produces a single transaction for a simple two-person debt")
    func singleTransactionForTwoPeople() {
        let balances = Balances([("a", 1000), ("b", -1000)])
        #expect(DebtSimplify.simplifyDebts(balances) == [Transaction(from: "b", to: "a", amountCents: 1000)])
    }

    @Test("never produces more than n-1 transactions for n people")
    func neverMoreThanNMinusOneTransactions() {
        // a is owed by everyone, b/c/d each owe a bit
        let balances = Balances([("a", 600), ("b", -200), ("c", -150), ("d", -250)])

        let transactions = DebtSimplify.simplifyDebts(balances)
        #expect(transactions.count <= 3)

        // and the net effect must match the original balances exactly
        var net: [String: Int] = [:]
        for t in transactions {
            net[t.from, default: 0] += t.amountCents
            net[t.to, default: 0] -= t.amountCents
        }
        #expect(net["a"] == -600)
        #expect(net["b"] == 200)
        #expect(net["c"] == 150)
        #expect(net["d"] == 250)
    }

    @Test("ignores users who are already settled")
    func ignoresAlreadySettledUsers() {
        let balances = Balances([("a", 0), ("b", 500), ("c", -500)])
        #expect(DebtSimplify.simplifyDebts(balances) == [Transaction(from: "c", to: "b", amountCents: 500)])
    }

    @Test("returns no transactions when everyone is even")
    func noTransactionsWhenEven() {
        let balances = Balances([("a", 0), ("b", 0)])
        #expect(DebtSimplify.simplifyDebts(balances) == [])
    }
}
