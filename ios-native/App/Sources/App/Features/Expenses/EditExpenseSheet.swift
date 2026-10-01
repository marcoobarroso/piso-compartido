import SwiftUI
import RumisCore

/// Edit dialog for an existing expense. Like the web app's own edit dialog
/// (expense-row-actions.tsx), it only exposes description/amount/category/
/// date/paid-by — the split isn't re-edited by hand. On save the split is
/// recomputed automatically: an originally-equal split is re-run through
/// splitEqually with the new amount and same participants; an
/// originally-custom split is rescaled proportionally via scaleShares when
/// the amount changed, or left untouched when it didn't.
struct EditExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss

    let store: ExpensesStore
    let expense: Expense
    let householdId: UUID

    @State private var description: String
    @State private var amountText: String
    @State private var category: ExpenseCategory
    @State private var date: Date
    @State private var paidBy: UUID
    @State private var isSaving = false

    private let oldShares: [ExpenseShareInput]
    private let participantIds: Set<UUID>
    private let looksEqual: Bool

    init(store: ExpensesStore, expense: Expense, householdId: UUID) {
        self.store = store
        self.expense = expense
        self.householdId = householdId

        let shares = store.sharesForExpense(expense.id)
        let shareInputs = shares.map { ExpenseShareInput(userId: $0.userId.uuidString, shareCents: $0.shareCents) }
        self.oldShares = shareInputs

        let ids = Set(shares.map { $0.userId })
        self.participantIds = ids

        // Guard against dividing by zero participants (shouldn't happen —
        // addExpense always requires at least one share — but this runs at
        // sheet-open time, so it's worth not trusting that invariant here).
        if ids.isEmpty {
            self.looksEqual = false
        } else {
            let sortedOld = shareInputs.sorted { $0.userId < $1.userId }
            let equalCandidate = DebtSimplify
                .splitEqually(amountCents: expense.amountCents, userIds: ids.map { $0.uuidString })
                .sorted { $0.userId < $1.userId }
            self.looksEqual = sortedOld == equalCandidate
        }

        _description = State(initialValue: expense.description)
        _amountText = State(initialValue: MoneyParsing.euroString(fromCents: expense.amountCents))
        _category = State(initialValue: expense.category)
        _date = State(initialValue: Format.parseDateOnly(expense.expenseDate) ?? Date())
        _paidBy = State(initialValue: expense.paidBy)
    }

    private var isValid: Bool {
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        (MoneyParsing.centsFromEuroString(amountText) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    LabeledField(label: "Descripción") {
                        RTextField(title: "Compra Mercadona", text: $description)
                    }
                    LabeledField(label: "Importe (€)") {
                        RTextField(title: "24,50", text: $amountText, keyboardType: .decimalPad)
                    }
                    LabeledField(label: "Categoría") {
                        CategoryPickerView(selected: $category)
                    }
                    LabeledField(label: "Fecha") {
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(RTheme.primary)
                    }
                    LabeledField(label: "¿Quién pagó?") {
                        MemberPickerView(members: store.members, selected: $paidBy)
                    }
                    Text("El reparto se ajusta automáticamente entre las mismas personas.")
                        .font(.caption)
                        .foregroundStyle(RTheme.mutedForeground)
                }
                .padding(16)
            }
            .background(RTheme.background)
            .navigationTitle("Editar gasto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Guardando..." : "Guardar") {
                        Task { await submit() }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }

    private func submit() async {
        guard let newTotalCents = MoneyParsing.centsFromEuroString(amountText), newTotalCents > 0 else { return }
        isSaving = true

        let shares: [ExpenseShareInput]
        if participantIds.isEmpty {
            // No shares to recompute from — leave as-is rather than risk
            // dividing by zero participants.
            shares = oldShares
        } else if looksEqual {
            shares = DebtSimplify.splitEqually(amountCents: newTotalCents, userIds: participantIds.map { $0.uuidString })
        } else if newTotalCents != expense.amountCents {
            shares = DebtSimplify.scaleShares(shares: oldShares, newTotalCents: newTotalCents)
        } else {
            shares = oldShares
        }

        let fields = ExpenseFieldsUpdate(
            paidBy: paidBy,
            description: description.trimmingCharacters(in: .whitespaces),
            amountCents: newTotalCents,
            category: category,
            expenseDate: Format.dateOnlyString(from: date)
        )

        let success = await store.updateExpense(id: expense.id, fields: fields, shares: shares, householdId: householdId)
        isSaving = false
        if success { dismiss() }
    }
}
