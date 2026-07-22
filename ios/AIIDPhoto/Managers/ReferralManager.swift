import Foundation
import UIKit

/// Referral network errors. `redeemCode` keeps its existing `redeemError: String?` surface for UI
/// compatibility; this type exists for the newer status/claim requests to log typed failures.
enum ReferralError: LocalizedError {
    case backendUnavailable
    case network(underlying: Error)
    case decodeFailed
    case server(message: String)

    var errorDescription: String? {
        switch self {
        case .backendUnavailable: return "服务器地址未配置"
        case .network(let e):     return "网络请求失败：\(e.localizedDescription)"
        case .decodeFailed:       return "无法解析服务器返回的数据"
        case .server(let message): return message
        }
    }
}

/// Read-only snapshot of the current device's referral standing (owner side).
struct ReferralStatus: Codable {
    let code: String
    let redeemCount: Int
    let claimedRewardCount: Int
    let unclaimedGenerations: Int
    let trialEligible: Bool
    let trialGranted: Bool
}

/// Result of a (possibly no-op) claim call.
struct ClaimResult: Codable {
    let grantedGenerations: Int
    let grantedTrialDays: Int
    let redeemCount: Int
    let claimedRewardCount: Int
    let trialGranted: Bool
}

@MainActor
final class ReferralManager: ObservableObject {
    @Published private(set) var referralCode: String?
    @Published private(set) var bonusGenerations: Int = 0
    @Published private(set) var status: ReferralStatus?
    /// Offline-friendly fallback count of people invited (mirrors status.redeemCount once fetched).
    @Published private(set) var invitedCount: Int = 0
    @Published var redeemError: String?

    private let kBonusKey = "aiid.referral.bonus"
    private let kCodeKey = "aiid.referral.code"
    private let kInvitedCountKey = "aiid.referral.invitedCount"
    private let kPendingClaimIdKey = "aiid.referral.pendingClaimId"
    private let kLastAppliedClaimIdKey = "aiid.referral.lastAppliedClaimId"
    private let kServerRegisteredKey = "aiid.referral.serverRegistered"
    private let kDeviceIdKey = "aiid.referral.deviceId"

    // Migration flag (UserDefaults → Keychain, one-time)
    private let kMigrated = "aiid.referral.keychainMigrated"

    /// Serializes claim calls so two concurrent `.task`s (e.g. root view + Settings) can't both
    /// apply the same server-replayed claim result. See `claimRewards`.
    private var claimInFlight = false

    init() {
        migrateToKeychainIfNeeded()
        bonusGenerations = KeychainHelper.readInt(key: kBonusKey) ?? 0
        referralCode = KeychainHelper.readString(key: kCodeKey)
        invitedCount = KeychainHelper.readInt(key: kInvitedCountKey) ?? 0
    }

    /// Stable per-install device id. `identifierForVendor` is normally stable, but returns nil
    /// briefly (e.g. before first unlock); reading it raw each time would then mint a *new* random
    /// UUID per access, so register/status/claim would disagree on the id. Compute once and
    /// persist any fallback so every referral call uses the same id.
    private lazy var _deviceId: String = {
        if let idfv = UIDevice.current.identifierForVendor?.uuidString { return idfv }
        if let cached = KeychainHelper.readString(key: kDeviceIdKey) { return cached }
        let generated = UUID().uuidString
        KeychainHelper.saveString(key: kDeviceIdKey, value: generated)
        return generated
    }()

    var deviceId: String { _deviceId }

    // MARK: - Migration

    private func migrateToKeychainIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: kMigrated) else { return }
        // Migrate bonus count
        let bonus = defaults.integer(forKey: kBonusKey)
        if bonus > 0 { KeychainHelper.saveInt(key: kBonusKey, value: bonus) }
        // Migrate code
        if let code = defaults.string(forKey: kCodeKey) {
            KeychainHelper.saveString(key: kCodeKey, value: code)
        }
        // Clean up UserDefaults
        defaults.removeObject(forKey: kBonusKey)
        defaults.removeObject(forKey: kCodeKey)
        defaults.set(true, forKey: kMigrated)
    }

    // MARK: - Register

    func registerCode() async {
        // Gate on a one-time "registered server-side" marker, NOT on `referralCode == nil`.
        // Installs that cached a code under the old in-memory backend still need to hit /register
        // once so Firestore actually creates the code doc — otherwise redeemers get 404 and the
        // whole referral chain silently fails for existing users.
        if referralCode != nil, KeychainHelper.readString(key: kServerRegisteredKey) != nil { return }
        guard let backendURL = Config.backendBaseURL else { return }
        let url = backendURL.appendingPathComponent("api/referral/register")
        var request = Config.authenticatedRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode(["deviceId": deviceId])

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let response = try? JSONDecoder().decode(RegisterResponse.self, from: data) else { return }
        referralCode = response.code
        KeychainHelper.saveString(key: kCodeKey, value: response.code)
        KeychainHelper.saveString(key: kServerRegisteredKey, value: "1")
    }

    // MARK: - Redeem

    func redeemCode(_ code: String) async -> Bool {
        guard let backendURL = Config.backendBaseURL else { return false }
        let url = backendURL.appendingPathComponent("api/referral/redeem")
        var request = Config.authenticatedRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode(["code": code, "deviceId": deviceId])

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse else {
            redeemError = "Network error"
            return false
        }

        if http.statusCode == 200,
           let result = try? JSONDecoder().decode(RedeemResponse.self, from: data) {
            bonusGenerations += result.granted
            KeychainHelper.saveInt(key: kBonusKey, value: bonusGenerations)
            redeemError = nil
            return true
        } else if let errorResp = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            redeemError = errorResp.error
            return false
        }
        redeemError = "Invalid code"
        return false
    }

    // MARK: - Use Bonus

    func useBonusGeneration() -> Bool {
        guard bonusGenerations > 0 else { return false }
        bonusGenerations -= 1
        KeychainHelper.saveInt(key: kBonusKey, value: bonusGenerations)
        return true
    }

    // MARK: - Status (owner side, read-only)

    /// Fetches the current device's referral standing. Best-effort — silently no-ops on failure
    /// since this is a background refresh, not a user-initiated action.
    func refreshStatus() async {
        guard let backendURL = Config.backendBaseURL else { return }
        let url = backendURL.appendingPathComponent("api/referral/status")
        var request = Config.authenticatedRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode(["deviceId": deviceId])

        do {
            let (data, response) = try await Self.fetch(request)
            let result = try Self.decodeOrThrow(ReferralStatus.self, data: data, response: response)
            status = result
            if referralCode == nil {
                referralCode = result.code
                KeychainHelper.saveString(key: kCodeKey, value: result.code)
            }
            invitedCount = result.redeemCount
            KeychainHelper.saveInt(key: kInvitedCountKey, value: result.redeemCount)
        } catch {
            #if DEBUG
            print("[ReferralManager] refreshStatus failed: \((error as? ReferralError)?.errorDescription ?? error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Claim (owner side, idempotent)

    /// Claims any outstanding referral rewards (bonus generations + the one-time 3-day Pro trial).
    /// Idempotency is enforced server-side by `requestId`: the id is persisted in Keychain *before*
    /// the request and only cleared after rewards have landed locally, so a retried call after a
    /// crash/lost-response always replays the same result instead of double-granting.
    @discardableResult
    func claimRewards(applyTrial: (Int) -> Void) async -> ClaimResult? {
        guard let backendURL = Config.backendBaseURL else { return nil }
        // Scenario (a): two concurrent claims (root view + Settings both fire on appear) would read
        // the same requestId; the server replays the same non-zero result to both, and each response
        // would `+=` locally → doubled rewards. Serialize with an in-flight flag (set synchronously
        // before the first await, so @MainActor re-entrancy can't slip a second call past it).
        guard !claimInFlight else { return nil }
        claimInFlight = true
        defer { claimInFlight = false }

        let requestId = pendingClaimRequestId()
        let url = backendURL.appendingPathComponent("api/referral/claim")
        var request = Config.authenticatedRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode(["deviceId": deviceId, "requestId": requestId])

        do {
            let (data, response) = try await Self.fetch(request)
            let result = try Self.decodeOrThrow(ClaimResult.self, data: data, response: response)

            // Scenario (b): a crash between applying rewards and clearing the pending id would, on
            // retry, replay the same server result and `+=` again. Only account for a given
            // requestId once locally — the server already made the counts idempotent.
            let alreadyApplied = KeychainHelper.readString(key: kLastAppliedClaimIdKey) == requestId
            if !alreadyApplied {
                if result.grantedGenerations > 0 {
                    bonusGenerations += result.grantedGenerations
                    KeychainHelper.saveInt(key: kBonusKey, value: bonusGenerations)
                }
                if result.grantedTrialDays > 0 {
                    applyTrial(result.grantedTrialDays)
                }
                KeychainHelper.saveString(key: kLastAppliedClaimIdKey, value: requestId)
            }
            // Rewards have landed (or were already applied) — safe to clear the pending id now.
            KeychainHelper.delete(key: kPendingClaimIdKey)

            invitedCount = result.redeemCount
            KeychainHelper.saveInt(key: kInvitedCountKey, value: result.redeemCount)
            // Keep the cached status in sync without a second round trip.
            if let current = status {
                status = ReferralStatus(
                    code: current.code,
                    redeemCount: result.redeemCount,
                    claimedRewardCount: result.claimedRewardCount,
                    unclaimedGenerations: 0,
                    trialEligible: false,
                    trialGranted: result.trialGranted
                )
            }
            return result
        } catch {
            #if DEBUG
            print("[ReferralManager] claimRewards failed: \((error as? ReferralError)?.errorDescription ?? error.localizedDescription)")
            #endif
            return nil
        }
    }

    /// Convenience: refreshes status first, then claims only if there's something to claim (or a
    /// prior claim never confirmed locally). Safe to call on every launch/foreground.
    @discardableResult
    func refreshAndClaim(applyTrial: (Int) -> Void) async -> ClaimResult? {
        await refreshStatus()
        let hasPendingClaim = KeychainHelper.readString(key: kPendingClaimIdKey) != nil
        let hasUnclaimed = (status?.unclaimedGenerations ?? 0) > 0
        let trialEligible = status?.trialEligible ?? false
        guard hasPendingClaim || hasUnclaimed || trialEligible else { return nil }
        return await claimRewards(applyTrial: applyTrial)
    }

    private func pendingClaimRequestId() -> String {
        if let existing = KeychainHelper.readString(key: kPendingClaimIdKey) {
            return existing
        }
        let newId = UUID().uuidString
        KeychainHelper.saveString(key: kPendingClaimIdKey, value: newId)
        return newId
    }

    // MARK: - Share Message

    /// Share-sheet copy: app one-liner + App Store link + this device's referral code.
    /// Japanese copy must never nudge for reviews/評価 (ステマ規制 compliance) — keep it that way.
    func shareMessage(language: AppLanguage) -> String {
        let code = referralCode ?? ""
        let body = l(
            language,
            zh: "AI证件照 App 一键生成媲美影楼品质的证件照。用我的推荐码「\(code)」下载注册，即得 3 次免费 Pro 品质生成！",
            en: "Studio-quality ID photos, right from your phone — AI ID Photo. Use my code \"\(code)\" to get 3 free Pro-quality generations!",
            ja: "AI証明写真アプリで、スタジオ品質の証明写真がすぐ作れます。紹介コード「\(code)」を入力すると、Pro品質の生成が3回無料になります！",
            ko: "AI 증명사진 앱으로 스튜디오 품질의 증명사진을 바로 만들어보세요. 추천 코드 「\(code)」를 입력하면 Pro 품질 생성 3회를 무료로 드립니다!",
            vi: "Tạo ảnh thẻ chất lượng studio ngay trên điện thoại với AI ID Photo. Dùng mã \"\(code)\" để nhận 3 lần tạo ảnh Pro miễn phí!",
            id: "Buat foto ID berkualitas studio langsung dari ponsel dengan AI ID Photo. Gunakan kode \"\(code)\" untuk 3 kali generasi Pro gratis!",
            pt: "Fotos de documento com qualidade de estúdio no AI ID Photo. Use o código \"\(code)\" e ganhe 3 gerações Pro grátis!"
        )
        return "\(body) \(Config.appStoreURL.absoluteString)"
    }

    private func l(_ language: AppLanguage, zh: String, en: String, ja: String, ko: String, vi: String, id: String, pt: String) -> String {
        switch language {
        case .chineseSimplified: return zh
        case .japanese:          return ja
        case .korean:            return ko
        case .vietnamese:        return vi
        case .indonesian:        return id
        case .portuguese:        return pt
        case .english, .system:  return en
        }
    }

    // MARK: - Networking Helper

    private static func fetch(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            throw ReferralError.network(underlying: error)
        }
    }

    private static func decodeOrThrow<T: Decodable>(_ type: T.Type, data: Data, response: URLResponse) throws -> T {
        guard let http = response as? HTTPURLResponse else { throw ReferralError.decodeFailed }
        guard http.statusCode == 200 else {
            let message = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.error ?? "HTTP \(http.statusCode)"
            throw ReferralError.server(message: message)
        }
        guard let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            throw ReferralError.decodeFailed
        }
        return decoded
    }

    // MARK: - Models

    private struct RegisterResponse: Codable { let code: String }
    private struct RedeemResponse: Codable { let granted: Int; let message: String }
    private struct ErrorResponse: Codable { let error: String }
}
