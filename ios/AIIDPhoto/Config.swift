import Foundation

enum Config {
    // Put your endpoint here, e.g., https://your-proxy.example.com/gemini/nanobanana
    static var geminiEndpointURL: URL? {
        if let s = Bundle.main.object(forInfoDictionaryKey: "GEMINI_ENDPOINT") as? String {
            return URL(string: s)
        }
        return nil
    }

    static var geminiAPIKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String
    }
}
