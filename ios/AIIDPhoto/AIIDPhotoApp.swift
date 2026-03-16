import SwiftUI

@main
struct AIIDPhotoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var subscription = SubscriptionManager()
    @StateObject private var usage = UsageManager()
    @StateObject private var adManager = AdManager()
    @StateObject private var langManager = LanguageManager()
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var referralManager = ReferralManager()

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(subscription)
                .environmentObject(usage)
                .environmentObject(adManager)
                .environmentObject(langManager)
                .environmentObject(historyManager)
                .environmentObject(referralManager)
                .preferredColorScheme(langManager.appearance.colorScheme)
                .fullScreenCover(isPresented: Binding(
                    get: { !hasSeenOnboarding },
                    set: { if !$0 { hasSeenOnboarding = true } }
                )) {
                    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                        .environmentObject(langManager)
                        .preferredColorScheme(langManager.appearance.colorScheme)
                }
                .onChange(of: hasSeenOnboarding) { seen in
                    if seen {
                        // Request ATT after onboarding is dismissed so the dialog is visible
                        AppDelegate.requestTrackingIfNeeded()
                    }
                }
                .task {
                    AnalyticsManager.shared.track(AnalyticsManager.Event.appOpen)
                    await referralManager.registerCode()
                    // For returning users who already completed onboarding
                    if hasSeenOnboarding {
                        AppDelegate.requestTrackingIfNeeded()
                    }
                }
        }
    }
}
