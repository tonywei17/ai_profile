import SwiftUI

@main
struct AIIDPhotoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var subscription = SubscriptionManager()
    @StateObject private var usage = UsageManager()
    @StateObject private var adManager = AdManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(subscription)
                .environmentObject(usage)
                .environmentObject(adManager)
        }
    }
}
