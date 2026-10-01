import SwiftUI
import RumisCore

/// "Añadir gasto" card: the household's primary entry point for logging a
/// new expense, split either equally among chosen participants or by exact
/// per-person amounts. Mirrors add-expense-form.tsx.
struct AddExpenseCard: View {
    let store: ExpensesStore
    let householdId: UUID
    let userId: UUID

    @State private var description = ""
    @State private var amountText = ""
    @State private var category: ExpenseCategory = .otros
    @State private var date = Date()
    @State private var paidBy: UUID
    @State private var splitMode: SplitMode = .equal
    @State private var participantIds: Set<UUID>
    @State private var customShareText: [UUID: String] = [:]
    @State private var isSaving = false

    init(store: ExpensesStore, householdId: UUID, userId: UUID) {
        self.store = store
        self.householdId = householdId
        self.userId = userId
        _paidBy = State(initialValue: userId)
        _participantIds = State(initialValue: Set(store.members.map { $0.userId }))
    }

    private var isValid: Bool {
        ExpenseFormValidation.isValid(
            description: description,
            amountText: amountText,
            splitMode: splitMode,
            participantIds: participantIds,
            customShareText: customShareText,
            members: store.members
        )
    }

    var body: some View {
        RCard(title: "Añadir gasto", systemImage: "receipt", description: "A partes iguales o por importes exactos") {
            VStack(alignment: .leading, spacing: 14) {
                ExpenseFormFields(
                    members: store.members,
                    description: $description,
                    amountText: $amountText,
                    category: $category,
                    date: $date,
                    paidBy: $paidBy,
                    splitMode: $splitMode,
                    participantIds: $participantIds,
                    customShareText: $customShareText
                )

                Button {
                    Task { await submit() }
                } label: {
                    Text(isSaving ? "Guardando..." : "Añadir gasto")
                }
                .buttonStyle(.rPrimary)
                .disabled(!isValid || isSaving)
            }
        }
        .onChange(of: store.members.count) { _, _ in
            if participantIds.isEmpty {
                participantIds = Set(store.members.map { $0.userId })
            }
        }
    }

    private func submit() async {
        guard let totalCents = MoneyParsing.centsFromEuroString(amountText), totalCents > 0 else { return }
        isSaving = true

        let shares = ExpenseFormValidation.buildShares(
            splitMode: splitMode,
            totalCents: totalCents,
            participantIds: participantIds,
            customShareText: customShareText,
            members: store.members
        )

        let insert = ExpenseInsert(
            householdId: householdId,
            paidBy: paidBy,
            description: description.trimmingCharacters(in: .whitespaces),
            amountCents: totalCents,
            category: category,
            expenseDate: ExpenseDateFormat.string(from: date),
            createdBy: userId
        )

        let success = await store.addExpense(insert, shares: shares, householdId: householdId)
        isSaving = false

        if success {
            description = ""
            amountText = ""
            category = .otros
            date = Date()
            paidBy = userId
            splitMode = .equal
            participantIds = Set(store.members.map { $0.userId })
            customShareText = [:]
        }
    }
}
