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

    /// App API key for backend authentication (X-App-Key header)
    static var appApiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "APP_API_KEY") as? String ?? ""
    }

    /// Create a URLRequest with common headers (Content-Type + X-App-Key)
    static func authenticatedRequest(url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let key = appApiKey
        if !key.isEmpty {
            req.setValue(key, forHTTPHeaderField: "X-App-Key")
        }
        return req
    }
}
