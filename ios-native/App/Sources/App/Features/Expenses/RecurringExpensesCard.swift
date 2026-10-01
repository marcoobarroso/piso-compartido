import SwiftUI
import RumisCore

/// "Gastos fijos" card: recurring expenses (rent, wifi, electricity...)
/// that generate themselves monthly. Mirrors recurring-expenses.tsx.
struct RecurringExpensesCard: View {
    let store: ExpensesStore
    let householdId: UUID
    let userId: UUID

    @State private var showingAddSheet = false
    @State private var pendingDeleteId: UUID?
    @State private var isGenerating = false

    var body: some View {
        RCard(title: "Gastos fijos", systemImage: "repeat", description: "Alquiler, wifi, luz... se crean solos cada mes") {
            VStack(alignment: .leading, spacing: 12) {
                if store.recurring.isEmpty {
                    Text("Todavía no hay gastos fijos.")
                        .font(.subheadline)
                        .foregroundStyle(RTheme.mutedForeground)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(store.recurring) { r in
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle().fill(r.category.color.opacity(0.18))
                                    Image(systemName: r.category.systemImage)
                                        .foregroundStyle(r.category.color)
                                        .font(.footnote)
                                }
                                .frame(width: 32, height: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.description)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(r.active ? RTheme.foreground : RTheme.mutedForeground)
                                        .strikethrough(!r.active)
                                    Text("día \(r.dayOfMonth) · paga \(store.name(for: r.paidBy))")
                                        .font(.caption)
                                        .foregroundStyle(RTheme.mutedForeground)
                                }

                                Spacer()

                                Text(Format.formatCents(r.amountCents))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(RTheme.foreground)

                                Toggle("", isOn: Binding(
                                    get: { r.active },
                                    set: { newValue in
                                        Task { await store.toggleRecurringExpense(id: r.id, active: newValue, householdId: householdId) }
                                    }
                                ))
                                .labelsHidden()
                                .tint(RTheme.primary)
                                .accessibilityLabel(r.active ? "Activo" : "Pausado")

                                Button {
                                    pendingDeleteId = r.id
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(RTheme.mutedForeground)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Borrar \(r.description)")
                            }
                        }
                    }

                    Button {
                        Task {
                            isGenerating = true
                            _ = await store.generateRecurringNow(householdId: householdId)
                            isGenerating = false
                        }
                    } label: {
                        Label(isGenerating ? "Generando..." : "Generar ahora", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.rSecondary)
                    .disabled(isGenerating)
                }

                Button {
                    showingAddSheet = true
                } label: {
                    Label("Añadir gasto fijo", systemImage: "plus")
                }
                .buttonStyle(.rSecondary)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddRecurringExpenseSheet(store: store, householdId: householdId, userId: userId)
        }
        .confirmationDialog(
            "¿Borrar este gasto fijo?",
            isPresented: Binding(
                get: { pendingDeleteId != nil },
                set: { isPresented in if !isPresented { pendingDeleteId = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Borrar", role: .destructive) {
                if let id = pendingDeleteId {
                    Task { await store.deleteRecurringExpense(id: id, householdId: householdId) }
                }
                pendingDeleteId = nil
            }
            Button("Cancelar", role: .cancel) { pendingDeleteId = nil }
        } message: {
            Text("No se generará más este gasto.")
        }
    }
}
