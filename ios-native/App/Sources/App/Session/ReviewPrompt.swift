import StoreKit
import UIKit

/// Asks for an App Store rating after a few genuinely positive moments
/// (completing a chore, settling a debt) — never on first launch or after
/// an error. StoreKit itself caps how often the system dialog can actually
/// appear (about 3 times/year) regardless of how often this is called, but
/// we still avoid calling it on every single action so it doesn't feel
/// like nagging on the few times it *would* show.
enum ReviewPrompt {
    private static let countKey = "rumis.positiveActionCount"
    private static let minActionsBeforeAsking = 3

    @MainActor
    static func registerPositiveAction() {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: countKey) + 1
        defaults.set(count, forKey: countKey)

        guard count >= minActionsBeforeAsking, count % minActionsBeforeAsking == 0 else { return }
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }

        SKStoreReviewController.requestReview(in: scene)
    }
}
