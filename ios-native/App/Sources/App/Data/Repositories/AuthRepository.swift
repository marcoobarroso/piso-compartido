import Foundation
import Supabase

struct AuthRepository {
    /// Triggers GoTrue's /otp email (shouldCreateUser: true matches the web
    /// app's passwordless signup-or-login-in-one flow).
    func requestEmailCode(email: String) async throws {
        try await supabase.auth.signInWithOTP(email: email, shouldCreateUser: true)
    }

    /// Matches the web app's `supabase.auth.verifyOtp({ type: "email" })` —
    /// supabase-swift's `EmailOTPType.email` is that same generic email-OTP
    /// case (`.magiclink` is for the separate magic-link-URL flow, not the
    /// numeric code `signInWithOTP(email:)` sends).
    func verifyEmailCode(email: String, code: String) async throws {
        try await supabase.auth.verifyOTP(email: email, token: code, type: .email)
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
