import Foundation
import UIKit

enum GeminiError: Error { case invalidConfig, network, decode }

final class GeminiService {
    static let shared = GeminiService()
    private init() {}

    // MARK: - Public API
    func generateIDPhoto(from image: UIImage, prompt: String) async throws -> UIImage {
        guard let apiKey = Config.geminiAPIKey, let endpoint = Config.geminiEndpointURL else {
            throw GeminiError.invalidConfig
        }

        guard let jpegData = image.jpegData(compressionQuality: 0.9) else {
            throw GeminiError.network
        }

        // Determine if using Google Gemini official endpoint
        let isGoogle = (endpoint.host?.contains("googleapis.com") == true)
        var requestURL = endpoint
        var req: URLRequest

        if isGoogle {
            // Use x-goog-api-key header for Image Generation endpoints
            req = URLRequest(url: requestURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

            let base64 = jpegData.base64EncodedString()
            // Build request per Image Generation docs (image-to-image editing)
            let body: [String: Any] = [
                "contents": [[
                    "parts": [
                        ["text": prompt],
                        ["inline_data": [
                            "mime_type": "image/jpeg",
                            "data": base64
                        ]]
                    ]
                ]]
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        } else {
            // Original nanobanana proxy schema: { image: base64 } -> { image: base64 }
            req = URLRequest(url: requestURL)
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
        }

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            // Try parse Google error: { error: { code, message, status } }
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = obj["error"] as? [String: Any],
               let msg = err["message"] as? String {
                throw NSError(domain: "GeminiHTTP", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(msg)"])
            }
            // Fallback to raw text
            let raw = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "GeminiHTTP", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(raw)"])
        }

        if isGoogle {
            // Parse Google response: candidates[0].content.parts[*].inline_data.data (base64)
            if let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = root["candidates"] as? [[String: Any]],
               let first = candidates.first,
               let content = first["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]] {
                // Find first part containing inline_data
                for part in parts {
                    let inline = (part["inline_data"] as? [String: Any]) ?? (part["inlineData"] as? [String: Any])
                    if let inline = inline,
                       let b64 = inline["data"] as? String,
                       let imgData = Data(base64Encoded: b64),
                       let ui = UIImage(data: imgData) {
                        return ui
                    }
                }
            }
            throw GeminiError.decode
        } else {
            // Parse proxy response: { "image": "base64..." }
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let b64 = dict["image"] as? String,
               let imgData = Data(base64Encoded: b64),
               let ui = UIImage(data: imgData) {
                return ui
            }
            throw GeminiError.decode
        }
    }

    // Convenience with default prompt
    func generateIDPhoto(from image: UIImage) async throws -> UIImage {
        let defaultPrompt = "生成证件照：浅色纯色背景，35x45mm，正脸居中，头肩框图，光照均匀，自然风格。"
        return try await generateIDPhoto(from: image, prompt: defaultPrompt)
    }
}
