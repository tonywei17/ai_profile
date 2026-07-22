import Foundation

@MainActor
final class UsageManager: ObservableObject {
    /// `.requireRewardedAds(count)` — user must watch `count` rewarded ads (back-to-back)
    /// before this generation. Ad count escalates with same-day usage (see `canGenerate`).
    enum Decision: Equatable { case allowed, requireRewardedAds(Int), reachedDailyLimit, reachedLimit }

    @Published private(set) var subscriberUsesLeft: Int = 20
    @Published private(set) var freeUsesToday: Int = 0

    private let defaults = UserDefaults.standard
    private let kFirstUseDone = "aiid.firstUseDone"
    private let kLastReset = "aiid.lastReset"
    // Keychain keys for sensitive counters
    private let kSubscriberLeft = "aiid.subscriber.left"
    private let kFreeUsesToday = "aiid.free.usesToday"

    // Migration flag
    private let kMigrated = "aiid.usage.keychainMigrated"

    static let freeDailyLimit = 3

    /// Hard cap on rewarded ads shown for a single generation, regardless of how high
    /// `freeDailyLimit` is raised later. Capped at 2 so the "watch N ads" promise never
    /// exceeds what ad fill reliably delivers (3 chained ads routinely under-filled).
    static let maxAdsPerGeneration = 2

    init() {
        migrateToKeychainIfNeeded()
        resetIfNeeded()
        subscriberUsesLeft = KeychainHelper.readInt(key: kSubscriberLeft) ?? 20
        if subscriberUsesLeft == 0 { subscriberUsesLeft = 20 }
        freeUsesToday = KeychainHelper.readInt(key: kFreeUsesToday) ?? 0
    }

    var freeUsesRemaining: Int {
        max(0, Self.freeDailyLimit - freeUsesToday)
    }

    /// True only until the very first generation of the app's lifetime is consumed.
    /// After that, every generation (including each day's first) requires watching ads.
    var hasLifetimeFreeLeft: Bool {
        !defaults.bool(forKey: kFirstUseDone)
    }

    func canGenerate(isSubscribed: Bool) -> Decision {
        resetIfNeeded()
        if isSubscribed {
            return subscriberUsesLeft > 0 ? .allowed : .reachedLimit
        } else {
            if freeUsesToday >= Self.freeDailyLimit {
                return .reachedDailyLimit
            }
            let firstUsed = defaults.bool(forKey: kFirstUseDone)
            // Lifetime-first generation is free; after that ads escalate with same-day usage:
            // today's 1st = 1 ad, 2nd and beyond = 2 ads … capped at maxAdsPerGeneration.
            guard firstUsed else { return .allowed }
            let ads = min(freeUsesToday + 1, Self.maxAdsPerGeneration)
            return .requireRewardedAds(ads)
        }
    }

    func markUsed(isSubscribed: Bool) {
        if isSubscribed {
            if subscriberUsesLeft > 0 {
                subscriberUsesLeft -= 1
                KeychainHelper.saveInt(key: kSubscriberLeft, value: subscriberUsesLeft)
            }
        } else {
            defaults.set(true, forKey: kFirstUseDone)
            freeUsesToday += 1
            KeychainHelper.saveInt(key: kFreeUsesToday, value: freeUsesToday)
        }
    }

    // MARK: - Daily Reset

    private func resetIfNeeded() {
        let today = Self.dayString(Date())
        let last = defaults.string(forKey: kLastReset)
        if last != today {
            defaults.set(today, forKey: kLastReset)
            subscriberUsesLeft = 20
            KeychainHelper.saveInt(key: kSubscriberLeft, value: 20)
            freeUsesToday = 0
            KeychainHelper.saveInt(key: kFreeUsesToday, value: 0)
        }
    }

    // MARK: - Migration (UserDefaults → Keychain, one-time)

    private func migrateToKeychainIfNeeded() {
        guard !defaults.bool(forKey: kMigrated) else { return }
        let oldSub = defaults.integer(forKey: kSubscriberLeft)
        if oldSub > 0 { KeychainHelper.saveInt(key: kSubscriberLeft, value: oldSub) }
        let oldFree = defaults.integer(forKey: kFreeUsesToday)
        if oldFree > 0 { KeychainHelper.saveInt(key: kFreeUsesToday, value: oldFree) }
        defaults.removeObject(forKey: kSubscriberLeft)
        defaults.removeObject(forKey: kFreeUsesToday)
        defaults.set(true, forKey: kMigrated)
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func dayString(_ date: Date) -> String {
        dayFormatter.string(from: date)
    }
}
