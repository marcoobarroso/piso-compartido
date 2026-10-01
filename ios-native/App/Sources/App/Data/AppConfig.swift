import Foundation

/// The Next.js/Vercel backend the native app still talks to directly for
/// two things Supabase alone can't do: generating the Excel export
/// (ExpensesView) and the share-link text for invites (HouseholdHomeView).
/// See docs/LANZAMIENTO_APP_STORE.md for why this stays deployed.
enum AppConfig {
    static let webBaseURL = URL(string: "https://piso-compartido.vercel.app")!
}
