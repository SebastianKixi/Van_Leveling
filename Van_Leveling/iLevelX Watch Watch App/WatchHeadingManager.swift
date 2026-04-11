import CoreLocation
import Observation

/// Tracks the Apple Watch's own compass heading.
/// Requires Apple Watch Series 5+ for built-in compass.
/// On older models, heading remains -1 (unavailable) and no rotation is applied.
@Observable
@MainActor
final class WatchHeadingManager: NSObject {
    private let locationManager = CLLocationManager()

    var heading: Double = -1         // compass degrees 0–360, -1 = unavailable
    var isAvailable: Bool = false

    override init() {
        super.init()
        isAvailable = CLLocationManager.headingAvailable()
        locationManager.delegate = self
        locationManager.headingFilter = 2.0  // update every 2° change
    }

    func start() {
        guard CLLocationManager.headingAvailable() else { return }
        locationManager.startUpdatingHeading()
    }

    func stop() {
        locationManager.stopUpdatingHeading()
    }
}

extension WatchHeadingManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        let h = newHeading.magneticHeading
        Task { @MainActor [weak self] in
            self?.heading = h
        }
    }
}
