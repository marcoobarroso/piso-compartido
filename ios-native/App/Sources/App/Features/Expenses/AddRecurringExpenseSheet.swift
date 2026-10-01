import SwiftUI
import RumisCore

/// Sheet to create a new recurring expense (rent, utilities...) that
/// generates itself every month. Mirrors the bottom form in
/// recurring-expenses.tsx.
struct AddRecurringExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss

    let store: ExpensesStore
    let householdId: UUID
    let userId: UUID

    @State private var description = ""
    @State private var amountText = ""
    @State private var category: ExpenseCategory = .otros
    @State private var dayOfMonth = 1
    @State private var paidBy: UUID
    @State private var isSaving = false

    init(store: ExpensesStore, householdId: UUID, userId: UUID) {
        self.store = store
        self.householdId = householdId
        self.userId = userId
        _paidBy = State(initialValue: userId)
    }

    private var isValid: Bool {
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        (MoneyParsing.centsFromEuroString(amountText) ?? 0) > 0 &&
        (1...28).contains(dayOfMonth)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    LabeledField(label: "Descripción") {
                        RTextField(title: "Alquiler", text: $description)
                    }
                    LabeledField(label: "Importe (€)") {
                        RTextField(title: "450", text: $amountText, keyboardType: .decimalPad)
                    }
                    LabeledField(label: "Categoría") {
                        CategoryPickerView(selected: $category)
                    }
                    LabeledField(label: "Día del mes (1-28)") {
                        Stepper(value: $dayOfMonth, in: 1...28) {
                            Text("Día \(dayOfMonth)")
                                .foregroundStyle(RTheme.foreground)
                        }
                    }
                    LabeledField(label: "¿Quién lo paga?") {
                        MemberPickerView(members: store.members, selected: $paidBy)
                    }
                }
                .padding(16)
            }
            .background(RTheme.background)
            .navigationTitle("Gasto fijo")
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
        guard let cents = MoneyParsing.centsFromEuroString(amountText), cents > 0 else { return }
        isSaving = true
        let insert = RecurringExpenseInsert(
            householdId: householdId,
            description: description.trimmingCharacters(in: .whitespaces),
            amountCents: cents,
            category: category,
            dayOfMonth: dayOfMonth,
            paidBy: paidBy,
            createdBy: userId
        )
        let success = await store.addRecurringExpense(insert, householdId: householdId)
        isSaving = false
        if success { dismiss() }
    }
}
