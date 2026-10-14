import SwiftUI

/// The app icon drawn in SwiftUI (gradient tile + house + lit door), so it
/// can be animated and reused at any size. Proportions are measured from
/// the Splash image used by LaunchScreen.storyboard, so at the same size it
/// lines up with the static launch screen.
struct RumiesMark: View {
    var size: CGFloat
    /// 0 = door as on the icon, 1 = door glowing.
    var doorGlow: Double = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .fill(RBrand.gradient)
                .overlay {
                    RadialGradient(
                        colors: [.white.opacity(0.35), .clear],
                        center: UnitPoint(x: 0.5, y: 0.4),
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.27, style: .continuous))
                }

            HouseShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#fbf7f3"), Color(hex: "#e5d8ca")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.52, height: size * 0.557)
                .offset(y: size * (0.4915 - 0.5))

            Circle()
                .fill(RBrand.door)
                .frame(width: size * 0.08, height: size * 0.08)
                .shadow(color: RBrand.door.opacity(doorGlow), radius: size * 0.08 * doorGlow)
                .brightness(0.12 * doorGlow)
                .offset(y: size * 0.089)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// House silhouette from the icon: pitched roof over a box, softly rounded.
struct HouseShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let eave = h * 0.368
        let apex = CGPoint(x: rect.midX, y: rect.minY)
        let rightEave = CGPoint(x: rect.maxX, y: rect.minY + eave)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        let leftEave = CGPoint(x: rect.minX, y: rect.minY + eave)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + eave + h * 0.1))
        path.addArc(tangent1End: leftEave, tangent2End: apex, radius: w * 0.04)
        path.addArc(tangent1End: apex, tangent2End: rightEave, radius: w * 0.05)
        path.addArc(tangent1End: rightEave, tangent2End: bottomRight, radius: w * 0.04)
        path.addArc(tangent1End: bottomRight, tangent2End: bottomLeft, radius: w * 0.05)
        path.addArc(tangent1End: bottomLeft, tangent2End: leftEave, radius: w * 0.05)
        path.closeSubpath()
        return path
    }
}

#Preview {
    RumiesMark(size: 160, doorGlow: 1)
        .padding()
        .background(RTheme.background)
}
