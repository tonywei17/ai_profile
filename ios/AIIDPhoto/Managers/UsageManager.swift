import Foundation

@MainActor
final class UsageManager: ObservableObject {
    enum Decision { case allowed, requireRewardedAd, reachedDailyLimit, reachedLimit }

    @Published private(set) var subscriberUsesLeft: Int = 20
    @Published private(set) var freeUsesToday: Int = 0

    private let defaults = UserDefaults.standard
    private let kFirstUseDone = "aiid.firstUseDone"
    private let kLastReset = "aiid.lastReset"
    private let kSubscriberLeft = "aiid.subscriber.left"
    private let kFreeUsesToday = "aiid.free.usesToday"

    static let freeDailyLimit = 5

    init() {
        resetIfNeeded()
        subscriberUsesLeft = defaults.integer(forKey: kSubscriberLeft)
        if subscriberUsesLeft == 0 { subscriberUsesLeft = 20 }
        freeUsesToday = defaults.integer(forKey: kFreeUsesToday)
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
                defaults.set(subscriberUsesLeft, forKey: kSubscriberLeft)
            }
        } else {
            defaults.set(true, forKey: kFirstUseDone)
            freeUsesToday += 1
            defaults.set(freeUsesToday, forKey: kFreeUsesToday)
        }
    }

    private func resetIfNeeded() {
        let today = Self.dayString(Date())
        let last = defaults.string(forKey: kLastReset)
        if last != today {
            defaults.set(today, forKey: kLastReset)
            defaults.set(20, forKey: kSubscriberLeft)
            subscriberUsesLeft = 20
            defaults.set(0, forKey: kFreeUsesToday)
            freeUsesToday = 0
        }
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
