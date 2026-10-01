import Testing
import Foundation
@testable import RumisCore

private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar.date(from: DateComponents(year: year, month: month, day: day))!
}

private func ymd(_ date: Date) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    let c = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
}

@Suite("nextAssignee")
struct NextAssigneeTests {
    private let order = ["a", "b", "c"]

    @Test("moves to the next person in order")
    func movesToNextPerson() throws {
        #expect(try ChoreRotation.nextAssignee(rotationOrder: order, currentAssigneeId: "a") == "b")
        #expect(try ChoreRotation.nextAssignee(rotationOrder: order, currentAssigneeId: "b") == "c")
    }

    @Test("wraps around back to the start")
    func wrapsAroundToStart() throws {
        #expect(try ChoreRotation.nextAssignee(rotationOrder: order, currentAssigneeId: "c") == "a")
    }

    @Test("restarts from the beginning if the current assignee left the household")
    func restartsWhenAssigneeLeft() throws {
        #expect(try ChoreRotation.nextAssignee(rotationOrder: ["a", "c"], currentAssigneeId: "b") == "a")
    }

    @Test("throws when there is nobody left in the rotation")
    func throwsWhenRotationEmpty() {
        #expect(throws: ChoreRotationError.emptyRotation) {
            try ChoreRotation.nextAssignee(rotationOrder: [], currentAssigneeId: "a")
        }
    }
}

@Suite("nextDueDate")
struct NextDueDateTests {
    @Test("adds the recurrence in days")
    func addsRecurrenceInDays() {
        let result = ChoreRotation.nextDueDate(from: date(2026, 1, 1), recurrenceDays: 7)
        #expect(ymd(result) == "2026-01-08")
    }

    @Test("rolls over month boundaries correctly")
    func rollsOverMonthBoundaries() {
        let result = ChoreRotation.nextDueDate(from: date(2026, 1, 28), recurrenceDays: 7)
        #expect(ymd(result) == "2026-02-04")
    }
}

@Suite("projectChoreOccurrences")
struct ProjectChoreOccurrencesTests {
    private let order = ["a", "b", "c"]

    @Test("projects forward until the given date, cycling assignees")
    func projectsForwardCyclingAssignees() {
        let occurrences = ChoreRotation.projectChoreOccurrences(
            rotationOrder: order,
            recurrenceDays: 7,
            firstAssignee: "a",
            firstDueDate: date(2026, 1, 1),
            until: date(2026, 1, 22)
        )

        #expect(occurrences.map { (ymd($0.date), $0.assignedTo) }.elementsEqual([
            ("2026-01-01", "a"),
            ("2026-01-08", "b"),
            ("2026-01-15", "c"),
            ("2026-01-22", "a"),
        ], by: ==))
    }

    @Test("returns just the first occurrence when until is before the second")
    func returnsJustFirstOccurrence() {
        let occurrences = ChoreRotation.projectChoreOccurrences(
            rotationOrder: order,
            recurrenceDays: 7,
            firstAssignee: "a",
            firstDueDate: date(2026, 1, 1),
            until: date(2026, 1, 5)
        )
        #expect(occurrences.count == 1)
        #expect(occurrences[0].assignedTo == "a")
    }

    @Test("returns nothing when the first date is already after until")
    func returnsNothingWhenFirstDateAfterUntil() {
        let occurrences = ChoreRotation.projectChoreOccurrences(
            rotationOrder: order,
            recurrenceDays: 7,
            firstAssignee: "a",
            firstDueDate: date(2026, 2, 1),
            until: date(2026, 1, 1)
        )
        #expect(occurrences.isEmpty)
    }
}
