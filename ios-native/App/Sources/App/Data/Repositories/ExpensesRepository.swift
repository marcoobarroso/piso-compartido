import Foundation
import RumisCore
import Supabase

struct ExpenseInsert: Encodable {
    let householdId: UUID
    let paidBy: UUID
    let description: String
    let amountCents: Int
    let category: ExpenseCategory
    let expenseDate: String
    let createdBy: UUID
}

struct ExpenseFieldsUpdate: Encodable {
    var paidBy: UUID
    var description: String
    var amountCents: Int
    var category: ExpenseCategory
    var expenseDate: String
}

struct ExpenseShareInsert: Encodable {
    let householdId: UUID
    let expenseId: UUID
    let userId: UUID
    let shareCents: Int
}

struct SettlementInsert: Encodable {
    let householdId: UUID
    let fromUserId: UUID
    let toUserId: UUID
    let amountCents: Int
}

struct RecurringExpenseInsert: Encodable {
    let householdId: UUID
    let description: String
    let amountCents: Int
    let category: ExpenseCategory
    let dayOfMonth: Int
    let paidBy: UUID
    let createdBy: UUID
}

struct ActiveUpdate: Encodable {
    var active: Bool
}

/// Thin CRUD over expenses/expense_shares/settlements/recurring_expenses.
/// Split math (equal/custom, rescaling on edit, balances, simplification)
/// lives in RumisCore.DebtSimplify — callers compute shares, this just
/// persists them, mirroring the manual-rollback pattern from
/// app/actions/expenses.ts (Postgres has no client-visible transactions
/// over PostgREST, so a failed shares insert deletes the just-created
/// expense).
struct ExpensesRepository {
    func fetchExpenses(householdId: UUID) async throws -> [Expense] {
        try await supabase.from("expenses")
            .select()
            .eq("household_id", value: householdId)
            .order("expense_date", ascending: false)
            .execute()
            .value
    }

    func fetchShares(householdId: UUID) async throws -> [ExpenseShare] {
        try await supabase.from("expense_shares")
            .select()
            .eq("household_id", value: householdId)
            .execute()
            .value
    }

    func fetchSettlements(householdId: UUID) async throws -> [Settlement] {
        try await supabase.from("settlements")
            .select()
            .eq("household_id", value: householdId)
            .order("settled_at", ascending: false)
            .execute()
            .value
    }

    func addExpense(_ expense: ExpenseInsert, shares: [ExpenseShareInput]) async throws -> Expense {
        let inserted: Expense = try await supabase.from("expenses")
            .insert(expense)
            .select()
            .single()
            .execute()
            .value

        do {
            let shareInserts = shares.map {
                ExpenseShareInsert(householdId: expense.householdId, expenseId: inserted.id, userId: UUID(uuidString: $0.userId)!, shareCents: $0.shareCents)
            }
            try await supabase.from("expense_shares").insert(shareInserts).execute()
        } catch {
            try? await supabase.from("expenses").delete().eq("id", value: inserted.id).execute()
            throw error
        }

        return inserted
    }

    func updateExpense(id: UUID, fields: ExpenseFieldsUpdate, householdId: UUID, shares: [ExpenseShareInput]) async throws {
        try await supabase.from("expenses").update(fields).eq("id", value: id).execute()

        try await supabase.from("expense_shares").delete().eq("expense_id", value: id).execute()
        let shareInserts = shares.map {
            ExpenseShareInsert(householdId: householdId, expenseId: id, userId: UUID(uuidString: $0.userId)!, shareCents: $0.shareCents)
        }
        try await supabase.from("expense_shares").insert(shareInserts).execute()
    }

    func deleteExpense(id: UUID) async throws {
        try await supabase.from("expenses").delete().eq("id", value: id).execute()
    }

    func recordSettlement(_ settlement: SettlementInsert) async throws {
        try await supabase.from("settlements").insert(settlement).execute()
    }

    func deleteSettlement(id: UUID) async throws {
        try await supabase.from("settlements").delete().eq("id", value: id).execute()
    }

    func fetchRecurringExpenses(householdId: UUID) async throws -> [RecurringExpense] {
        try await supabase.from("recurring_expenses")
            .select()
            .eq("household_id", value: householdId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func addRecurringExpense(_ insert: RecurringExpenseInsert) async throws {
        try await supabase.from("recurring_expenses").insert(insert).execute()
    }

    func toggleRecurringExpense(id: UUID, active: Bool) async throws {
        try await supabase.from("recurring_expenses")
            .update(ActiveUpdate(active: active))
            .eq("id", value: id)
            .execute()
    }

    func deleteRecurringExpense(id: UUID) async throws {
        try await supabase.from("recurring_expenses").delete().eq("id", value: id).execute()
    }

    func generateRecurringNow(householdId: UUID) async throws {
        try await supabase
            .rpc("generate_recurring_expenses_for_household", params: HouseholdIdParams(householdId: householdId))
            .execute()
    }
}
