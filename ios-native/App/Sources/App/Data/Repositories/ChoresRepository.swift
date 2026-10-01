import Foundation
import Supabase

struct ChoreInsert: Encodable {
    let householdId: UUID
    let name: String
    let description: String?
    let recurrenceDays: Int
    let rotationOrder: [UUID]
    let createdBy: UUID
}

struct ChoreFieldsUpdate: Encodable {
    var name: String
    var description: String?
    var recurrenceDays: Int
    var rotationOrder: [UUID]
}

struct ChoreAssignmentInsert: Encodable {
    let choreId: UUID
    let householdId: UUID
    let assignedTo: UUID
    let dueDate: String
}

struct ChoreAssignmentCompleteUpdate: Encodable {
    var status: String
    var completedAt: Date
    var completedBy: UUID
}

/// Thin CRUD over chores/chore_assignments. Rotation math (who's next, due
/// dates, calendar projection) lives in RumisCore.ChoreRotation — callers
/// compute the next assignment, this just persists it, mirroring
/// completeChore in app/actions/chores.ts.
struct ChoresRepository {
    func fetchChores(householdId: UUID) async throws -> [Chore] {
        try await supabase.from("chores")
            .select()
            .eq("household_id", value: householdId)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func fetchAssignments(householdId: UUID) async throws -> [ChoreAssignment] {
        try await supabase.from("chore_assignments")
            .select()
            .eq("household_id", value: householdId)
            .order("due_date", ascending: true)
            .execute()
            .value
    }

    func addChore(_ chore: ChoreInsert, firstAssignee: UUID, firstDueDate: String) async throws -> (chore: Chore, assignment: ChoreAssignment) {
        let inserted: Chore = try await supabase.from("chores")
            .insert(chore)
            .select()
            .single()
            .execute()
            .value

        let assignment: ChoreAssignment = try await supabase.from("chore_assignments")
            .insert(ChoreAssignmentInsert(choreId: inserted.id, householdId: chore.householdId, assignedTo: firstAssignee, dueDate: firstDueDate))
            .select()
            .single()
            .execute()
            .value

        return (inserted, assignment)
    }

    func updateChore(id: UUID, fields: ChoreFieldsUpdate) async throws {
        try await supabase.from("chores").update(fields).eq("id", value: id).execute()
    }

    func deleteChore(id: UUID) async throws {
        try await supabase.from("chores").delete().eq("id", value: id).execute()
    }

    /// Marks the current assignment done and creates the next one — caller
    /// computes `nextAssignedTo`/`nextDueDate` via RumisCore.ChoreRotation.
    /// Returns both rows so the caller can update local state in place.
    func completeChore(assignmentId: UUID, choreId: UUID, householdId: UUID, completedBy: UUID, nextAssignedTo: UUID, nextDueDate: String) async throws -> (completed: ChoreAssignment, next: ChoreAssignment) {
        let completed: ChoreAssignment = try await supabase.from("chore_assignments")
            .update(ChoreAssignmentCompleteUpdate(status: "done", completedAt: Date(), completedBy: completedBy))
            .eq("id", value: assignmentId)
            .select()
            .single()
            .execute()
            .value

        let next: ChoreAssignment = try await supabase.from("chore_assignments")
            .insert(ChoreAssignmentInsert(choreId: choreId, householdId: householdId, assignedTo: nextAssignedTo, dueDate: nextDueDate))
            .select()
            .single()
            .execute()
            .value

        return (completed, next)
    }
}
