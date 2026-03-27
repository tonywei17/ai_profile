import Foundation
import UIKit

@MainActor
final class ReferralManager: ObservableObject {
    @Published private(set) var referralCode: String?
    @Published private(set) var bonusGenerations: Int = 0
    @Published var redeemError: String?

    private let kBonusKey = "aiid.referral.bonus"
    private let kCodeKey = "aiid.referral.code"

    // Migration flag (UserDefaults → Keychain, one-time)
    private let kMigrated = "aiid.referral.keychainMigrated"

    init() {
        migrateToKeychainIfNeeded()
        bonusGenerations = KeychainHelper.readInt(key: kBonusKey) ?? 0
        referralCode = KeychainHelper.readString(key: kCodeKey)
    }

    var deviceId: String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }

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
        guard referralCode == nil else { return }
        guard let backendURL = Config.backendBaseURL else { return }
        let url = backendURL.appendingPathComponent("api/referral/register")
        var request = Config.authenticatedRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode(["deviceId": deviceId])

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let response = try? JSONDecoder().decode(RegisterResponse.self, from: data) else { return }
        referralCode = response.code
        KeychainHelper.saveString(key: kCodeKey, value: response.code)
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

    // MARK: - Models

    private struct RegisterResponse: Codable { let code: String }
    private struct RedeemResponse: Codable { let granted: Int; let message: String }
    private struct ErrorResponse: Codable { let error: String }
}
