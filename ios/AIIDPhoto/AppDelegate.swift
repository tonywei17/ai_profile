import SwiftUI
import AppTrackingTransparency

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start(completionHandler: nil)
        #endif
        return true
    }

    /// Request ATT permission. Called from the app after onboarding is complete
    /// to ensure the dialog is visible and not hidden behind a fullScreenCover.
    static func requestTrackingIfNeeded() {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        // Small delay to ensure the UI is fully settled after onboarding dismissal
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}
