import SwiftUI

/// Small "caption label above content" wrapper used across the expense
/// forms (add/edit/recurring) to keep field layout consistent without
/// repeating the same VStack boilerplate in every form.
struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(RTheme.mutedForeground)
            content
        }
    }
}
