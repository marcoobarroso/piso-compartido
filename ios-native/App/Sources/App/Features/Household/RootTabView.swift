import SwiftUI

/// Top-level tab bar, shown once `AppSession.route == .inHousehold`. Mirrors
/// the web app's BottomNav (app/household/bottom-nav.tsx) plus the "Stats"
/// tab which lives at /household/stats there.
struct RootTabView: View {
    @State private var selection = 0

    private static let tabNames = ["Inicio", "Gastos", "Tareas", "Compra", "Stats"]

    var body: some View {
        TabView(selection: $selection) {
            HouseholdHomeView()
                .tabItem {
                    Label("Inicio", systemImage: "house.fill")
                }
                .tag(0)

            ExpensesView()
                .tabItem {
                    Label("Gastos", systemImage: "eurosign.circle.fill")
                }
                .tag(1)

            ChoresView()
                .tabItem {
                    Label("Tareas", systemImage: "checklist")
                }
                .tag(2)

            ShoppingView()
                .tabItem {
                    Label("Compra", systemImage: "cart.fill")
                }
                .tag(3)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(4)
        }
        .tint(RTheme.primary)
        .task {
            AnalyticsConfig.screen(Self.tabNames[selection])
        }
        .onChange(of: selection) { _, newValue in
            AnalyticsConfig.screen(Self.tabNames[newValue])
        }
        .onReceive(NotificationCenter.default.publisher(for: .rumisPushTapped)) { note in
            // `link` values come from the notification triggers in
            // supabase/migrations/0004_notifications.sql — keep in sync if
            // those ever change.
            guard let link = note.userInfo?["link"] as? String else { return }
            switch link {
            case "/household/expenses": selection = 1
            case "/household/chores": selection = 2
            default: selection = 0
            }
        }
    }
}
