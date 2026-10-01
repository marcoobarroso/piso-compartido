import SwiftUI
import RumisCore

/// Last 30 completed assignments, most recent first. Mirrors the
/// "Historial" tab in app/household/chores/page.tsx.
struct ChoresHistoryTab: View {
    let chores: [Chore]
    let assignments: [ChoreAssignment]
    let memberNames: [UUID: String]

    private struct HistoryRow: Identifiable {
        let id: UUID
        let choreName: String
        let completedByName: String
        let completedAt: Date
        let lateDays: Int
    }

    private var rows: [HistoryRow] {
        let mapped: [HistoryRow] = assignments
            .filter { $0.status == "done" }
            .compactMap { assignment in
                guard let completedAt = assignment.completedAt else { return nil }
                let choreName = chores.first { $0.id == assignment.choreId }?.name ?? ""
                let completedByName = assignment.completedBy.flatMap { memberNames[$0] } ?? "—"
                let late = Format.daysLate(dueDateStr: assignment.dueDate, completedAt: completedAt)
                return HistoryRow(
                    id: assignment.id,
                    choreName: choreName,
                    completedByName: completedByName,
                    completedAt: completedAt,
                    lateDays: late
                )
            }
            .sorted { $0.completedAt > $1.completedAt }
        return Array(mapped.prefix(30))
    }

    private var onTimeCount: Int { rows.filter { $0.lateDays <= 0 }.count }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.setLocalizedDateFormatFromTemplate("d MMM")
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if rows.isEmpty {
                emptyState
            } else {
                Text("\(onTimeCount) de \(rows.count) a tiempo")
                    .font(.caption)
                    .foregroundStyle(RTheme.mutedForeground)

                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    historyRow(row)
                    if index != rows.count - 1 {
                        Rectangle()
                            .fill(RTheme.border)
                            .frame(height: 1)
                    }
                }
            }
        }
    }

    private func historyRow(_ row: HistoryRow) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(EmojiMatch.choreEmoji(row.choreName))
                .font(.system(size: 16))
                .frame(width: 32, height: 32)
                .background(RTheme.accent)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(row.choreName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RTheme.foreground)
                Text("\(row.completedByName) · \(Self.dateFormatter.string(from: row.completedAt))")
                    .font(.caption)
                    .foregroundStyle(RTheme.mutedForeground)
            }

            Spacer()

            if row.lateDays > 0 {
                RBadge(
                    text: "Con \(row.lateDays) día\(row.lateDays == 1 ? "" : "s") de retraso",
                    tint: RTheme.destructive,
                    background: RTheme.destructive.opacity(0.15)
                )
            } else {
                RBadge(text: "A tiempo")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.title2)
                .foregroundStyle(RTheme.mutedForeground.opacity(0.5))
            Text("Todavía no se ha completado ninguna tarea.")
                .font(.subheadline)
                .foregroundStyle(RTheme.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}
