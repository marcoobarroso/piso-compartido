import SwiftUI
import Charts
import RumisCore

/// Mirrors app/household/stats/page.tsx: headline tiles + four charts built
/// from the same three fetches (expenses, chore assignments, members),
/// computed client-side instead of with per-chart Supabase queries. Unlike
/// the web page (which scopes the bar-row charts to the current month),
/// "Quién ha pagado más", "Gasto por categoría" and "Tareas completadas"
/// here are all-time aggregates, per this rewrite's spec.
struct StatsView: View {
    @Environment(AppSession.self) private var session

    @State private var expenses: [Expense] = []
    @State private var assignments: [ChoreAssignment] = []
    @State private var members: [HouseholdMember] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private static let monthLabels = [
        "ene", "feb", "mar", "abr", "may", "jun",
        "jul", "ago", "sep", "oct", "nov", "dic",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(RTheme.destructive)
                }

                if isLoading {
                    ProgressView()
                        .tint(RTheme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    HStack(spacing: 12) {
                        StatTile(label: "Gastado este mes", value: Format.formatCents(totalThisMonthCents))
                        StatTile(
                            label: "Total del piso",
                            value: Format.formatCents(totalAllTimeCents),
                            tint: ChartPalette.color(at: 1)
                        )
                    }

                    RCard(title: "Gasto mensual", systemImage: "chart.bar.fill", description: "Últimos 6 meses") {
                        if monthlyBuckets.allSatisfy({ $0.cents == 0 }) {
                            EmptyChartPlaceholder()
                        } else {
                            monthlyChart
                        }
                    }

                    RCard(title: "Quién ha pagado más", systemImage: "banknote.fill") {
                        if paidByRows.isEmpty {
                            EmptyChartPlaceholder()
                        } else {
                            barRowChart(rows: paidByRows.map { ($0.name, Double($0.cents) / 100, Format.formatCents($0.cents)) })
                        }
                    }

                    RCard(title: "Gasto por categoría", systemImage: "tag.fill") {
                        if categoryRows.isEmpty {
                            EmptyChartPlaceholder()
                        } else {
                            categoryChart
                        }
                    }

                    RCard(title: "Tareas completadas", systemImage: "checkmark.circle.fill") {
                        if choreRows.isEmpty {
                            EmptyChartPlaceholder()
                        } else {
                            barRowChart(rows: choreRows.map { ($0.name, Double($0.count), String($0.count)) })
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(RTheme.background.ignoresSafeArea())
        .navigationTitle("Estadísticas")
        .task {
            guard isLoading, let householdId = session.household?.id else { return }
            do {
                async let expensesTask = ExpensesRepository().fetchExpenses(householdId: householdId)
                async let assignmentsTask = ChoresRepository().fetchAssignments(householdId: householdId)
                async let membersTask = HouseholdRepository().fetchMembers(householdId: householdId)
                let (fetchedExpenses, fetchedAssignments, fetchedMembers) = try await (expensesTask, assignmentsTask, membersTask)
                expenses = fetchedExpenses
                assignments = fetchedAssignments
                members = fetchedMembers
            } catch {
                errorMessage = "No se pudieron cargar las estadísticas."
            }
            isLoading = false
        }
    }

    // MARK: - Charts

    private var monthlyChart: some View {
        Chart(monthlyBuckets) { bucket in
            BarMark(
                x: .value("Mes", bucket.label),
                y: .value("Total", Double(bucket.cents) / 100)
            )
            .foregroundStyle(RTheme.primary)
            .cornerRadius(4)
            .annotation(position: .top) {
                if bucket.cents > 0 {
                    Text(Format.formatCents(bucket.cents))
                        .font(.caption2)
                        .foregroundStyle(RTheme.mutedForeground)
                }
            }
        }
        .chartYScale(domain: 0...(Double(max(monthlyMaxCents, 100)) / 100 * 1.3))
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(RTheme.mutedForeground)
            }
        }
        .frame(height: 180)
    }

    private var categoryChart: some View {
        Chart {
            ForEach(Array(categoryRows.enumerated()), id: \.offset) { _, row in
                BarMark(
                    x: .value("Total", Double(row.cents) / 100),
                    y: .value("Categoría", row.category.label)
                )
                .foregroundStyle(row.category.color)
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text(Format.formatCents(row.cents))
                        .font(.caption2)
                        .foregroundStyle(RTheme.mutedForeground)
                }
            }
        }
        .chartXScale(domain: 0...(Double(max(categoryMaxCents, 100)) / 100 * 1.35))
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(RTheme.cardForeground)
            }
        }
        .chartPlotStyle { $0.padding(.trailing, 46) }
        .frame(height: CGFloat(categoryRows.count) * 38 + 8)
    }

    /// Shared horizontal bar-row renderer for "Quién ha pagado más" and
    /// "Tareas completadas": (label, plotted value, formatted trailing text).
    private func barRowChart(rows: [(name: String, value: Double, formatted: String)]) -> some View {
        let maxValue = rows.map(\.value).max() ?? 0
        return Chart {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                BarMark(
                    x: .value("Total", row.value),
                    y: .value("Persona", row.name)
                )
                .foregroundStyle(ChartPalette.color(at: index))
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text(row.formatted)
                        .font(.caption2)
                        .foregroundStyle(RTheme.mutedForeground)
                }
            }
        }
        .chartXScale(domain: 0...(max(maxValue, 1) * 1.35))
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(RTheme.cardForeground)
            }
        }
        .chartPlotStyle { $0.padding(.trailing, 46) }
        .frame(height: CGFloat(rows.count) * 38 + 8)
    }

    // MARK: - Aggregation

    private var totalThisMonthCents: Int {
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.year, .month], from: Date())
        return expenses.reduce(0) { sum, expense in
            guard let date = Format.parseDateOnly(expense.expenseDate) else { return sum }
            let components = calendar.dateComponents([.year, .month], from: date)
            guard components.year == nowComponents.year, components.month == nowComponents.month else { return sum }
            return sum + expense.amountCents
        }
    }

    private var totalAllTimeCents: Int {
        expenses.reduce(0) { $0 + $1.amountCents }
    }

    private struct MonthBucket: Identifiable {
        let id = UUID()
        let year: Int
        let month: Int
        let label: String
        var cents: Int
    }

    private var monthlyBuckets: [MonthBucket] {
        let calendar = Calendar.current
        let now = Date()
        var buckets: [MonthBucket] = (0..<6).compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -(5 - offset), to: now) else { return nil }
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let year = components.year, let month = components.month else { return nil }
            return MonthBucket(year: year, month: month, label: Self.monthLabels[month - 1], cents: 0)
        }

        for expense in expenses {
            guard let date = Format.parseDateOnly(expense.expenseDate) else { continue }
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let year = components.year, let month = components.month else { continue }
            if let index = buckets.firstIndex(where: { $0.year == year && $0.month == month }) {
                buckets[index].cents += expense.amountCents
            }
        }

        return buckets
    }

    private var monthlyMaxCents: Int {
        monthlyBuckets.map(\.cents).max() ?? 0
    }

    private struct NamedAmount {
        let name: String
        let cents: Int
    }

    private var paidByRows: [NamedAmount] {
        var totals: [UUID: Int] = [:]
        for expense in expenses {
            totals[expense.paidBy, default: 0] += expense.amountCents
        }
        return totals
            .map { NamedAmount(name: memberName(for: $0.key), cents: $0.value) }
            .sorted { $0.cents > $1.cents }
    }

    private struct CategoryAmount {
        let category: ExpenseCategory
        let cents: Int
    }

    private var categoryRows: [CategoryAmount] {
        // Keyed by rawValue (String) rather than the enum itself, since
        // ExpenseCategory doesn't explicitly declare Hashable.
        var totals: [String: Int] = [:]
        for expense in expenses {
            totals[expense.category.rawValue, default: 0] += expense.amountCents
        }
        return ExpenseCategory.allCases
            .map { CategoryAmount(category: $0, cents: totals[$0.rawValue] ?? 0) }
            .filter { $0.cents > 0 }
            .sorted { $0.cents > $1.cents }
    }

    private var categoryMaxCents: Int {
        categoryRows.map(\.cents).max() ?? 0
    }

    private struct NamedCount {
        let name: String
        let count: Int
    }

    private var choreRows: [NamedCount] {
        var counts: [UUID: Int] = [:]
        for assignment in assignments where assignment.status == "done" {
            counts[assignment.assignedTo, default: 0] += 1
        }
        return counts
            .map { NamedCount(name: memberName(for: $0.key), count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private func memberName(for userId: UUID) -> String {
        guard let member = members.first(where: { $0.userId == userId }) else { return "Alguien" }
        return member.profiles?.displayName ?? "Sin nombre"
    }
}

private struct EmptyChartPlaceholder: View {
    var body: some View {
        Text("Todavía no hay datos")
            .font(.subheadline)
            .foregroundStyle(RTheme.mutedForeground)
            .frame(maxWidth: .infinity, minHeight: 80)
    }
}
