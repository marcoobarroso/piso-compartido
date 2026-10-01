import Foundation
import Supabase
import RumisCore

enum AppRoute: Equatable {
    case loading
    case loggedOut
    case needsProfile
    case needsHousehold
    case inHousehold
}

/// Drives top-level navigation the same way app/page.tsx +
/// lib/household.ts (resolveCurrentUser/requireHousehold) do on the web:
/// signed out -> needs a display name -> needs a household -> in the app.
/// One membership per user is a server-enforced invariant (join_household),
/// not re-validated here.
@MainActor
@Observable
final class AppSession {
    private(set) var route: AppRoute = .loading
    private(set) var userId: UUID?
    private(set) var userEmail: String?
    private(set) var profile: Profile?
    private(set) var household: Household?
    private(set) var membership: HouseholdMember?
    /// Set when the very first `resolve()` fails (e.g. no connection on cold
    /// launch) — without this, `route` stays `.loading` forever with no way
    /// out, since there's no previous good state to fall back to.
    private(set) var loadError: String?
    /// Set by an incoming "/join/CODE" Universal Link. Consumed the next
    /// time `resolve()` lands on `.needsHousehold` — which also covers the
    /// case where the link arrives before login/profile setup are done,
    /// since those paths all funnel back through `resolve()` via `refresh()`.
    private(set) var pendingInviteCode: String?
    private(set) var joinLinkError: String?
    /// Set right before `signOut()` in AccountSettingsView's delete-account
    /// flow, read once by LoginView to show the "cuenta borrada" banner —
    /// mirrors the web's /login?deleted=1 (app/login/deleted-notice.tsx).
    private(set) var accountJustDeleted = false

    private let authRepo = AuthRepository()
    private let profileRepo = ProfileRepository()
    private let householdRepo = HouseholdRepository()

    private var authTask: Task<Void, Never>?

    func start() {
        authTask?.cancel()
        authTask = Task { [weak self] in
            guard let self else { return }
            for await (event, session) in supabase.auth.authStateChanges {
                switch event {
                case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
                    if let session {
                        await self.resolve(userId: session.user.id, email: session.user.email)
                    } else {
                        self.setLoggedOut()
                    }
                case .signedOut:
                    self.setLoggedOut()
                default:
                    break
                }
            }
        }
    }

    private func setLoggedOut() {
        userId = nil
        userEmail = nil
        profile = nil
        household = nil
        membership = nil
        route = .loggedOut
    }

    func resolve(userId: UUID, email: String?) async {
        self.userId = userId
        self.userEmail = email
        do {
            let profile = try await profileRepo.fetchProfile(id: userId)
            self.profile = profile
            loadError = nil

            guard let name = profile.displayName, !name.isEmpty else {
                route = .needsProfile
                return
            }

            guard let membership = try await householdRepo.fetchMyMembership(userId: userId) else {
                if let code = pendingInviteCode {
                    pendingInviteCode = nil
                    do {
                        try await joinHousehold(code: code)
                    } catch {
                        joinLinkError = "No se ha podido unir al piso con ese enlace."
                        route = .needsHousehold
                    }
                    return
                }
                route = .needsHousehold
                return
            }
            self.membership = membership
            self.household = try await householdRepo.fetchHousehold(id: membership.householdId)
            route = .inHousehold
        } catch {
            if route == .loading {
                // No prior good state to fall back to (e.g. no connection on
                // cold launch) — surface it so the UI can offer a retry
                // instead of spinning forever.
                loadError = "No se ha podido conectar. Comprueba tu conexión."
            }
            // Otherwise: transient failure with an existing good state
            // already on screen — keep it rather than bouncing the user.
        }
    }

    func refresh() async {
        guard let userId else { return }
        await resolve(userId: userId, email: userEmail)
    }

    /// Retries the initial session resolution after a `loadError` (e.g. the
    /// user tapped "Reintentar" on the no-connection screen).
    func retryInitialLoad() async {
        guard let userId else { return }
        loadError = nil
        await resolve(userId: userId, email: userEmail)
    }

    func completeProfileSetup(name: String) async throws {
        guard let userId else { return }
        try await profileRepo.setDisplayName(name, userId: userId)
        await refresh()
    }

    func createHousehold(name: String) async throws {
        _ = try await householdRepo.createHousehold(name: name)
        await refresh()
    }

    func joinHousehold(code: String) async throws {
        _ = try await householdRepo.joinHousehold(inviteCode: code)
        await refresh()
    }

    func leaveHousehold() async throws {
        guard let household else { return }
        try await householdRepo.leaveHousehold(householdId: household.id)
        await refresh()
    }

    func signOut() async throws {
        try await authRepo.signOut()
    }

    /// Call right before `signOut()` when the sign-out is a consequence of
    /// deleting the account, so LoginView knows to show the confirmation.
    func noteAccountDeleted() {
        accountJustDeleted = true
    }

    /// LoginView calls this once it has shown the banner, so it doesn't
    /// reappear on a later, unrelated sign-out.
    func acknowledgeAccountDeleted() {
        accountJustDeleted = false
    }

    /// Called from `RumisApp`'s `.onContinueUserActivity` when the user taps
    /// a "/join/CODE" Universal Link. If we're already in the right state to
    /// act on it, join immediately — otherwise stash it for `resolve()` to
    /// pick up once login/profile setup finish.
    func handleInviteLink(_ url: URL) {
        guard let code = InviteLink.inviteCode(from: url) else { return }
        if route == .needsHousehold {
            pendingInviteCode = nil
            Task {
                do {
                    try await joinHousehold(code: code)
                } catch {
                    joinLinkError = "No se ha podido unir al piso con ese enlace."
                }
            }
        } else {
            pendingInviteCode = code
        }
    }
}
