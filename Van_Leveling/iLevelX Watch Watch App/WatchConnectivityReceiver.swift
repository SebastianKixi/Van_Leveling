import WatchConnectivity
import Observation

/// Watch side – receives live level data from the paired iPhone.
@Observable
@MainActor
final class WatchConnectivityReceiver: NSObject {

    var pitch: Double = 0
    var roll:  Double = 0
    var isLevel:      Bool = false
    var isPitchLevel: Bool = false
    var isRollLevel:  Bool = false

    var profileName: String = "Allgemein"
    var profileIcon: String = "scope"
    var rollPositive:  String = ""
    var rollNegative:  String = ""
    var pitchPositive: String = ""
    var pitchNegative: String = ""
    var showPitch: Bool   = true
    var tolerance: Double = 0.5

    var iPhoneHeading: Double = -1  // compass degrees, -1 = unavailable
    var isConnected: Bool = false

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func apply(_ dict: [String: Any]) {
        pitch         = dict["pitch"]          as? Double ?? pitch
        roll          = dict["roll"]           as? Double ?? roll
        isLevel       = dict["isLevel"]        as? Bool   ?? isLevel
        isPitchLevel  = dict["isPitchLevel"]   as? Bool   ?? isPitchLevel
        isRollLevel   = dict["isRollLevel"]    as? Bool   ?? isRollLevel
        profileName   = dict["profileName"]    as? String ?? profileName
        profileIcon   = dict["profileIcon"]    as? String ?? profileIcon
        rollPositive  = dict["rollPositive"]   as? String ?? rollPositive
        rollNegative  = dict["rollNegative"]   as? String ?? rollNegative
        pitchPositive = dict["pitchPositive"]  as? String ?? pitchPositive
        pitchNegative = dict["pitchNegative"]  as? String ?? pitchNegative
        showPitch     = dict["showPitch"]      as? Bool   ?? showPitch
        tolerance     = dict["tolerance"]      as? Double ?? tolerance
        iPhoneHeading = dict["iPhoneHeading"]  as? Double ?? iPhoneHeading
        isConnected   = true
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityReceiver: WCSessionDelegate {

    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String: Any]) {
        Task { @MainActor in self.apply(message) }
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveApplicationContext context: [String: Any]) {
        Task { @MainActor in self.apply(context) }
    }

    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {}
}
