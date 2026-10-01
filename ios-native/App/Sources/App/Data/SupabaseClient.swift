import Foundation
import Supabase

/// Same project the Next.js web app talks to (NEXT_PUBLIC_SUPABASE_URL /
/// NEXT_PUBLIC_SUPABASE_ANON_KEY in .env.local) — the anon/publishable key
/// is safe to embed client-side, it's only as powerful as RLS allows.
enum SupabaseConfig {
    static let url = URL(string: "https://ffrsgxxekbkwmijumdxl.supabase.co")!
    static let anonKey = "sb_publishable_3QVb80gOOKLdAn2AqF1KQA_6l-riL3F"
}

/// The default PostgrestClient decoder/encoder handle Postgres timestamptz
/// (ISO8601, with/without fractional seconds) but don't convert
/// snake_case <-> camelCase keys. Ours does both, so model properties can
/// stay idiomatic Swift (e.g. `displayName`) while matching DB columns
/// (`display_name`).
private func makePostgrestDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        if let date = try? Date(string, strategy: Date.ISO8601FormatStyle.rumisTimestamp(fractional: true)) {
            return date
        }
        if let date = try? Date(string, strategy: Date.ISO8601FormatStyle.rumisTimestamp(fractional: false)) {
            return date
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Invalid Postgres timestamp: \(string)"
        )
    }
    return decoder
}

private func makePostgrestEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .custom { date, encoder in
        var container = encoder.singleValueContainer()
        try container.encode(date.formatted(Date.ISO8601FormatStyle.rumisTimestamp(fractional: true)))
    }
    return encoder
}

private extension Date.ISO8601FormatStyle {
    static func rumisTimestamp(fractional: Bool) -> Date.ISO8601FormatStyle {
        .init()
            .year().month().day()
            .dateTimeSeparator(.standard)
            .time(includingFractionalSeconds: fractional)
            .timeZone(separator: .colon)
    }
}

let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.anonKey,
    options: SupabaseClientOptions(
        db: .init(encoder: makePostgrestEncoder(), decoder: makePostgrestDecoder())
    )
)
