import Foundation
import UIKit

@MainActor
final class ReferralManager: ObservableObject {
    @Published private(set) var referralCode: String?
    @Published private(set) var bonusGenerations: Int = 0
    @Published var redeemError: String?

    private let defaults = UserDefaults.standard
    private let kBonusKey = "aiid.referral.bonus"
    private let kCodeKey = "aiid.referral.code"

    init() {
        bonusGenerations = defaults.integer(forKey: kBonusKey)
        referralCode = defaults.string(forKey: kCodeKey)
    }

    var deviceId: String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }

    // MARK: - Register

    func registerCode() async {
        guard referralCode == nil else { return }
        guard let backendURL = Config.backendBaseURL else { return }
        let url = backendURL.appendingPathComponent("api/referral/register")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["deviceId": deviceId])

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let response = try? JSONDecoder().decode(RegisterResponse.self, from: data) else { return }
        referralCode = response.code
        defaults.set(response.code, forKey: kCodeKey)
    }

    // MARK: - Redeem

    func redeemCode(_ code: String) async -> Bool {
        guard let backendURL = Config.backendBaseURL else { return false }
        let url = backendURL.appendingPathComponent("api/referral/redeem")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["code": code, "deviceId": deviceId])

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse else {
            redeemError = "Network error"
            return false
        }

        if http.statusCode == 200,
           let result = try? JSONDecoder().decode(RedeemResponse.self, from: data) {
            bonusGenerations += result.granted
            defaults.set(bonusGenerations, forKey: kBonusKey)
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
        defaults.set(bonusGenerations, forKey: kBonusKey)
        return true
    }

    // MARK: - Models

    private struct RegisterResponse: Codable { let code: String }
    private struct RedeemResponse: Codable { let granted: Int; let message: String }
    private struct ErrorResponse: Codable { let error: String }
}
