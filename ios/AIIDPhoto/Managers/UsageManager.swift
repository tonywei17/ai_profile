import Foundation

@MainActor
final class UsageManager: ObservableObject {
    enum Decision { case allowed, requireRewardedAd, reachedDailyLimit, reachedLimit }

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

    static let freeDailyLimit = 5

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

    func canGenerate(isSubscribed: Bool) -> Decision {
        resetIfNeeded()
        if isSubscribed {
            return subscriberUsesLeft > 0 ? .allowed : .reachedLimit
        } else {
            if freeUsesToday >= Self.freeDailyLimit {
                return .reachedDailyLimit
            }
            let firstUsed = defaults.bool(forKey: kFirstUseDone)
            return firstUsed ? .requireRewardedAd : .allowed
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
