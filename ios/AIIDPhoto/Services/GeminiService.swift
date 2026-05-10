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
            return Self.localizedNetworkMessage(code: code, raw: msg)
        case .decodeFailed:
            return "生成结果解析失败，请重试"
        }
    }

    /// 是否可以通过重试解决（用于 UI 显示"重试"按钮）。
    var isRetryable: Bool {
        switch self {
        case .invalidImage:                       return false
        case .invalidConfig, .decodeFailed:       return true
        case .networkError(let code, _):          return code >= 500 || code == 408 || code == 429
        }
    }

    private static func localizedNetworkMessage(code: Int, raw: String) -> String {
        // 把后端返回的英文消息映射为中文，未匹配的保留原文作为兜底。
        let lower = raw.lowercased()
        if code == 429 || lower.contains("too many") || lower.contains("rate limit") {
            return "请求太频繁了，请稍后再试。"
        }
        if code == 503 || lower.contains("temporarily unavailable") {
            return "服务繁忙，请稍后再试。"
        }
        if code == 413 || lower.contains("too large") {
            return "图片太大了，请换一张更小的照片。"
        }
        if code == 400 && (lower.contains("invalid") || lower.contains("format")) {
            return "照片格式或参数不正确，请换一张试试。"
        }
        if code == 502 || lower.contains("generation failed") {
            return "生成失败，请重试。如多次失败请换一张更清晰的正面照。"
        }
        if code == 401 || code == 403 {
            return "服务暂时无法访问，请稍后再试。"
        }
        if code >= 500 {
            return "服务暂时不可用，请稍后再试。"
        }
        return raw.isEmpty ? "网络异常，请检查网络后重试。" : raw
    }
}

// MARK: - Codable Models (Backend Proxy)

struct BackendGenerateRequest: Encodable {
    let image: String
    let prompt: String
    let cosmeticPrompt: String?  // 第二阶段：Hivision 输出后叠加的外观编辑指令
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

    func generateIDPhoto(from image: UIImage, prompt: String, tier: OutputTier = .pro, specInfo: SpecInfo? = nil, cosmeticPrompt: String? = nil) async throws -> UIImage {
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
        let cleanCosmetic = cosmeticPrompt.map { sanitizePrompt($0) }
        return try await requestViaBackend(base64: base64, prompt: cleanPrompt, tier: tier, backendURL: backendURL, specInfo: specInfo, cosmeticPrompt: cleanCosmetic)
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

    private func requestViaBackend(base64: String, prompt: String, tier: OutputTier, backendURL: URL, specInfo: SpecInfo? = nil, cosmeticPrompt: String? = nil) async throws -> UIImage {
        let url = backendURL.appendingPathComponent("api/gemini/generate")
        var req = Config.authenticatedRequest(url: url)
        req.httpMethod = "POST"
        // HivisionIDPhotos cold start can take ~60s; keep 150s for safety
        req.timeoutInterval = 150

        let body = BackendGenerateRequest(
            image: base64,
            prompt: prompt,
            cosmeticPrompt: cosmeticPrompt,
            tier: tier.apiValue,
            specWidth: specInfo?.widthPx,
            specHeight: specInfo?.heightPx,
            specBgColor: specInfo?.bgColorHex
        )
        req.httpBody = try encoder.encode(body)

        // Retry up to 2 times for transient network errors
        var lastURLError: URLError?
        for attempt in 0..<3 {
            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                return try decodeBackendResponse(data: data, response: response)
            } catch let error as URLError where error.code == .timedOut || error.code == .networkConnectionLost || error.code == .notConnectedToInternet {
                lastURLError = error
                if attempt < 2 {
                    try await Task.sleep(for: .seconds(pow(2.0, Double(attempt))))
                }
            }
        }
        // 网络重试均失败，包装为中文 GeminiError 让 UI 友好提示
        let msg: String
        switch lastURLError?.code {
        case .timedOut:                msg = "请求超时，请检查网络后重试。"
        case .notConnectedToInternet:  msg = "网络未连接，请检查网络设置后重试。"
        case .networkConnectionLost:   msg = "网络连接中断，请重试。"
        default:                       msg = "网络异常，请检查网络后重试。"
        }
        throw GeminiError.networkError(statusCode: 0, message: msg)
    }

    /// Robust base64 → UIImage: handles data URL prefix, whitespace, url-safe chars, padding.
    private static func decodeBase64Image(_ raw: String) -> UIImage? {
        var b64 = raw
        // Strip data URL prefix if present (e.g. "data:image/png;base64,")
        if let range = b64.range(of: #"^data:image/[^;]+;base64,"#, options: .regularExpression) {
            b64.removeSubrange(range)
        }
        b64 = b64.components(separatedBy: .whitespacesAndNewlines).joined()
        b64 = b64.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let rem = b64.count % 4
        if rem == 2 { b64 += "==" } else if rem == 3 { b64 += "=" }
        guard let data = Data(base64Encoded: b64, options: .ignoreUnknownCharacters) else { return nil }
        return UIImage(data: data)
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
        guard let uiImage = Self.decodeBase64Image(result.image) else {
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
