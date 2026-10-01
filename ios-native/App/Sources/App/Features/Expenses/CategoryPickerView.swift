import SwiftUI
import RumisCore

/// Pill grid over all ExpenseCategory cases, matching
/// components/category-picker.tsx's look with SF Symbols instead of
/// lucide-react icons.
struct CategoryPickerView: View {
    @Binding var selected: ExpenseCategory

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                Button {
                    selected = category
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: category.systemImage)
                        Text(category.label)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .font(.footnote.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(selected == category ? category.color.opacity(0.22) : RTheme.secondary)
                    .foregroundStyle(selected == category ? category.color : RTheme.mutedForeground)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(selected == category ? category.color : .clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
