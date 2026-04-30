import CoreMotion
import CoreLocation
import Observation

@Observable
@MainActor
final class MotionManager: NSObject {
    private let manager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.maxConcurrentOperationCount = 1
        q.qualityOfService = .userInteractive
        return q
    }()

    var pitch: Double = 0       // degrees, positive = front tilted down
    var roll: Double = 0        // degrees, positive = right side down
    var heading: Double = -1    // compass degrees 0–360, -1 = unavailable
    var isAvailable: Bool = false
    var isHeadingAvailable: Bool = false

    // Gravity vector in device-body frame (each component in g, range -1...1)
    var gravityX: Double = 0
    var gravityY: Double = 0
    var gravityZ: Double = 0

    override init() {
        super.init()
        isAvailable = manager.isDeviceMotionAvailable
        isHeadingAvailable = CLLocationManager.headingAvailable()
        locationManager.delegate = self
        locationManager.headingFilter = 1.0
    }

    func startUpdates() {
        // Motion (pitch + roll)
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let motion else { return }
            let p = motion.attitude.pitch * 180.0 / .pi
            let r = motion.attitude.roll  * 180.0 / .pi
            let gx = motion.gravity.x
            let gy = motion.gravity.y
            let gz = motion.gravity.z
            Task { @MainActor [weak self] in
                self?.pitch = p
                self?.roll  = r
                self?.gravityX = gx
                self?.gravityY = gy
                self?.gravityZ = gz
            }
        }

        // Compass heading
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }

    func stopUpdates() {
        manager.stopDeviceMotionUpdates()
        locationManager.stopUpdatingHeading()
    }
}

// MARK: - CLLocationManagerDelegate

extension MotionManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        let h = newHeading.magneticHeading
        Task { @MainActor [weak self] in
            self?.heading = h
        }
    }

    nonisolated func locationManagerShouldDisplayHeadingCalibration(
        _ manager: CLLocationManager
    ) -> Bool { true }
}
