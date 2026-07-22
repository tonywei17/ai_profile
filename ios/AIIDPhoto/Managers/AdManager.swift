import Foundation
import SwiftUI
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@MainActor
final class AdManager: ObservableObject {
    #if canImport(GoogleMobileAds)
    private var rewardedAd: RewardedAd?
    /// Held strongly during presentation because `fullScreenContentDelegate` is weak.
    private var presentationDelegate: RewardedPresentationDelegate?
    #endif

    /// True when a rewarded ad is loaded and ready to present. The caller uses this to skip an
    /// ad slot on load failure / no fill instead of blocking the user's generation.
    var hasRewardedReady: Bool {
        #if canImport(GoogleMobileAds)
        return rewardedAd != nil
        #else
        return true
        #endif
    }

    func loadRewarded() async {
        #if canImport(GoogleMobileAds)
        do {
            rewardedAd = try await RewardedAd.load(with: AdUnits.rewarded, request: Request())
        } catch {
            print("Failed to load rewarded: \(error)")
            rewardedAd = nil
        }
        #endif
    }

    /// Presents the loaded rewarded ad and resolves ONLY after the ad is fully dismissed (or
    /// immediately if it fails to present). Returns true if the user earned the reward.
    ///
    /// Resolving on dismiss — not on the reward callback — is critical: it guarantees the
    /// full-screen ad has left the screen before the caller presents the next ad or starts
    /// generation. The previous implementation resumed on the reward callback (fired while the
    /// ad was still on screen), so the next `present` raced the in-flight dismissal and silently
    /// failed, leaving the continuation hung and the photo never generated.
    func showRewarded() async -> Bool {
        #if canImport(GoogleMobileAds)
        guard let root = await UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.keyWindow?.rootViewController,
              let ad = rewardedAd else { return false }
        rewardedAd = nil  // consume — a rewarded ad object can only be presented once

        return await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            let delegate = RewardedPresentationDelegate { earned in
                cont.resume(returning: earned)
            }
            self.presentationDelegate = delegate
            ad.fullScreenContentDelegate = delegate
            ad.present(from: root) {
                delegate.didEarnReward = true
            }
        }
        #else
        return true
        #endif
    }
}

#if canImport(GoogleMobileAds)
/// Bridges GoogleMobileAds' full-screen callbacks into a single resume-once continuation.
/// Calls `onFinish(earnedReward)` exactly once — on dismiss, or on present-failure.
private final class RewardedPresentationDelegate: NSObject, FullScreenContentDelegate {
    var didEarnReward = false
    private var finished = false
    private let onFinish: (Bool) -> Void

    init(onFinish: @escaping (Bool) -> Void) {
        self.onFinish = onFinish
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Rewarded ad failed to present: \(error)")
        finish(false)
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        finish(didEarnReward)
    }

    private func finish(_ earned: Bool) {
        guard !finished else { return }
        finished = true
        onFinish(earned)
    }
}
#endif

struct AdUnits {
    #if DEBUG
    static let banner = "ca-app-pub-3940256099942544/2934735716" // test
    static let rewarded = "ca-app-pub-3940256099942544/5224354917" // test
    #else
    static let banner = "ca-app-pub-4720104330290543/5918173790"
    static let rewarded = "ca-app-pub-4720104330290543/8097944140"
    #endif
}

#if canImport(GoogleMobileAds)
struct AdBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let view = BannerView(adSize: AdSizeBanner)
        view.adUnitID = AdUnits.banner
        view.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.rootViewController
        view.load(Request())
        return view
    }
    func updateUIView(_ uiView: BannerView, context: Context) {}
}
#endif

private extension UIWindowScene {
    var keyWindow: UIWindow? { self.windows.first { $0.isKeyWindow } }
}
