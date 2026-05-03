import WatchKit

/// Hält den Bildschirm der Apple Watch wach solange die iLevelX-App offen ist.
/// Nutzt WKExtendedRuntimeSession (watchOS 7+), Ersatz für das deprecated
/// `WKExtension.isFrontmostTimeoutExtended`.
@MainActor
final class WatchRuntimeSession: NSObject {
    private var session: WKExtendedRuntimeSession?

    func start() {
        guard session == nil else { return }
        let s = WKExtendedRuntimeSession()
        s.delegate = self
        s.start()
        session = s
    }

    func stop() {
        session?.invalidate()
        session = nil
    }
}

extension WatchRuntimeSession: WKExtendedRuntimeSessionDelegate {
    nonisolated func extendedRuntimeSessionDidStart(
        _ extendedRuntimeSession: WKExtendedRuntimeSession
    ) {}

    nonisolated func extendedRuntimeSessionWillExpire(
        _ extendedRuntimeSession: WKExtendedRuntimeSession
    ) {
        // Versuche die Session zu erneuern wenn sie abläuft
        Task { @MainActor [weak self] in
            self?.session = nil
            self?.start()
        }
    }

    nonisolated func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            self?.session = nil
        }
    }
}
