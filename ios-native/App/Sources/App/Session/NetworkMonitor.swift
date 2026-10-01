import Foundation
import Network

/// Tracks basic connectivity so the UI can show a persistent "sin conexión"
/// banner — the native equivalent of the Capacitor app's offline.html
/// fallback screen, but as a non-blocking banner since a native app can
/// still show whatever data it already has cached in view state.
@MainActor
@Observable
final class NetworkMonitor {
    private(set) var isConnected = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "rumis.network-monitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
