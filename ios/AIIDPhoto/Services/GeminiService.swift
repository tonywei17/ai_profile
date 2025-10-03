import Foundation
import UIKit

enum GeminiError: Error { case invalidConfig, network, decode }

final class GeminiService {
    static let shared = GeminiService()
    private init() {}

    // MARK: - Public API
    func generateIDPhoto(from image: UIImage) async throws -> UIImage {
        guard let apiKey = Config.geminiAPIKey, let endpoint = Config.geminiEndpointURL else {
            throw GeminiError.invalidConfig
        }

        guard let jpegData = image.jpegData(compressionQuality: 0.9) else {
            throw GeminiError.network
        }

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let base64 = jpegData.base64EncodedString()
        let body: [String: Any] = [
            "image": base64,
            "style": "id_photo",
            "size": "35x45mm"
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw GeminiError.network
        }

        // Expected: { "image": "base64..." }
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let b64 = dict["image"] as? String,
           let imgData = Data(base64Encoded: b64),
           let ui = UIImage(data: imgData) {
            return ui
        }
        throw GeminiError.decode
    }
}
