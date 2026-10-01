import SwiftUI
import RumisCore

/// The description/amount/category/date/paid-by/split fields shared by the
/// add-expense card. The edit sheet intentionally reuses only the simpler
/// subset of these building blocks (see EditExpenseSheet) since the web
/// app's own edit dialog never exposes a split editor either — there the
/// split is recomputed automatically instead.
struct ExpenseFormFields: View {
    let members: [HouseholdMember]
    @Binding var description: String
    @Binding var amountText: String
    @Binding var category: ExpenseCategory
    @Binding var date: Date
    @Binding var paidBy: UUID
    @Binding var splitMode: SplitMode
    @Binding var participantIds: Set<UUID>
    @Binding var customShareText: [UUID: String]

    private var totalCents: Int { MoneyParsing.centsFromEuroString(amountText) ?? 0 }
    private var enteredCents: Int {
        members.reduce(0) { sum, m in
            sum + (MoneyParsing.centsFromEuroString(customShareText[m.userId] ?? "") ?? 0)
        }
    }
    private var remainingCents: Int { totalCents - enteredCents }

    var body: some View {
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
            LabeledField(label: "¿Quién paga?") {
                MemberPickerView(members: members, selected: $paidBy)
            }
            LabeledField(label: "¿Cómo se reparte?") {
                HStack(spacing: 8) {
                    splitModeButton(.equal, label: "Igual")
                    splitModeButton(.custom, label: "Personalizado")
                }
            }

            if splitMode == .equal {
                LabeledField(label: "¿Quién participa?") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(members) { member in
                            let isSelected = participantIds.contains(member.userId)
                            Button {
                                if isSelected {
                                    participantIds.remove(member.userId)
                                } else {
                                    participantIds.insert(member.userId)
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                        .foregroundStyle(isSelected ? RTheme.primary : RTheme.mutedForeground)
                                    Text(member.profiles?.displayName ?? "Sin nombre")
                                        .foregroundStyle(RTheme.foreground)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else {
                LabeledField(label: "¿Cuánto paga cada uno?") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(members) { member in
                            HStack {
                                Text(member.profiles?.displayName ?? "Sin nombre")
                                    .font(.subheadline)
                                    .foregroundStyle(RTheme.foreground)
                                Spacer()
                                TextField("0,00", text: Binding(
                                    get: { customShareText[member.userId] ?? "" },
                                    set: { customShareText[member.userId] = $0 }
                                ))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 90)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(RTheme.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: RTheme.Radius.sm))
                                .foregroundStyle(RTheme.foreground)
                            }
                        }
                        Text(remainingText)
                            .font(.caption)
                            .foregroundStyle(remainingCents == 0 && totalCents > 0 ? RTheme.mutedForeground : RTheme.destructive)
                    }
                }
            }
        }
    }

    private var remainingText: String {
        if totalCents == 0 { return "Pon primero el importe total." }
        if remainingCents == 0 { return "Cuadra con el importe total." }
        if remainingCents > 0 { return "Faltan \(Format.formatCents(remainingCents)) por repartir." }
        return "Sobran \(Format.formatCents(-remainingCents)) repartidos de más."
    }

    @ViewBuilder
    private func splitModeButton(_ mode: SplitMode, label: String) -> some View {
        Button {
            splitMode = mode
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(splitMode == mode ? RTheme.primary.opacity(0.15) : RTheme.secondary)
                .foregroundStyle(splitMode == mode ? RTheme.primary : RTheme.mutedForeground)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(splitMode == mode ? RTheme.primary : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
