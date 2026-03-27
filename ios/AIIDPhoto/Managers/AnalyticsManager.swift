import Foundation

@MainActor
final class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()

    private let defaults = UserDefaults.standard
    private let kEventsKey = "aiid.analytics.events"
    private let maxStoredEvents = 500

    struct AnalyticsEvent: Codable {
        let name: String
        let timestamp: Date
        let properties: [String: String]?
    }

    // MARK: - Event Names

    enum Event {
        static let appOpen            = "app_open"
        static let onboardingComplete = "onboarding_complete"
        static let photoSelected      = "photo_selected"
        static let generationSuccess  = "generation_success"
        static let generationFailed   = "generation_failed"
        static let paywallShown       = "paywall_shown"
        static let subscriptionStarted = "subscription_started"
        static let adWatched          = "ad_watched"
        static let photoSaved         = "photo_saved"
        static let photoShared        = "photo_shared"
        static let printUsed          = "print_used"
    }

    // MARK: - Track

    func track(_ name: String, properties: [String: String]? = nil) {
        let event = AnalyticsEvent(name: name, timestamp: Date(), properties: properties)
        var events = loadEvents()
        events.append(event)
        if events.count > maxStoredEvents {
            events = Array(events.suffix(maxStoredEvents))
        }
        saveEvents(events)
        #if DEBUG
        let props = properties.map { " \($0)" } ?? ""
        print("[Analytics] \(name)\(props)")
        #endif
    }

    // MARK: - Persistence

    private func loadEvents() -> [AnalyticsEvent] {
        guard let data = defaults.data(forKey: kEventsKey),
              let events = try? JSONDecoder().decode([AnalyticsEvent].self, from: data) else {
            return []
        }
        return events
    }

    private func saveEvents(_ events: [AnalyticsEvent]) {
        do {
            let data = try JSONEncoder().encode(events)
            defaults.set(data, forKey: kEventsKey)
        } catch {
            #if DEBUG
            print("[AnalyticsManager] Failed to save events: \(error)")
            #endif
        }
    }

    // MARK: - Optional flush to backend

    func flush(to backendURL: URL) async {
        let events = loadEvents()
        guard !events.isEmpty else { return }
        var request = URLRequest(url: backendURL.appendingPathComponent("api/analytics/events"))
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(events)
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
        // Clear local events after successful flush
        saveEvents([])
    }
}
