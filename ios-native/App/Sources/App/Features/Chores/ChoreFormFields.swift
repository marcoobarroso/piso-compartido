import SwiftUI
import RumisCore

/// Shared fields for the add-chore card and the edit-chore sheet: name (with
/// a live emoji preview), optional description, a recurrence-in-days
/// stepper, and a tap-to-toggle member picker that also records selection
/// order — that order becomes the chore's rotation order.
struct ChoreFormFields: View {
    @Binding var name: String
    @Binding var description: String
    @Binding var recurrenceDays: Int
    @Binding var rotationOrder: [UUID]
    let members: [HouseholdMember]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(EmojiMatch.choreEmoji(name))
                    .font(.title2)
                    .frame(width: 34, height: 34)
                    .background(RTheme.accent)
                    .clipShape(Circle())
                RTextField(title: "Tarea (ej. Sacar la basura)", text: $name)
            }

            RTextField(title: "Descripción (opcional)", text: $description)

            Stepper(value: $recurrenceDays, in: 1...365) {
                Text("Cada \(recurrenceDays) día\(recurrenceDays == 1 ? "" : "s")")
                    .foregroundStyle(RTheme.foreground)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("¿Quién entra en la rotación?")
                    .font(.subheadline)
                    .foregroundStyle(RTheme.mutedForeground)

                if members.isEmpty {
                    Text("No hay compañeros en este piso todavía.")
                        .font(.footnote)
                        .foregroundStyle(RTheme.mutedForeground)
                } else {
                    VStack(spacing: 8) {
                        ForEach(members) { member in
                            memberRow(member)
                        }
                    }

                    if !rotationOrder.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(Array(rotationOrder.enumerated()), id: \.element) { index, id in
                                    RBadge(
                                        text: "\(index + 1). \(displayName(for: id))",
                                        tint: RTheme.primary,
                                        background: RTheme.primary.opacity(0.15)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func displayName(for userId: UUID) -> String {
        members.first { $0.userId == userId }?.profiles?.displayName ?? "Sin nombre"
    }

    private func memberRow(_ member: HouseholdMember) -> some View {
        let position = rotationOrder.firstIndex(of: member.userId)
        return Button {
            if let position {
                rotationOrder.remove(at: position)
            } else {
                rotationOrder.append(member.userId)
            }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(position != nil ? RTheme.primary : RTheme.secondary)
                    if let position {
                        Text("\(position + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RTheme.primaryForeground)
                    }
                }
                .frame(width: 24, height: 24)

                Text(member.profiles?.displayName ?? "Sin nombre")
                    .foregroundStyle(RTheme.foreground)

                Spacer()

                if position != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(RTheme.primary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(RTheme.secondary.opacity(position != nil ? 1 : 0.4))
            .clipShape(RoundedRectangle(cornerRadius: RTheme.Radius.sm))
        }
        .buttonStyle(.plain)
    }
}
