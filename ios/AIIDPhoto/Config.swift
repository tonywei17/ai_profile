import Foundation

enum Config {
    /// Backend proxy base URL (production — hides API key server-side)
    static var backendBaseURL: URL? {
        if let s = Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String,
           !s.isEmpty {
            return URL(string: s)
        }
        return nil
    }
}
