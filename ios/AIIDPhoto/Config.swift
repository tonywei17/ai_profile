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

    // MARK: - App Store

    /// TODO(Wei): App Store Connect 上架后填真实数字 ID(apps.apple.com/app/idXXXXXXXXXX)
    static let appStoreID = "0000000000"  // TODO: placeholder

    static var appStoreURL: URL { URL(string: "https://apps.apple.com/app/id\(appStoreID)")! }
}
