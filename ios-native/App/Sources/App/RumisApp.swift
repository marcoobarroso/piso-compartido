import SwiftUI

@main
struct RumisApp: App {
    @UIApplicationDelegateAdaptor(RumisPushDelegate.self) private var appDelegate
    @State private var session = AppSession()
    @State private var networkMonitor = NetworkMonitor()

    init() {
        SentryConfig.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(session)
                .environment(networkMonitor)
                .preferredColorScheme(.dark)
                .task {
                    // UI tests want a deterministic signed-out starting
                    // point regardless of whatever session persisted from a
                    // previous run/launch.
                    if ProcessInfo.processInfo.arguments.contains("UITEST_RESET_SESSION") {
                        try? await supabase.auth.signOut()
                    }
                    session.start()
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    guard let url = activity.webpageURL else { return }
                    session.handleInviteLink(url)
                }
        }
    }
}
