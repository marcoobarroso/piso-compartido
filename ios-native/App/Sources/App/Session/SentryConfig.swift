import Sentry

/// Crash/error reporting. The DSN below is not secret — like the Supabase
/// anon key in SupabaseClient.swift, Sentry DSNs are designed to ship
/// inside client binaries (write-only: it lets the SDK submit events, not
/// read project data). `start()` is a no-op if `dsn` is ever emptied out
/// (e.g. for a throwaway fork nobody wants reporting to this project).
enum SentryConfig {
    static let dsn = "https://42748a5f079443d1c2ab839f526d53b9@o4511943193329664.ingest.de.sentry.io/4512181614805072"

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
