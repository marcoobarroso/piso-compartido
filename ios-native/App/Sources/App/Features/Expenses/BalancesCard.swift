import SwiftUI
import RumisCore

/// "Saldos y pagos pendientes" card: per-member net balance plus the
/// minimal set of suggested settle-up transactions, mirroring the
/// "Saldos del piso" / "Para saldar cuentas" sections of page.tsx and
/// settle-button.tsx's settlement action.
struct BalancesCard: View {
    let store: ExpensesStore
    let currentUserId: UUID
    let householdId: UUID

    @State private var settlingIndex: Int?
    @State private var settledTrigger = 0

    var body: some View {
        RCard(title: "Saldos y pagos pendientes", systemImage: "arrow.left.arrow.right") {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(store.members) { member in
                        let amount = store.balances.get(member.userId.uuidString) ?? 0
                        HStack(spacing: 10) {
                            Text(store.name(for: member.userId) + (member.userId == currentUserId ? " (tú)" : ""))
                                .font(.subheadline)
                                .foregroundStyle(RTheme.foreground)
                            Spacer()
                            Text(balanceLabel(amount))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(balanceColor(amount))
                        }
                    }
                }

                if !store.suggestedTransactions.isEmpty {
                    Rectangle()
                        .fill(RTheme.border)
                        .frame(height: 1)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Para saldar cuentas")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RTheme.foreground)

                        ForEach(store.suggestedTransactions.indices, id: \.self) { i in
                            let t = store.suggestedTransactions[i]
                            HStack(spacing: 10) {
                                Text("\(store.name(for: UUID(uuidString: t.from) ?? currentUserId)) debe \(Format.formatCents(t.amountCents)) a \(store.name(for: UUID(uuidString: t.to) ?? currentUserId))")
                                    .font(.footnote)
                                    .foregroundStyle(RTheme.mutedForeground)
                                Spacer(minLength: 8)
                                Button {
                                    Task { await settle(index: i, from: t.from, to: t.to, amountCents: t.amountCents) }
                                } label: {
                                    Text("Saldar")
                                }
                                .buttonStyle(.rSecondary)
                                .disabled(settlingIndex != nil)
                            }
                        }
                    }
                }
            }
        }
        .sensoryFeedback(.success, trigger: settledTrigger)
    }

    private func balanceLabel(_ amountCents: Int) -> String {
        if amountCents == 0 { return "al día" }
        if amountCents > 0 { return "le deben \(Format.formatCents(amountCents))" }
        return "debe \(Format.formatCents(-amountCents))"
    }

    private func balanceColor(_ amountCents: Int) -> Color {
        if amountCents > 0 { return RTheme.primary }
        if amountCents < 0 { return RTheme.destructive }
        return RTheme.mutedForeground
    }

    private func settle(index: Int, from: String, to: String, amountCents: Int) async {
        guard let fromId = UUID(uuidString: from), let toId = UUID(uuidString: to) else { return }
        settlingIndex = index
        let succeeded = await store.recordSettlement(fromUserId: fromId, toUserId: toId, amountCents: amountCents, householdId: householdId)
        settlingIndex = nil
        if succeeded {
            settledTrigger += 1
            ReviewPrompt.registerPositiveAction()
        }
    }
}
