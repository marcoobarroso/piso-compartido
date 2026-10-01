import Sentry

/// Crash/error reporting, off by default so a fresh checkout doesn't spam a
/// DSN nobody owns. To turn it on: create a project at sentry.io, paste its
/// DSN below, rebuild — that's the only step left. Until then `start()` is a
/// no-op (Sentry's own SDK behavior when given an empty DSN).
enum SentryConfig {
    /// TODO: paste the real DSN from sentry.io here to enable crash reporting.
    static let dsn = ""

    static func start() {
        guard !dsn.isEmpty else { return }
        SentrySDK.start { options in
            options.dsn = dsn
            options.tracesSampleRate = 0.2
            // Matches the web app's privacy stance (docs/LANZAMIENTO_APP_STORE.md
            // §5): crash/performance diagnostics only, not linked to identity,
            // no session replay/screenshots of user content.
            options.attachScreenshot = false
            options.attachViewHierarchy = false
        }
    }
}
