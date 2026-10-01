import SwiftUI
import RumisCore

/// Hand-rolled month grid projecting each active chore's occurrences
/// forward from its earliest pending assignment. Mirrors
/// app/household/chores/chores-calendar.tsx.
struct ChoresCalendarTab: View {
    let chores: [Chore]
    let assignments: [ChoreAssignment]
    let memberNames: [UUID: String]

    @State private var visibleMonth: Date = Calendar.current.date(
        from: Calendar.current.dateComponents([.year, .month], from: Date())
    ) ?? Date()
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())

    private let calendar = Calendar.current
    private static let weekdayLabels = ["L", "M", "X", "J", "V", "S", "D"]

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    private static let selectedDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE, d 'de' MMMM"
        return f
    }()

    private struct CalendarEvent: Identifiable {
        let id = UUID()
        let chore: Chore
        let assignedTo: UUID
        let isReal: Bool
        let colorIndex: Int
    }

    private var gridStart: Date {
        let first = calendar.date(from: calendar.dateComponents([.year, .month], from: visibleMonth)) ?? visibleMonth
        let weekday = calendar.component(.weekday, from: first) // 1 = Sun ... 7 = Sat
        let offset = (weekday + 5) % 7 // Monday = 0
        return calendar.date(byAdding: .day, value: -offset, to: first) ?? first
    }

    private var gridDays: [Date] {
        (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    private var eventsByDay: [String: [CalendarEvent]] {
        guard let gridEnd = gridDays.last else { return [:] }
        var map: [String: [CalendarEvent]] = [:]

        for (index, chore) in chores.enumerated() where chore.active {
            let pendingForChore = assignments
                .filter { $0.choreId == chore.id && $0.status == "pending" }
                .sorted { $0.dueDate < $1.dueDate }
            guard
                let earliest = pendingForChore.first,
                let firstDueDate = Format.parseDateOnly(earliest.dueDate)
            else { continue }

            let occurrences = ChoreRotation.projectChoreOccurrences(
                rotationOrder: chore.rotationOrder.map(\.uuidString),
                recurrenceDays: chore.recurrenceDays,
                firstAssignee: earliest.assignedTo.uuidString,
                firstDueDate: firstDueDate,
                until: gridEnd
            )

            for (occIndex, occ) in occurrences.enumerated() {
                guard occ.date >= gridStart, let assignedUUID = UUID(uuidString: occ.assignedTo) else { continue }
                let key = Self.keyFormatter.string(from: occ.date)
                map[key, default: []].append(
                    CalendarEvent(chore: chore, assignedTo: assignedUUID, isReal: occIndex == 0, colorIndex: index)
                )
            }
        }
        return map
    }

    private func events(on day: Date) -> [CalendarEvent] {
        eventsByDay[Self.keyFormatter.string(from: day)] ?? []
    }

    var body: some View {
        if chores.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 12) {
                header

                HStack(spacing: 0) {
                    ForEach(Self.weekdayLabels, id: \.self) { label in
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(RTheme.mutedForeground)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(gridDays, id: \.self) { day in
                        dayCell(day)
                    }
                }

                Rectangle()
                    .fill(RTheme.border)
                    .frame(height: 1)

                selectedDaySection
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

    private var header: some View {
        HStack {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("Mes anterior")
            Spacer()
            Text(Self.monthFormatter.string(from: visibleMonth).capitalized)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RTheme.foreground)
            Spacer()
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
            }
            .accessibilityLabel("Mes siguiente")
        }
        .foregroundStyle(RTheme.mutedForeground)
    }

    private func changeMonth(by value: Int) {
        visibleMonth = calendar.date(byAdding: .month, value: value, to: visibleMonth) ?? visibleMonth
    }

    @ViewBuilder
    private func dayCell(_ day: Date) -> some View {
        let dayEvents = events(on: day)
        let inMonth = calendar.isDate(day, equalTo: visibleMonth, toGranularity: .month)
        let isToday = calendar.isDateInToday(day)
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)

        Button {
            selectedDay = day
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.caption)
                    .foregroundStyle(inMonth ? RTheme.foreground : RTheme.mutedForeground.opacity(0.4))

                HStack(spacing: 2) {
                    ForEach(dayEvents.prefix(4)) { event in
                        Circle()
                            .fill(ChartPalette.color(at: event.colorIndex))
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(isSelected ? RTheme.primary.opacity(0.18) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: RTheme.Radius.sm)
                    .strokeBorder(isToday && !isSelected ? RTheme.primary.opacity(0.5) : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: RTheme.Radius.sm))
        }
        .buttonStyle(.plain)
    }

    private var selectedDaySection: some View {
        let dayEvents = events(on: selectedDay)
        return VStack(alignment: .leading, spacing: 8) {
            Text(Self.selectedDayFormatter.string(from: selectedDay))
                .font(.caption.weight(.medium))
                .foregroundStyle(RTheme.mutedForeground)

            if dayEvents.isEmpty {
                Text("Nada programado este día.")
                    .font(.subheadline)
                    .foregroundStyle(RTheme.mutedForeground)
            } else {
                VStack(spacing: 8) {
                    ForEach(dayEvents) { event in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(ChartPalette.color(at: event.colorIndex).opacity(0.25))
                                .frame(width: 26, height: 26)
                                .overlay(Text(EmojiMatch.choreEmoji(event.chore.name)).font(.caption))
                            Text("\(event.chore.name) · \(memberNames[event.assignedTo] ?? "—")")
                                .font(.subheadline)
                                .foregroundStyle(RTheme.foreground)
                            Spacer()
                            if !event.isReal {
                                Text("estimado")
                                    .font(.caption2)
                                    .foregroundStyle(RTheme.mutedForeground)
                            }
                        }
                    }
                }
            }
        }
    }
}
