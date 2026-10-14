import SwiftUI

extension EnvironmentValues {
    /// True while ContentView's launch splash covers the app, so screens
    /// underneath can hold their entrance animations until it lifts.
    @Entry var isSplashVisible = false
}

/// Animated intro shown over ContentView on cold launch. Its first frame is
/// LaunchScreen.storyboard's own Splash image, with the SwiftUI mark drawn
/// at the same size and spot underneath, so the static launch screen hands
/// off without a visible jump. Then the mark dips and springs up, the door
/// lights and the wordmark writes itself in. It stays up until both the
/// intro has played and `isReady` (the session resolved its first route),
/// showing a small loader if the session is slower than the intro.
struct SplashView: View {
    let isReady: Bool
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var launchImageOpacity = 1.0
    @State private var markScale = 1.0
    @State private var lifted = false
    @State private var doorLit = false
    @State private var ripple = false
    @State private var lettersShown = 0
    @State private var taglineShown = false
    @State private var introDone = false
    @State private var finished = false
    /// Mirror of `isReady`: the intro task outlives the view value it was
    /// started from, so it must read readiness from state, not the prop.
    @State private var readySeen = false

    private static let wordmark = Array("Rumies")

    var body: some View {
        GeometryReader { geo in
            // The launch image is a square scaled to fill, so its side is the
            // screen's longest edge; the icon is 17.86% of that side.
            let side = max(geo.size.width, geo.size.height)
            let markSize = side * 0.1786

            ZStack {
                background

                Circle()
                    .fill(RTheme.primary)
                    .frame(width: markSize * 1.6, height: markSize * 1.6)
                    .blur(radius: markSize * 0.6)
                    .opacity(doorLit ? 0.28 : 0)
                    .offset(y: lifted ? -markSize * 0.55 : 0)

                RumiesMark(size: markSize, doorGlow: doorLit ? 1 : 0)
                    .overlay {
                        Circle()
                            .stroke(RBrand.door, lineWidth: 2)
                            .frame(width: markSize * 0.08, height: markSize * 0.08)
                            .scaleEffect(ripple ? 9 : 1)
                            .opacity(ripple ? 0 : (doorLit ? 0.9 : 0))
                            .offset(y: markSize * 0.089)
                    }
                    .shadow(color: .black.opacity(0.45), radius: 24, y: 12)
                    .scaleEffect(markScale * (lifted ? 0.66 : 1))
                    .offset(y: lifted ? -markSize * 0.55 : 0)

                VStack(spacing: 10) {
                    wordmarkView
                    Text("Gastos, tareas y compra del piso")
                        .font(.subheadline)
                        .foregroundStyle(RTheme.mutedForeground)
                        .opacity(taglineShown ? 1 : 0)
                        .offset(y: taglineShown || reduceMotion ? 0 : 8)
                }
                .offset(y: markSize * 0.3)

                LoadingDots()
                    .opacity(introDone && !isReady ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: introDone && !isReady)
                    .offset(y: markSize * 1.0)

                Image("Splash")
                    .resizable()
                    .scaledToFill()
                    .frame(width: side, height: side)
                    .opacity(launchImageOpacity)
                    .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .task { await playIntro() }
        .onChange(of: isReady, initial: true) {
            readySeen = isReady
            finishIfPossible()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rumies, cargando")
    }

    private var background: some View {
        // Same vertical warm-to-black fade as the Splash image.
        LinearGradient(
            stops: [
                .init(color: Color(hex: "#271813"), location: 0),
                .init(color: Color(hex: "#1d1311"), location: 0.3),
                .init(color: Color(hex: "#15100d"), location: 0.45),
                .init(color: Color(hex: "#0d0c0a"), location: 0.6),
                .init(color: RTheme.background, location: 0.75),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var wordmarkView: some View {
        HStack(spacing: 0) {
            ForEach(Self.wordmark.indices, id: \.self) { index in
                let shown = index < lettersShown
                Text(String(Self.wordmark[index]))
                    .opacity(shown ? 1 : 0)
                    .offset(y: shown || reduceMotion ? 0 : 16)
                    .blur(radius: shown || reduceMotion ? 0 : 6)
            }
        }
        .font(.system(size: 42, weight: .bold, design: .rounded))
        .foregroundStyle(RTheme.foreground)
    }

    private func playIntro() async {
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.35)) {
                launchImageOpacity = 0
                lifted = true
                doorLit = true
                lettersShown = Self.wordmark.count
                taglineShown = true
            }
            try? await Task.sleep(for: .seconds(0.8))
        } else {
            // Our copy of the mark sits right under the launch image's, so
            // fading the image out is invisible until the mark starts moving.
            withAnimation(.easeOut(duration: 0.3)) { launchImageOpacity = 0 }
            withAnimation(.easeInOut(duration: 0.2)) { markScale = 0.93 }
            try? await Task.sleep(for: .seconds(0.2))

            withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) {
                markScale = 1
                lifted = true
            }
            try? await Task.sleep(for: .seconds(0.2))

            withAnimation(.easeOut(duration: 0.35)) { doorLit = true }
            withAnimation(.easeOut(duration: 0.9)) { ripple = true }

            for index in 1...Self.wordmark.count {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) { lettersShown = index }
                try? await Task.sleep(for: .seconds(0.05))
            }
            withAnimation(.easeOut(duration: 0.4)) { taglineShown = true }
            try? await Task.sleep(for: .seconds(0.6))
        }
        introDone = true
        finishIfPossible()
    }

    private func finishIfPossible() {
        guard introDone, readySeen, !finished else { return }
        finished = true
        onFinish()
    }
}

/// Three dots pulsing in turn, driven by a clock rather than springs so the
/// loop never stutters.
private struct LoadingDots: View {
    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    let phase = (time * 1.4 - Double(index) * 0.18).truncatingRemainder(dividingBy: 1)
                    let pulse = 0.5 - 0.5 * cos(phase * 2 * .pi)
                    Circle()
                        .fill(RTheme.primary)
                        .frame(width: 7, height: 7)
                        .opacity(0.3 + 0.7 * pulse)
                        .scaleEffect(0.8 + 0.3 * pulse)
                }
            }
        }
    }
}

#Preview {
    SplashView(isReady: false) {}
}
