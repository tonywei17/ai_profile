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
            return "服务配置异常，请检查网络设置后重试"
        case .invalidImage:
            return "图片格式不支持，请换一张照片"
        case .networkError(let code, let msg):
            return "服务器错误（\(code)）：\(msg)"
        case .decodeFailed:
            return "生成结果解析失败，请重试"
        }
    }
}

// MARK: - Codable Models (Backend Proxy)

struct BackendGenerateRequest: Encodable {
    let image: String
    let prompt: String
    let tier: String
    let specWidth: Int?
    let specHeight: Int?
    let specBgColor: String?
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

    enum OutputTier {
        case free   // 512px max dimension, cheaper model
        case pro    // 1024px max dimension, better model

        var maxDimension: CGFloat { self == .free ? 512 : 1024 }
        var apiValue: String { self == .free ? "free" : "pro" }
    }

    struct SpecInfo {
        let widthPx: Int
        let heightPx: Int
        let bgColorHex: String
    }

    func generateIDPhoto(from image: UIImage, prompt: String, tier: OutputTier = .pro, specInfo: SpecInfo? = nil) async throws -> UIImage {
        guard let backendURL = Config.backendBaseURL else {
            throw GeminiError.invalidConfig
        }

        // HivisionIDPhotos needs higher input resolution for quality face detection
        let maxDim: CGFloat = specInfo != nil ? 1500 : tier.maxDimension

        let base64 = try await Task.detached(priority: .userInitiated) {
            let processed = image.capped(to: maxDim)
            guard let jpegData = processed.jpegData(compressionQuality: 0.92) else {
                throw GeminiError.invalidImage
            }
            let b64 = jpegData.base64EncodedString()
            guard b64.count < 10_000_000 else { throw GeminiError.invalidImage }
            return b64
        }.value

        let cleanPrompt = sanitizePrompt(prompt)
        return try await requestViaBackend(base64: base64, prompt: cleanPrompt, tier: tier, backendURL: backendURL, specInfo: specInfo)
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

    private func requestViaBackend(base64: String, prompt: String, tier: OutputTier, backendURL: URL, specInfo: SpecInfo? = nil) async throws -> UIImage {
        let url = backendURL.appendingPathComponent("api/gemini/generate")
        var req = Config.authenticatedRequest(url: url)
        req.httpMethod = "POST"
        // HivisionIDPhotos cold start can take ~60s; keep 150s for safety
        req.timeoutInterval = 150

        let body = BackendGenerateRequest(
            image: base64,
            prompt: prompt,
            tier: tier.apiValue,
            specWidth: specInfo?.widthPx,
            specHeight: specInfo?.heightPx,
            specBgColor: specInfo?.bgColorHex
        )
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
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            if let errorResp = try? decoder.decode(BackendErrorResponse.self, from: data) {
                throw GeminiError.networkError(statusCode: http.statusCode, message: errorResp.error)
            }
            let raw = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GeminiError.networkError(statusCode: http.statusCode, message: raw)
        }

        let result = try decoder.decode(BackendGenerateResponse.self, from: data)
        // .ignoreUnknownCharacters handles \n inserted by Python's base64.encodebytes
        guard let imgData = Data(base64Encoded: result.image, options: .ignoreUnknownCharacters),
              let uiImage = UIImage(data: imgData) else {
            throw GeminiError.decodeFailed
        }
        return uiImage
    }
}

// MARK: - UIImage Resize Helper

private extension UIImage {
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
