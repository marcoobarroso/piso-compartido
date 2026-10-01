import Foundation

public enum ChoreRotationError: Error, Equatable {
    case emptyRotation
}

public struct ChoreOccurrence: Equatable, Sendable {
    public let date: Date
    public let assignedTo: String

    public init(date: Date, assignedTo: String) {
        self.date = date
        self.assignedTo = assignedTo
    }
}

public enum ChoreRotation {
    /// Whoever is next in the fixed rotation order, given whose turn it is now.
    /// If the current assignee is no longer in the rotation (they left the
    /// household), the rotation restarts from the beginning of the list rather
    /// than throwing, so a departure never gets a chore stuck.
    public static func nextAssignee(rotationOrder: [String], currentAssigneeId: String) throws -> String {
        guard !rotationOrder.isEmpty else {
            throw ChoreRotationError.emptyRotation
        }

        guard let currentIndex = rotationOrder.firstIndex(of: currentAssigneeId) else {
            return rotationOrder[0]
        }

        return rotationOrder[(currentIndex + 1) % rotationOrder.count]
    }

    public static func nextDueDate(from date: Date, recurrenceDays: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: recurrenceDays, to: date) ?? date
    }

    /// Projects a chore's occurrences forward from its current real assignment
    /// up to (and including) `until`, assuming everyone completes on time. Only
    /// the first occurrence returned corresponds to a real chore_assignment row
    /// in the database — the rest are estimates for calendar display, and shift
    /// automatically if someone finishes early or late.
    public static func projectChoreOccurrences(
        rotationOrder: [String],
        recurrenceDays: Int,
        firstAssignee: String,
        firstDueDate: Date,
        until: Date,
        calendar: Calendar = .current
    ) -> [ChoreOccurrence] {
        var occurrences: [ChoreOccurrence] = []
        var assignee = firstAssignee
        var date = firstDueDate
        var safety = 0

        while date <= until && safety < 366 {
            occurrences.append(ChoreOccurrence(date: date, assignedTo: assignee))
            guard let next = try? nextAssignee(rotationOrder: rotationOrder, currentAssigneeId: assignee) else {
                break
            }
            assignee = next
            date = nextDueDate(from: date, recurrenceDays: recurrenceDays, calendar: calendar)
            safety += 1
        }

        return occurrences
    }
}
