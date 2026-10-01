import Foundation
import RumisCore

/// Central data + mutation hub for the Expenses tab. Fetches expenses,
/// shares, settlements and recurring expenses; household members come from
/// `AppSession.members` (set via `setMembers`) instead of being fetched
/// here too, since every tab needs the same list. Each mutation splices its
/// own result into local state instead of re-fetching everything — the one
/// exception is `generateRecurringNow`, whose server-side date logic can
/// create/skip an arbitrary number of rows, so that one still reloads.
@MainActor
@Observable
final class ExpensesStore {
    private let repo = ExpensesRepository()

    private(set) var members: [HouseholdMember] = []
    private(set) var expenses: [Expense] = []
    private(set) var shares: [ExpenseShare] = []
    private(set) var settlements: [Settlement] = []
    private(set) var recurring: [RecurringExpense] = []

    var isLoading = false
    var errorMessage: String?

    /// Empty, non-isolated on purpose: lets `@State private var store =
    /// ExpensesStore()` construct this MainActor-isolated type from a
    /// (formally) non-isolated View initializer context.
    nonisolated init() {}

    func setMembers(_ members: [HouseholdMember]) {
        self.members = members
    }

    var nameByUserId: [UUID: String] {
        Dictionary(uniqueKeysWithValues: members.map { ($0.userId, $0.profiles?.displayName ?? "Sin nombre") })
    }

    func name(for userId: UUID) -> String {
        nameByUserId[userId] ?? "—"
    }

    func sharesForExpense(_ expenseId: UUID) -> [ExpenseShare] {
        shares.filter { $0.expenseId == expenseId }
    }

    var balances: Balances {
        DebtSimplify.computeBalances(
            expenses: expenses.map { ExpenseInput(paidBy: $0.paidBy.uuidString, amountCents: $0.amountCents) },
            shares: shares.map { ExpenseShareInput(userId: $0.userId.uuidString, shareCents: $0.shareCents) },
            settlements: settlements.map {
                SettlementInput(fromUserId: $0.fromUserId.uuidString, toUserId: $0.toUserId.uuidString, amountCents: $0.amountCents)
            }
        )
    }

    var suggestedTransactions: [Transaction] {
        DebtSimplify.simplifyDebts(balances)
    }

    func loadAll(householdId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            async let expensesTask = repo.fetchExpenses(householdId: householdId)
            async let sharesTask = repo.fetchShares(householdId: householdId)
            async let settlementsTask = repo.fetchSettlements(householdId: householdId)
            async let recurringTask = repo.fetchRecurringExpenses(householdId: householdId)
            let (e, s, st, r) = try await (expensesTask, sharesTask, settlementsTask, recurringTask)
            expenses = e
            shares = s
            settlements = st
            recurring = r
        } catch {
            errorMessage = "No se han podido cargar los gastos: \(error.localizedDescription)"
        }
        isLoading = false
    }

    /// Expenses are shown newest-first by `expenseDate` ("YYYY-MM-DD", so a
    /// plain string compare sorts chronologically) — re-sort after any
    /// insert/update since the edited date may have moved.
    private func resortExpenses() {
        expenses.sort { $0.expenseDate > $1.expenseDate }
    }

    @discardableResult
    func addExpense(_ insert: ExpenseInsert, shares: [ExpenseShareInput], householdId: UUID) async -> Bool {
        do {
            let (expense, newShares) = try await repo.addExpense(insert, shares: shares)
            expenses.append(expense)
            resortExpenses()
            self.shares.append(contentsOf: newShares)
            return true
        } catch {
            errorMessage = "No se ha podido guardar el gasto: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func updateExpense(id: UUID, fields: ExpenseFieldsUpdate, shares: [ExpenseShareInput], householdId: UUID) async -> Bool {
        do {
            let (expense, newShares) = try await repo.updateExpense(id: id, fields: fields, householdId: householdId, shares: shares)
            if let index = expenses.firstIndex(where: { $0.id == id }) {
                expenses[index] = expense
            }
            resortExpenses()
            self.shares.removeAll { $0.expenseId == id }
            self.shares.append(contentsOf: newShares)
            return true
        } catch {
            errorMessage = "No se ha podido actualizar el gasto: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func deleteExpense(id: UUID, householdId: UUID) async -> Bool {
        do {
            try await repo.deleteExpense(id: id)
            expenses.removeAll { $0.id == id }
            shares.removeAll { $0.expenseId == id }
            return true
        } catch {
            errorMessage = "No se ha podido borrar el gasto: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func recordSettlement(fromUserId: UUID, toUserId: UUID, amountCents: Int, householdId: UUID) async -> Bool {
        do {
            let insert = SettlementInsert(householdId: householdId, fromUserId: fromUserId, toUserId: toUserId, amountCents: amountCents)
            let settlement = try await repo.recordSettlement(insert)
            settlements.insert(settlement, at: 0)
            return true
        } catch {
            errorMessage = "No se ha podido registrar el pago: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func deleteSettlement(id: UUID, householdId: UUID) async -> Bool {
        do {
            try await repo.deleteSettlement(id: id)
            settlements.removeAll { $0.id == id }
            return true
        } catch {
            errorMessage = "No se ha podido deshacer el pago: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func addRecurringExpense(_ insert: RecurringExpenseInsert, householdId: UUID) async -> Bool {
        do {
            let created = try await repo.addRecurringExpense(insert)
            recurring.insert(created, at: 0)
            return true
        } catch {
            errorMessage = "No se ha podido crear el gasto fijo: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func toggleRecurringExpense(id: UUID, active: Bool, householdId: UUID) async -> Bool {
        do {
            let updated = try await repo.toggleRecurringExpense(id: id, active: active)
            if let index = recurring.firstIndex(where: { $0.id == id }) {
                recurring[index] = updated
            }
            return true
        } catch {
            errorMessage = "No se ha podido actualizar el gasto fijo: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func deleteRecurringExpense(id: UUID, householdId: UUID) async -> Bool {
        do {
            try await repo.deleteRecurringExpense(id: id)
            recurring.removeAll { $0.id == id }
            return true
        } catch {
            errorMessage = "No se ha podido borrar el gasto fijo: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func generateRecurringNow(householdId: UUID) async -> Bool {
        do {
            try await repo.generateRecurringNow(householdId: householdId)
            await loadAll(householdId: householdId)
            return true
        } catch {
            errorMessage = "No se han podido generar los gastos fijos: \(error.localizedDescription)"
            return false
        }
    }
}
