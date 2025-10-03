import Foundation

@MainActor
final class UsageManager: ObservableObject {
    enum Decision { case allowed, requireRewardedAd, reachedLimit }

    @Published private(set) var subscriberUsesLeft: Int = 20

    private let defaults = UserDefaults.standard
    private let kFirstUseDone = "aiid.firstUseDone"
    private let kLastReset = "aiid.lastReset"
    private let kSubscriberLeft = "aiid.subscriber.left"

    init() {
        resetIfNeeded()
        subscriberUsesLeft = defaults.integer(forKey: kSubscriberLeft)
        if subscriberUsesLeft == 0 { subscriberUsesLeft = 20 }
    }

    var freeTitle: String {
        let firstUsed = defaults.bool(forKey: kFirstUseDone)
        return firstUsed ? "再次使用需观看广告" : "首次免费"
    }

    func canGenerate(isSubscribed: Bool) -> Decision {
        resetIfNeeded()
        if isSubscribed {
            return subscriberUsesLeft > 0 ? .allowed : .reachedLimit
        } else {
            let firstUsed = defaults.bool(forKey: kFirstUseDone)
            return firstUsed ? .requireRewardedAd : .allowed
        }
    }

    func markUsed(isSubscribed: Bool) {
        if isSubscribed {
            if subscriberUsesLeft > 0 {
                subscriberUsesLeft -= 1
                defaults.set(subscriberUsesLeft, forKey: kSubscriberLeft)
            }
        } else {
            defaults.set(true, forKey: kFirstUseDone)
        }
    }

    private func resetIfNeeded() {
        let today = Self.dayString(Date())
        let last = defaults.string(forKey: kLastReset)
        if last != today {
            defaults.set(today, forKey: kLastReset)
            defaults.set(20, forKey: kSubscriberLeft)
            subscriberUsesLeft = 20
        }
    }

    private static func dayString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
