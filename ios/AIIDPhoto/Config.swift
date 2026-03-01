import Foundation

enum Config {
    /// Backend proxy base URL (preferred for production — hides API key server-side)
    static var backendBaseURL: URL? {
        if let s = Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String,
           !s.isEmpty {
            return URL(string: s)
        }
        return nil
    }

    /// Direct Gemini endpoint (fallback for development only)
    static var geminiEndpointURL: URL? {
        if let s = Bundle.main.object(forInfoDictionaryKey: "GEMINI_ENDPOINT") as? String,
           !s.isEmpty {
            return URL(string: s)
        }
        return nil
    }

    /// Direct Gemini API key (fallback for development only)
    /// FIXME: Remove before production — use backend proxy instead
    static var geminiAPIKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String
    }
}
