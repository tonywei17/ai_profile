import Foundation
import UIKit

// MARK: - Error Types

enum GeminiError: LocalizedError {
    case invalidConfig
    case invalidImage
    case networkError(statusCode: Int, message: String)
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .invalidConfig:
            return "API 配置无效，请检查网络设置"
        case .invalidImage:
            return "图片格式无效，请选择其他照片"
        case .networkError(let code, let msg):
            return "服务器错误 (\(code))：\(msg)"
        case .decodeFailed:
            return "无法解析生成结果，请重试"
        }
    }
}

// MARK: - Codable Models (Backend Proxy)

struct BackendGenerateRequest: Encodable {
    let image: String   // base64
    let prompt: String
}

struct BackendGenerateResponse: Decodable {
    let image: String   // base64 result
}

struct BackendErrorResponse: Decodable {
    let error: String
}

// MARK: - Codable Models (Google Gemini Direct)

struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
}

struct GeminiContent: Encodable {
    let parts: [GeminiPart]
}

enum GeminiPart: Encodable {
    case text(String)
    case inlineData(mimeType: String, data: String)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let text):
            try container.encode(["text": text])
        case .inlineData(let mimeType, let data):
            try container.encode([
                "inline_data": [
                    "mime_type": mimeType,
                    "data": data
                ]
            ])
        }
    }
}

struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]?
    let error: GeminiAPIError?
}

struct GeminiCandidate: Decodable {
    let content: GeminiResponseContent
}

struct GeminiResponseContent: Decodable {
    let parts: [GeminiResponsePart]
}

struct GeminiResponsePart: Decodable {
    let text: String?
    let inlineData: GeminiInlineData?

    enum CodingKeys: String, CodingKey {
        case text
        case inlineData = "inline_data"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        // Support both snake_case and camelCase from API
        if let data = try container.decodeIfPresent(GeminiInlineData.self, forKey: .inlineData) {
            inlineData = data
        } else {
            inlineData = nil
        }
    }
}

struct GeminiInlineData: Decodable {
    let mimeType: String?
    let data: String

    enum CodingKeys: String, CodingKey {
        case mimeType = "mime_type"
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode(String.self, forKey: .data)
        mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType)
    }
}

struct GeminiAPIError: Decodable {
    let code: Int?
    let message: String?
}

// MARK: - Service

final class GeminiService {
    static let shared = GeminiService()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()

    private init() {}

    // MARK: - Public API

    func generateIDPhoto(from image: UIImage, prompt: String) async throws -> UIImage {
        guard let jpegData = image.jpegData(compressionQuality: 0.9) else {
            throw GeminiError.invalidImage
        }

        let base64 = jpegData.base64EncodedString()

        // Prefer backend proxy if configured, fallback to direct Gemini
        if let backendURL = Config.backendBaseURL {
            return try await requestViaBackend(base64: base64, prompt: prompt, backendURL: backendURL)
        } else if let endpoint = Config.geminiEndpointURL, let apiKey = Config.geminiAPIKey, !apiKey.isEmpty {
            return try await requestDirectGemini(base64: base64, prompt: prompt, endpoint: endpoint, apiKey: apiKey)
        } else {
            throw GeminiError.invalidConfig
        }
    }

    func generateIDPhoto(from image: UIImage) async throws -> UIImage {
        let defaultPrompt = "生成证件照：浅色纯色背景，35x45mm，正脸居中，头肩框图，光照均匀，自然风格。"
        return try await generateIDPhoto(from: image, prompt: defaultPrompt)
    }

    // MARK: - Backend Proxy

    private func requestViaBackend(base64: String, prompt: String, backendURL: URL) async throws -> UIImage {
        let url = backendURL.appendingPathComponent("api/gemini/generate")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 60

        let body = BackendGenerateRequest(image: base64, prompt: prompt)
        req.httpBody = try encoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            if let errorResp = try? decoder.decode(BackendErrorResponse.self, from: data) {
                throw GeminiError.networkError(statusCode: http.statusCode, message: errorResp.error)
            }
            let raw = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GeminiError.networkError(statusCode: http.statusCode, message: raw)
        }

        let result = try decoder.decode(BackendGenerateResponse.self, from: data)
        guard let imgData = Data(base64Encoded: result.image),
              let uiImage = UIImage(data: imgData) else {
            throw GeminiError.decodeFailed
        }
        return uiImage
    }

    // MARK: - Direct Gemini (fallback / development)

    private func requestDirectGemini(base64: String, prompt: String, endpoint: URL, apiKey: String) async throws -> UIImage {
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        req.timeoutInterval = 60

        let body = GeminiRequest(contents: [
            GeminiContent(parts: [
                .text(prompt),
                .inlineData(mimeType: "image/jpeg", data: base64)
            ])
        ])
        req.httpBody = try encoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let geminiResp = try? decoder.decode(GeminiResponse.self, from: data)
            let message = geminiResp?.error?.message ?? String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GeminiError.networkError(statusCode: http.statusCode, message: message)
        }

        let geminiResp = try decoder.decode(GeminiResponse.self, from: data)

        guard let candidates = geminiResp.candidates, let first = candidates.first else {
            throw GeminiError.decodeFailed
        }

        for part in first.content.parts {
            if let inline = part.inlineData,
               let imgData = Data(base64Encoded: inline.data),
               let uiImage = UIImage(data: imgData) {
                return uiImage
            }
        }

        throw GeminiError.decodeFailed
    }
}
