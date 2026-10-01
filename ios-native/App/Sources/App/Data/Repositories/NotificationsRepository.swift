import Foundation
import Supabase

struct NotificationReadUpdate: Encodable {
    var isRead: Bool
}

struct NotificationsRepository {
    func fetchNotifications(userId: UUID) async throws -> [AppNotification] {
        try await supabase.from("notifications")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(30)
            .execute()
            .value
    }

    func markRead(id: UUID) async throws {
        try await supabase.from("notifications")
            .update(NotificationReadUpdate(isRead: true))
            .eq("id", value: id)
            .execute()
    }

    func markAllRead(userId: UUID) async throws {
        try await supabase.from("notifications")
            .update(NotificationReadUpdate(isRead: true))
            .eq("user_id", value: userId)
            .eq("is_read", value: false)
            .execute()
    }
}

@MainActor
final class NotificationsRealtimeSubscription {
    private var channel: RealtimeChannelV2?

    func subscribe(userId: UUID, onInsert: @escaping @Sendable () -> Void) async {
        await unsubscribe()
        let channel = supabase.channel("notifications-\(userId.uuidString)")
        _ = channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "notifications",
            filter: .eq("user_id", value: userId)
        ) { _ in
            onInsert()
        }
        self.channel = channel
        try? await channel.subscribeWithError()
    }

    func unsubscribe() async {
        guard let channel else { return }
        await supabase.removeChannel(channel)
        self.channel = nil
    }
}
