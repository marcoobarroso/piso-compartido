import PostHog

/// Minimal, privacy-conscious product analytics — screen views and a
/// handful of core actions, just enough to answer "what gets used" and
/// "where people drop off". `apiKey` is PostHog's public "Project API Key"
/// (write-only: submits events, can't read project data back) — same
/// embed-safely-in-a-client-binary category as the Sentry DSN and the
/// Supabase anon key elsewhere in this app. Host is the EU cloud region,
/// matching where this project lives (posthog.com defaults to US unless
/// EU is picked explicitly at signup — check app vs. eu.posthog.com in the
/// dashboard URL before changing the key for a different project).
///
/// Deliberately anonymous: we never call `identify()` with the Supabase
/// user id, so PostHog's device-generated anonymous distinct ID is all it
/// ever sees. That matches the existing "Interacción con el producto |
/// Analíticas | No vinculado" row already declared in PrivacyInfo.xcprivacy
/// and docs/LANZAMIENTO_APP_STORE.md §5 — keep it that way if this ever
/// grows beyond anonymous aggregate events.
enum AnalyticsConfig {
    static let apiKey = "phc_nEuaZxFcU6GMLEwcY8wRF2oyBGwMTvw794mF2dHQCBCS"

    static func start() {
        guard !apiKey.isEmpty else { return }
        let config = PostHogConfig(apiKey: apiKey, host: "https://eu.i.posthog.com")
        PostHogSDK.shared.setup(config)
    }

    static func track(_ event: String, _ properties: [String: Any] = [:]) {
        guard !apiKey.isEmpty else { return }
        PostHogSDK.shared.capture(event, properties: properties)
    }

    static func screen(_ name: String) {
        guard !apiKey.isEmpty else { return }
        PostHogSDK.shared.screen(name)
    }
}
