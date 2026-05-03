import WatchConnectivity
import Observation

/// iPhone side – sends level data to the paired Apple Watch.
@Observable
@MainActor
final class WatchConnectivityManager: NSObject {

    var isWatchReachable: Bool = false
    var isWatchPaired: Bool = false
    var isWatchAppInstalled: Bool = false

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func refreshState() {
        let session = WCSession.default
        isWatchReachable    = session.isReachable
        isWatchPaired       = session.isPaired
        isWatchAppInstalled = session.isWatchAppInstalled
    }

    /// Sends a dictionary to the Watch.
    /// Uses `sendMessage` when the Watch app is in the foreground,
    /// falls back to `updateApplicationContext` otherwise.
    func send(_ payload: [String: Any]) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled else { return }

        // Always update context so Watch has fresh data on launch
        try? session.updateApplicationContext(payload)

        // Additionally push live via sendMessage when Watch is in foreground
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith state: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in self.refreshState() }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.refreshState() }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.refreshState() }
    }

    // Required on iOS
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
