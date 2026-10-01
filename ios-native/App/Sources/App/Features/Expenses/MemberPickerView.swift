import SwiftUI

/// Horizontal pill row to pick a single household member (e.g. "who paid"),
/// matching the payer picker in recurring-expenses.tsx.
struct MemberPickerView: View {
    let members: [HouseholdMember]
    @Binding var selected: UUID

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(members) { member in
                    let isSelected = selected == member.userId
                    Button {
                        selected = member.userId
                    } label: {
                        Text(member.profiles?.displayName ?? "Sin nombre")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? RTheme.primary.opacity(0.15) : RTheme.secondary)
                            .foregroundStyle(isSelected ? RTheme.primary : RTheme.mutedForeground)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().strokeBorder(isSelected ? RTheme.primary : .clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
