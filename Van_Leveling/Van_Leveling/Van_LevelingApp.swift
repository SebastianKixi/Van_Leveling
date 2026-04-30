import SwiftUI
import UIKit

@main
struct Van_LevelingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// Steuert dynamisch die erlaubten Orientierungen pro View.
/// Default: alle Orientierungen erlaubt. Einzelne Tabs (z.B. Winkelmesser)
/// setzen `orientationLock` auf .portrait und stellen sie beim Verlassen wieder her.
final class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .all

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return Self.orientationLock
    }
}

/// Bequemer Helper zum Sperren/Freigeben der UI-Orientierung pro View.
extension View {
    func lockOrientation(_ mask: UIInterfaceOrientationMask) -> some View {
        self
            .onAppear {
                AppDelegate.orientationLock = mask
                if let scene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene }).first {
                    scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
                }
            }
            .onDisappear {
                AppDelegate.orientationLock = .all
            }
    }
}
