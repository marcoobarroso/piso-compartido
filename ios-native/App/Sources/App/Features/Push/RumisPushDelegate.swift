import Foundation
import UIKit
import UserNotifications

/// Posted when the user taps a push notification that carries a `link`
/// payload (same shape as the `link` column on `notifications`, see
/// Data/Models.swift's `AppNotification`). The coordinator observes this to
/// drive in-app navigation; this file does not navigate itself.
extension Notification.Name {
    static let rumisPushTapped = Notification.Name("rumis.pushTapped")
}

/// App delegate handling APNs registration and notification presentation,
/// mirroring the native push plugin's responsibilities described in
/// lib/native-push.ts (token registration + foreground presentation +
/// tap-to-navigate), adapted to UIKit's push APIs.
final class RumisPushDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let hexToken = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task {
            try? await PushRepository().registerToken(hexToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("APNs registration failed: \(error)")
        #endif
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show pushes even while the app is foregrounded, matching the web
        // app's behavior (the service worker always shows a system toast).
        [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let link = response.notification.request.content.userInfo["link"] as? String else { return }
        NotificationCenter.default.post(name: .rumisPushTapped, object: nil, userInfo: ["link": link])
    }
}
