import Foundation
import SwiftUI
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@MainActor
final class AdManager: ObservableObject {
    #if canImport(GoogleMobileAds)
    private var rewardedAd: GADRewardedAd?
    #endif

    func loadRewarded() async {
        #if canImport(GoogleMobileAds)
        do {
            rewardedAd = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<GADRewardedAd, Error>) in
                GADRewardedAd.load(withAdUnitID: AdUnits.rewarded, request: GADRequest()) { ad, error in
                    if let error = error { cont.resume(throwing: error); return }
                    guard let ad = ad else { cont.resume(throwing: NSError(domain: "Ad", code: -1)); return }
                    cont.resume(returning: ad)
                }
            }
        } catch {
            print("Failed to load rewarded: \(error)")
        }
        #endif
    }

    func showRewarded() async -> Bool {
        #if canImport(GoogleMobileAds)
        guard let root = await UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.keyWindow?.rootViewController,
              let ad = rewardedAd else { return false }
        return await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            ad.present(fromRootViewController: root) {
                cont.resume(returning: true)
            }
        }
        #else
        // Fallback in simulator/no SDK: grant reward instantly
        return true
        #endif
    }
}

struct AdUnits {
    #if DEBUG
    static let banner = "ca-app-pub-3940256099942544/2934735716" // test
    static let rewarded = "ca-app-pub-3940256099942544/5224354917" // test
    #else
    static let banner = "YOUR_PRODUCTION_BANNER_UNIT_ID"
    static let rewarded = "YOUR_PRODUCTION_REWARDED_UNIT_ID"
    #endif
}

#if canImport(GoogleMobileAds)
struct AdBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let view = GADBannerView(adSize: GADAdSizeBanner)
        view.adUnitID = AdUnits.banner
        view.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.rootViewController
        view.load(GADRequest())
        return view
    }
    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
#endif

private extension UIWindowScene {
    var keyWindow: UIWindow? { self.windows.first { $0.isKeyWindow } }
}
