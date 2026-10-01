import Foundation
import Supabase

/// Registers/unregisters this device's APNs token, mirroring
/// lib/native-push.ts. The token belongs to the device, not the account —
/// re-registering under a different signed-in user reassigns it
/// server-side (see register_native_push_token in
/// supabase/migrations/0015_native_push_tokens.sql).
struct PushRepository {
    func registerToken(_ token: String) async throws {
        try await supabase
            .rpc("register_native_push_token", params: PushTokenParams(token: token, platform: "ios"))
            .execute()
    }

    func unregisterToken(_ token: String) async throws {
        try await supabase
            .rpc("unregister_native_push_token", params: TokenOnlyParams(token: token))
            .execute()
    }
}
