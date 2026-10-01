import SwiftUI
import RumisCore

/// Pending assignments, soonest due date first. Mirrors the "Lista" tab in
/// app/household/chores/page.tsx.
struct ChoresListTab: View {
    let chores: [Chore]
    let assignments: [ChoreAssignment]
    let memberNames: [UUID: String]
    let householdId: UUID
    let userId: UUID
    let onCompleted: () async -> Void

    private let repo = ChoresRepository()
    @State private var completingId: UUID?

    private var pending: [ChoreAssignment] {
        assignments
            .filter { $0.status == "pending" }
            .sorted { $0.dueDate < $1.dueDate }
    }

    private func chore(for assignment: ChoreAssignment) -> Chore? {
        chores.first { $0.id == assignment.choreId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if pending.isEmpty {
                emptyState
            } else {
                ForEach(Array(pending.enumerated()), id: \.element.id) { index, assignment in
                    row(for: assignment)
                    if index != pending.count - 1 {
                        Rectangle()
                            .fill(RTheme.border)
                            .frame(height: 1)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(RTheme.mutedForeground.opacity(0.5))
            Text("Todavía no hay tareas domésticas. Añade la primera arriba.")
                .font(.subheadline)
                .foregroundStyle(RTheme.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    @ViewBuilder
    private func row(for assignment: ChoreAssignment) -> some View {
        let matchedChore = chore(for: assignment)
        let name = matchedChore?.name ?? ""
        let overdue = Format.isOverdue(assignment.dueDate)
        let today = Format.isToday(assignment.dueDate)
        let rotationEmpty = matchedChore?.rotationOrder.isEmpty ?? true

        HStack(alignment: .top, spacing: 10) {
            Text(EmojiMatch.choreEmoji(name))
                .font(.system(size: 16))
                .frame(width: 32, height: 32)
                .background(RTheme.accent)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RTheme.foreground)
                Text(memberNames[assignment.assignedTo] ?? "—")
                    .font(.caption)
                    .foregroundStyle(RTheme.mutedForeground)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                if overdue {
                    RBadge(text: "Vencida", tint: RTheme.destructive, background: RTheme.destructive.opacity(0.15))
                } else if today {
                    RBadge(text: "Hoy", tint: RTheme.primary, background: RTheme.primary.opacity(0.15))
                } else {
                    RBadge(text: Format.formatDate(assignment.dueDate))
                }

                Button {
                    Task { await complete(assignment, chore: matchedChore) }
                } label: {
                    if completingId == assignment.id {
                        ProgressView()
                            .tint(RTheme.primaryForeground)
                    } else {
                        Text("Hecho")
                    }
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RTheme.primary)
                .foregroundStyle(RTheme.primaryForeground)
                .clipShape(Capsule())
                .disabled(rotationEmpty || completingId != nil)
            }
        }
    }

    private func complete(_ assignment: ChoreAssignment, chore: Chore?) async {
        guard let chore else { return }
        let rotation = chore.rotationOrder.map(\.uuidString)
        guard
            let nextId = try? ChoreRotation.nextAssignee(rotationOrder: rotation, currentAssigneeId: assignment.assignedTo.uuidString),
            let nextUUID = UUID(uuidString: nextId)
        else { return }

        // Matches app/actions/chores.ts completeChore: the next due date is
        // recurrenceDays from the moment it's completed (not from the
        // original due date), so a late completion shifts the whole
        // rotation later instead of leaving it stuck in the past.
        let nextDate = ChoreRotation.nextDueDate(from: Date(), recurrenceDays: chore.recurrenceDays)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        let nextDateStr = formatter.string(from: nextDate)

        completingId = assignment.id
        defer { completingId = nil }
        do {
            try await repo.completeChore(
                assignmentId: assignment.id,
                choreId: chore.id,
                householdId: householdId,
                completedBy: userId,
                nextAssignedTo: nextUUID,
                nextDueDate: nextDateStr
            )
            await onCompleted()
            ReviewPrompt.registerPositiveAction()
        } catch {
            // Best-effort: the list stays as-is and the user can retry.
        }
    }
}
