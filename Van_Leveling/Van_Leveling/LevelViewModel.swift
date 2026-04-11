import Foundation
import AudioToolbox
import Observation

@Observable
@MainActor
final class LevelViewModel {
    let motion = MotionManager()
    let watchManager = WatchConnectivityManager()

    // Calibration offsets (UserDefaults)
    var calibrationPitch: Double = 0
    var calibrationRoll: Double = 0

    // Active use-case profile
    var selectedProfile: LevelProfile = .general {
        didSet { UserDefaults.standard.set(selectedProfile.id, forKey: "selectedProfileID") }
    }

    // Settings
    var soundEnabled: Bool = true

    // Monetization (Pro IAP not yet active — all features unlocked in v1.0)
    var isProVersion: Bool = true

    // Effective tolerance: respect pro-only profiles
    var tolerance: Double {
        guard !selectedProfile.isProOnly || isProVersion else { return 1.0 }
        return selectedProfile.tolerance
    }

    // Calibration-adjusted angles
    var adjustedPitch: Double { motion.pitch - calibrationPitch }
    var adjustedRoll:  Double { motion.roll  - calibrationRoll  }

    var isLevel:      Bool { abs(adjustedPitch) <= tolerance && abs(adjustedRoll) <= tolerance }
    var isPitchLevel: Bool { abs(adjustedPitch) <= tolerance }
    var isRollLevel:  Bool { abs(adjustedRoll)  <= tolerance }

    // Profile-aware instructions
    var rollInstruction: String {
        if isRollLevel { return "Links / Rechts: Waagerecht ✓" }
        return adjustedRoll > 0
            ? selectedProfile.rollPositive
            : selectedProfile.rollNegative
    }

    var pitchInstruction: String {
        if isPitchLevel { return "Vorne / Hinten: Waagerecht ✓" }
        return adjustedPitch > 0
            ? selectedProfile.pitchPositive
            : selectedProfile.pitchNegative
    }

    // Arrow SF Symbol names
    var rollArrowName: String? {
        guard !isRollLevel else { return nil }
        return adjustedRoll > 0 ? "arrow.right" : "arrow.left"
    }

    var pitchArrowName: String? {
        guard !isPitchLevel else { return nil }
        return adjustedPitch > 0 ? "arrow.down" : "arrow.up"
    }

    private var wasLevel = false
    private var lastWatchSend: Date = .distantPast

    init() {
        loadCalibration()
        loadProfile()
    }

    func start() { motion.startUpdates() }
    func stop()  { motion.stopUpdates()  }

    func calibrate() {
        calibrationPitch = motion.pitch
        calibrationRoll  = motion.roll
        saveCalibration()
    }

    func resetCalibration() {
        calibrationPitch = 0
        calibrationRoll  = 0
        saveCalibration()
    }

    /// Called every motion tick from ContentView's onChange.
    func onMotionTick() {
        checkAndPlayLevelSound()
        sendToWatchThrottled()
    }

    // MARK: - Private

    private func checkAndPlayLevelSound() {
        let levelNow = isLevel
        if levelNow && !wasLevel && soundEnabled {
            AudioServicesPlaySystemSound(1057)
        }
        wasLevel = levelNow
    }

    /// Throttled to ~10 Hz to avoid flooding WatchConnectivity.
    private func sendToWatchThrottled() {
        let now = Date()
        guard now.timeIntervalSince(lastWatchSend) >= 0.1 else { return }
        lastWatchSend = now

        watchManager.send([
            "pitch"           : adjustedPitch,
            "roll"            : adjustedRoll,
            "isLevel"         : isLevel,
            "isPitchLevel"    : isPitchLevel,
            "isRollLevel"     : isRollLevel,
            "profileName"     : selectedProfile.name,
            "profileIcon"     : selectedProfile.icon,
            "rollPositive"    : selectedProfile.rollPositive,
            "rollNegative"    : selectedProfile.rollNegative,
            "pitchPositive"   : selectedProfile.pitchPositive,
            "pitchNegative"   : selectedProfile.pitchNegative,
            "showPitch"       : selectedProfile.showPitch,
            "tolerance"       : tolerance,
            "iPhoneHeading"   : motion.heading
        ])
    }

    // MARK: - Persistence

    private func saveCalibration() {
        UserDefaults.standard.set(calibrationPitch, forKey: "cal_pitch")
        UserDefaults.standard.set(calibrationRoll,  forKey: "cal_roll")
    }

    private func loadCalibration() {
        calibrationPitch = UserDefaults.standard.double(forKey: "cal_pitch")
        calibrationRoll  = UserDefaults.standard.double(forKey: "cal_roll")
    }

    private func loadProfile() {
        guard let id = UserDefaults.standard.string(forKey: "selectedProfileID"),
              let profile = LevelProfile.all.first(where: { $0.id == id })
        else { return }
        selectedProfile = profile
    }
}
