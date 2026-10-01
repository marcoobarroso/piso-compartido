import Foundation
import Supabase

struct AuthRepository {
    /// Triggers GoTrue's /otp email (shouldCreateUser: true matches the web
    /// app's passwordless signup-or-login-in-one flow).
    func requestEmailCode(email: String) async throws {
        try await supabase.auth.signInWithOTP(email: email, shouldCreateUser: true)
    }

    /// NOTE: supabase-js verifies this flow with `type: "email"`, but
    /// supabase-swift's `EmailOTPType` has no `.email` case (only `.signup`,
    /// `.invite`, `.magiclink`, `.recovery`, `.emailChange`) — `.magiclink`
    /// is the closest documented match for a `signInWithOTP(email:)` code.
    /// VERIFY against the real project on first device test: if GoTrue
    /// rejects it, try `.signup` for a brand-new user's first-ever code.
    func verifyEmailCode(email: String, code: String) async throws {
        try await supabase.auth.verifyOTP(email: email, token: code, type: .magiclink)
    }

    func signInDemo(email: String, password: String) async throws {
        try await supabase.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
    }

    var currentUserId: UUID? {
        supabase.auth.currentUser?.id
    }

    var currentUserEmail: String? {
        supabase.auth.currentUser?.email
    }
}
