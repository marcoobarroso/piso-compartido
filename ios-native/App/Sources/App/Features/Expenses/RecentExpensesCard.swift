import SwiftUI
import RumisCore

/// "Gastos recientes" card: newest-first expense list (already sorted by
/// the repo), tap to edit, trash to delete, plus the Excel export action in
/// the header (mirrors CardAction + ExportButton in page.tsx).
struct RecentExpensesCard: View {
    let store: ExpensesStore
    let householdId: UUID
    let onEdit: (Expense) -> Void
    let onExport: () -> Void
    let isExporting: Bool
    let exportError: String?

    @State private var pendingDeleteId: UUID?

    var body: some View {
        RCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Gastos recientes")
                        .font(.headline)
                        .foregroundStyle(RTheme.cardForeground)
                    Spacer()
                    Button {
                        onExport()
                    } label: {
                        if isExporting {
                            ProgressView()
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .disabled(isExporting)
                    .accessibilityLabel("Exportar a Excel")
                }

                if let exportError {
                    Text(exportError)
                        .font(.caption)
                        .foregroundStyle(RTheme.destructive)
                }

                if store.expenses.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "receipt")
                            .font(.title2)
                            .foregroundStyle(RTheme.mutedForeground.opacity(0.5))
                        Text("Todavía no hay gastos. Añade el primero arriba.")
                            .font(.subheadline)
                            .foregroundStyle(RTheme.mutedForeground)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(store.expenses) { expense in
                            expenseRow(expense)
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            "¿Borrar este gasto?",
            isPresented: Binding(
                get: { pendingDeleteId != nil },
                set: { isPresented in if !isPresented { pendingDeleteId = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Borrar", role: .destructive) {
                if let id = pendingDeleteId {
                    Task { await store.deleteExpense(id: id, householdId: householdId) }
                }
                pendingDeleteId = nil
            }
            Button("Cancelar", role: .cancel) { pendingDeleteId = nil }
        } message: {
            Text("No se puede deshacer.")
        }
    }

    @ViewBuilder
    private func expenseRow(_ expense: Expense) -> some View {
        HStack(spacing: 10) {
            Button {
                onEdit(expense)
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(expense.category.color.opacity(0.18))
                        Image(systemName: expense.category.systemImage)
                            .foregroundStyle(expense.category.color)
                            .font(.footnote)
                    }
                    .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(expense.description)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RTheme.foreground)
                        Text("Pagó \(store.name(for: expense.paidBy)) · \(Format.formatDate(expense.expenseDate))")
                            .font(.caption)
                            .foregroundStyle(RTheme.mutedForeground)
                    }

                    Spacer()

                    Text(Format.formatCents(expense.amountCents))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RTheme.foreground)
                }
            }
            .buttonStyle(.plain)

            Button {
                pendingDeleteId = expense.id
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(RTheme.mutedForeground)
                    .font(.footnote)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Borrar \(expense.description)")
        }
    }
}
