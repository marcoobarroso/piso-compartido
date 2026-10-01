import SwiftUI
import RumisCore

/// "Historial de liquidaciones" card: past settlements, newest first
/// (already sorted by the repo), each undoable — mirrors
/// settlement-history.tsx.
struct SettlementHistoryCard: View {
    let store: ExpensesStore
    let householdId: UUID

    @State private var pendingDeleteId: UUID?

    var body: some View {
        RCard(title: "Historial de liquidaciones", systemImage: "clock.arrow.circlepath") {
            if store.settlements.isEmpty {
                Text("Todavía no hay pagos registrados.")
                    .font(.subheadline)
                    .foregroundStyle(RTheme.mutedForeground)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(store.settlements) { settlement in
                        HStack(spacing: 10) {
                            Text("\(store.name(for: settlement.fromUserId)) pagó \(Format.formatCents(settlement.amountCents)) a \(store.name(for: settlement.toUserId))")
                                .font(.footnote)
                                .foregroundStyle(RTheme.foreground)
                            Spacer()
                            Button {
                                pendingDeleteId = settlement.id
                            } label: {
                                Image(systemName: "arrow.uturn.backward.circle")
                                    .foregroundStyle(RTheme.mutedForeground)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Deshacer pago")
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            "¿Deshacer este pago?",
            isPresented: Binding(
                get: { pendingDeleteId != nil },
                set: { isPresented in if !isPresented { pendingDeleteId = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Deshacer pago", role: .destructive) {
                if let id = pendingDeleteId {
                    Task { await store.deleteSettlement(id: id, householdId: householdId) }
                }
                pendingDeleteId = nil
            }
            Button("Cancelar", role: .cancel) { pendingDeleteId = nil }
        } message: {
            Text("Se ajustará el saldo del piso.")
        }
    }
}
