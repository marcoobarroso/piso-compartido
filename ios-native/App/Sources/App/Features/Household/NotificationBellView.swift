import SwiftUI
import RumisCore

/// Toolbar notification bell, mirroring app/household/notification-bell.tsx:
/// unread badge, popover list newest-first, tap-to-read, mark-all-read, and
/// a realtime subscription that refetches on new inserts.
struct NotificationBellView: View {
    @Environment(AppSession.self) private var session

    @State private var notifications: [AppNotification] = []
    @State private var showList = false
    @State private var realtime = NotificationsRealtimeSubscription()

    private let notificationsRepo = NotificationsRepository()

    private var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var body: some View {
        Button {
            showList = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")

                if unreadCount > 0 {
                    Text(unreadCount > 9 ? "9+" : "\(unreadCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(RTheme.primaryForeground)
                        .padding(3)
                        .frame(minWidth: 14, minHeight: 14)
                        .background(RTheme.destructive)
                        .clipShape(Circle())
                        .offset(x: 9, y: -9)
                }
            }
        }
        .accessibilityLabel("Notificaciones")
        .popover(isPresented: $showList) {
            NotificationsListView(
                notifications: notifications,
                onMarkRead: markRead,
                onMarkAllRead: markAllRead
            )
            .frame(minWidth: 320, minHeight: 360)
        }
        .task {
            guard let userId = session.userId else { return }
            await loadNotifications()
            await realtime.subscribe(userId: userId) {
                Task { await loadNotifications() }
            }
        }
        .onDisappear {
            Task { await realtime.unsubscribe() }
        }
    }

    private func loadNotifications() async {
        guard let userId = session.userId else { return }
        if let fetched = try? await notificationsRepo.fetchNotifications(userId: userId) {
            notifications = fetched
        }
    }

    private func markRead(_ notification: AppNotification) async {
        if !notification.isRead {
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].isRead = true
            }
            try? await notificationsRepo.markRead(id: notification.id)
        }
        // Mirrors notification-bell.tsx's router.push(notification.link) —
        // reuses the same tab-switch bus RootTabView already wires up for
        // tapping a push notification, so the mapping stays in one place.
        if let link = notification.link {
            showList = false
            NotificationCenter.default.post(name: .rumisPushTapped, object: nil, userInfo: ["link": link])
        }
    }

    private func markAllRead() async {
        guard notifications.contains(where: { !$0.isRead }) else { return }
        notifications = notifications.map { notification in
            var updated = notification
            updated.isRead = true
            return updated
        }
        guard let userId = session.userId else { return }
        try? await notificationsRepo.markAllRead(userId: userId)
    }
}

private struct NotificationsListView: View {
    let notifications: [AppNotification]
    let onMarkRead: (AppNotification) async -> Void
    let onMarkAllRead: () async -> Void

    var body: some View {
        NavigationStack {
            List {
                if notifications.isEmpty {
                    Text("No tienes notificaciones")
                        .font(.subheadline)
                        .foregroundStyle(RTheme.mutedForeground)
                        .listRowBackground(RTheme.background)
                } else {
                    ForEach(notifications) { notification in
                        Button {
                            Task { await onMarkRead(notification) }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(notification.message)
                                    .font(.subheadline.weight(notification.isRead ? .regular : .semibold))
                                    .foregroundStyle(notification.isRead ? RTheme.mutedForeground : RTheme.cardForeground)
                                Text(Format.formatRelativeTime(notification.createdAt))
                                    .font(.caption)
                                    .foregroundStyle(RTheme.mutedForeground)
                            }
                        }
                        .listRowBackground(RTheme.card)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(RTheme.background)
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Marcar todas como leídas") {
                        Task { await onMarkAllRead() }
                    }
                    .font(.caption)
                    .disabled(notifications.allSatisfy(\.isRead))
                }
            }
        }
    }
}
