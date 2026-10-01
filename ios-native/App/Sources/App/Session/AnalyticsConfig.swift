import PostHog

/// Minimal, privacy-conscious product analytics — screen views and a
/// handful of core actions, just enough to answer "what gets used" and
/// "where people drop off". Off by default so a fresh checkout doesn't
/// send events to a project nobody owns, same pattern as SentryConfig.
///
/// Deliberately anonymous: we never call `identify()` with the Supabase
/// user id, so PostHog's device-generated anonymous distinct ID is all it
/// ever sees. That matches the existing "Interacción con el producto |
/// Analíticas | No vinculado" row already declared in PrivacyInfo.xcprivacy
/// and docs/LANZAMIENTO_APP_STORE.md §5 — keep it that way if this ever
/// grows beyond anonymous aggregate events.
enum AnalyticsConfig {
    /// TODO: paste the API key from a posthog.com project (free plan) to enable.
    static let apiKey = ""

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
