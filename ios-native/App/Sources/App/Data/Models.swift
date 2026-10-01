import Foundation
import RumisCore

// Mirrors supabase/migrations/*.sql exactly (column names/types), decoded
// with a JSONDecoder using .convertFromSnakeCase (see SupabaseClient.swift).
// Postgres `date` columns (expense_date, due_date, last_generated_month) are
// kept as raw "YYYY-MM-DD" strings — same choice lib/format.ts makes — and
// parsed on demand via RumisCore.Format.parseDateOnly to avoid timezone
// shift bugs. `timestamptz` columns decode straight to Date.

struct Profile: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var displayName: String?
    var avatarUrl: String?
    let createdAt: Date
}

struct Household: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var inviteCode: String
    let createdBy: UUID
    let createdAt: Date
}

struct HouseholdMember: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let householdId: UUID
    let userId: UUID
    var role: String // "admin" | "member"
    let joinedAt: Date
    /// Populated only when selected with a `profiles(*)` embed.
    var profiles: Profile?

    var isAdmin: Bool { role == "admin" }
}

struct Expense: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let householdId: UUID
    var paidBy: UUID
    var description: String
    var amountCents: Int
    var currency: String
    var expenseDate: String // date-only "YYYY-MM-DD"
    let createdBy: UUID
    let createdAt: Date
    var category: ExpenseCategory
}

struct ExpenseShare: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let householdId: UUID
    let expenseId: UUID
    var userId: UUID
    var shareCents: Int
}

struct Settlement: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let householdId: UUID
    var fromUserId: UUID
    var toUserId: UUID
    var amountCents: Int
    var note: String?
    let settledAt: Date
}

struct Chore: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let householdId: UUID
    var name: String
    var description: String?
    var recurrenceDays: Int
    var rotationOrder: [UUID]
    var rotationPointer: Int
    var active: Bool
    let createdBy: UUID
    let createdAt: Date
}

struct ChoreAssignment: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let choreId: UUID
    let householdId: UUID
    var assignedTo: UUID
    var dueDate: String // date-only "YYYY-MM-DD"
    var status: String // "pending" | "done" | "skipped"
    var completedAt: Date?
    var completedBy: UUID?
    let createdAt: Date
}

struct ShoppingItem: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let householdId: UUID
    var name: String
    var quantity: String?
    var addedBy: UUID
    var isChecked: Bool
    var checkedBy: UUID?
    var checkedAt: Date?
    let createdAt: Date
    var ownerUserId: UUID?

    var isShared: Bool { ownerUserId == nil }
}

struct AppNotification: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let householdId: UUID
    let userId: UUID
    var message: String
    var link: String?
    var isRead: Bool
    let createdAt: Date
}

struct RecurringExpense: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let householdId: UUID
    var description: String
    var amountCents: Int
    var category: ExpenseCategory
    var dayOfMonth: Int
    var paidBy: UUID
    var active: Bool
    let createdBy: UUID
    let createdAt: Date
    var lastGeneratedMonth: String? // date-only "YYYY-MM-DD"
}
