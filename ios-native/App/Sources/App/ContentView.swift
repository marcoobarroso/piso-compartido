import SwiftUI

/// Top-level router, mirroring app/page.tsx's redirect chain: loading ->
/// logged out -> needs a display name -> needs a household -> in the app.
struct ContentView: View {
    @Environment(AppSession.self) private var session
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some View {
        VStack(spacing: 0) {
            if !networkMonitor.isConnected {
                OfflineBanner()
            }

            Group {
                switch session.route {
                case .loading:
                    if let loadError = session.loadError {
                        ConnectionErrorView(message: loadError) {
                            Task { await session.retryInitialLoad() }
                        }
                    } else {
                        ProgressView()
                            .tint(RTheme.primary)
                    }
                case .loggedOut:
                    LoginView()
                case .needsProfile:
                    ProfileSetupView()
                case .needsHousehold:
                    OnboardingView()
                case .inHousehold:
                    RootTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(RTheme.background)
        .onChange(of: session.route) { _, newRoute in
            if newRoute == .inHousehold {
                Task { await PushManager.requestPermissionAndRegister() }
            }
        }
    }
}

private struct OfflineBanner: View {
    var body: some View {
        Text("Sin conexión")
            .font(.footnote.weight(.medium))
            .foregroundStyle(RTheme.primaryForeground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(RTheme.destructive)
    }
}

private struct ConnectionErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundStyle(RTheme.mutedForeground)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(RTheme.mutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Reintentar", action: onRetry)
                .buttonStyle(.rPrimary)
                .frame(width: 160)
        }
    }
}
