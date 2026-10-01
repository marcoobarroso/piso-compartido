import Foundation
import RumisCore

/// Central data + mutation hub for the Expenses tab. Fetches expenses,
/// shares, settlements, recurring expenses and household members together,
/// and exposes derived balances/settle-up suggestions via
/// RumisCore.DebtSimplify. Every mutation refetches everything afterwards
/// (mirrors `revalidatePath` on the web) since the datasets here are small
/// per household and correctness matters more than shaving a round trip.
@MainActor
@Observable
final class ExpensesStore {
    private let repo = ExpensesRepository()
    private let householdRepo = HouseholdRepository()

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
            async let membersTask = householdRepo.fetchMembers(householdId: householdId)
            async let expensesTask = repo.fetchExpenses(householdId: householdId)
            async let sharesTask = repo.fetchShares(householdId: householdId)
            async let settlementsTask = repo.fetchSettlements(householdId: householdId)
            async let recurringTask = repo.fetchRecurringExpenses(householdId: householdId)
            let (m, e, s, st, r) = try await (membersTask, expensesTask, sharesTask, settlementsTask, recurringTask)
            members = m
            expenses = e
            shares = s
            settlements = st
            recurring = r
        } catch {
            errorMessage = "No se han podido cargar los gastos. Comprueba tu conexión e inténtalo de nuevo."
        }
        isLoading = false
    }

    @discardableResult
    func addExpense(_ insert: ExpenseInsert, shares: [ExpenseShareInput], householdId: UUID) async -> Bool {
        do {
            _ = try await repo.addExpense(insert, shares: shares)
            await loadAll(householdId: householdId)
            return true
        } catch {
            errorMessage = "No se ha podido guardar el gasto: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func updateExpense(id: UUID, fields: ExpenseFieldsUpdate, shares: [ExpenseShareInput], householdId: UUID) async -> Bool {
        do {
            try await repo.updateExpense(id: id, fields: fields, householdId: householdId, shares: shares)
            await loadAll(householdId: householdId)
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
            await loadAll(householdId: householdId)
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
            try await repo.recordSettlement(insert)
            await loadAll(householdId: householdId)
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
            await loadAll(householdId: householdId)
            return true
        } catch {
            errorMessage = "No se ha podido deshacer el pago: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func addRecurringExpense(_ insert: RecurringExpenseInsert, householdId: UUID) async -> Bool {
        do {
            try await repo.addRecurringExpense(insert)
            await loadAll(householdId: householdId)
            return true
        } catch {
            errorMessage = "No se ha podido crear el gasto fijo: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func toggleRecurringExpense(id: UUID, active: Bool, householdId: UUID) async -> Bool {
        do {
            try await repo.toggleRecurringExpense(id: id, active: active)
            await loadAll(householdId: householdId)
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
            await loadAll(householdId: householdId)
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
