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
    #endif

    func loadRewarded() async {
        #if canImport(GoogleMobileAds)
        do {
            rewardedAd = try await RewardedAd.load(with: AdUnits.rewarded, request: Request())
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
            ad.present(from: root) {
                cont.resume(returning: true)
            }
        }
        #else
        return true
        #endif
    }
}

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
