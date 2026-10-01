import SwiftUI

/// Card container matching the web design system's ui/card.tsx: icon chip +
/// title + description + content, used as the dominant layout block on
/// every screen.
struct RCard<Content: View>: View {
    var title: String? = nil
    var systemImage: String? = nil
    var description: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if title != nil || systemImage != nil {
                HStack(spacing: 10) {
                    if let systemImage {
                        ZStack {
                            RoundedRectangle(cornerRadius: RTheme.Radius.sm)
                                .fill(RTheme.accent)
                            Image(systemName: systemImage)
                                .foregroundStyle(RTheme.accentForeground)
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(width: 32, height: 32)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        if let title {
                            Text(title)
                                .font(.headline)
                                .foregroundStyle(RTheme.cardForeground)
                        }
                        if let description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(RTheme.mutedForeground)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            content
        }
        .padding(16)
        .background(RTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: RTheme.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: RTheme.Radius.lg)
                .strokeBorder(RTheme.border, lineWidth: 1)
        )
    }
}

struct StatTile: View {
    let label: String
    let value: String
    var tint: Color = RTheme.primary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(RTheme.mutedForeground)
            Text(value)
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: RTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RTheme.Radius.md)
                .strokeBorder(RTheme.border, lineWidth: 1)
        )
    }
}

struct RBadge: View {
    let text: String
    var tint: Color = RTheme.mutedForeground
    var background: Color = RTheme.muted

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(background)
            .clipShape(Capsule())
    }
}
