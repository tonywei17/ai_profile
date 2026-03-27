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

    /// Maximum output dimension for each tier.
    /// Free users get 512px (fewer tokens → lower API cost).
    /// Pro users get 1024px (high quality for printing).
    enum OutputTier {
        case free   // 512px max dimension
        case pro    // 1024px max dimension

        var maxDimension: CGFloat { self == .free ? 512 : 1024 }
    }

    func generateIDPhoto(from image: UIImage, prompt: String, tier: OutputTier = .pro) async throws -> UIImage {
        guard let backendURL = Config.backendBaseURL else {
            throw GeminiError.invalidConfig
        }

        // Heavy image processing off the main thread
        let base64 = try await Task.detached(priority: .userInitiated) {
            let processed = image.capped(to: tier.maxDimension)
            guard let jpegData = processed.jpegData(compressionQuality: tier == .free ? 0.85 : 0.9) else {
                throw GeminiError.invalidImage
            }
            let b64 = jpegData.base64EncodedString()
            guard b64.count < 10_000_000 else { throw GeminiError.invalidImage }
            return b64
        }.value

        let cleanPrompt = sanitizePrompt(prompt)
        return try await requestViaBackend(base64: base64, prompt: cleanPrompt, backendURL: backendURL)
    }

    func generateIDPhoto(from image: UIImage) async throws -> UIImage {
        let defaultPrompt = "生成证件照：浅色纯色背景，35x45mm，正脸居中，头肩框图，光照均匀，自然风格。"
        return try await generateIDPhoto(from: image, prompt: defaultPrompt)
    }

    // MARK: - Backend Proxy

    private func sanitizePrompt(_ prompt: String) -> String {
        var clean = prompt
        let blocked = ["ignore previous", "ignore all", "system:", "disregard", "override"]
        for pattern in blocked {
            clean = clean.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }
        return clean
    }

    private func requestViaBackend(base64: String, prompt: String, backendURL: URL) async throws -> UIImage {
        let url = backendURL.appendingPathComponent("api/gemini/generate")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 60

        let body = BackendGenerateRequest(image: base64, prompt: prompt)
        req.httpBody = try encoder.encode(body)

        // Retry up to 2 times for transient network errors
        var lastError: Error?
        for attempt in 0..<3 {
            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                return try decodeBackendResponse(data: data, response: response)
            } catch let error as URLError where error.code == .timedOut || error.code == .networkConnectionLost || error.code == .notConnectedToInternet {
                lastError = error
                if attempt < 2 {
                    try await Task.sleep(for: .seconds(pow(2.0, Double(attempt))))
                }
            }
        }
        throw lastError ?? GeminiError.invalidConfig
    }

    private func decodeBackendResponse(data: Data, response: URLResponse) throws -> UIImage {
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
}

// MARK: - UIImage Resize Helper

private extension UIImage {
    /// Returns a new image whose longest edge is at most `maxDimension` px.
    /// If the image is already within bounds, returns `self` (no copy).
    func capped(to maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
