import Foundation
import UIKit
import UserNotifications

/// Requests notification permission and, if granted, kicks off APNs
/// registration. The resulting device token is handed to `PushRepository`
/// from `RumisPushDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`
/// once iOS calls back — mirrors the opt-in flow in lib/native-push.ts.
enum PushManager {
    static func requestPermissionAndRegister() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { return }
            await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
        } catch {
            // ignore — user can retry later, no need to surface this
        }
    }
}
