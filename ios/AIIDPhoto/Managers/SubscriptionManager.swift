import Foundation
import StoreKit

/// Represents a subscription plan option.
enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case monthly = "com.nexus.aiidphoto.pro_monthly"
    case annual  = "com.nexus.aiidphoto.pro_annual"

    var id: String { rawValue }

    static let allProductIDs: Set<String> = Set(allCases.map(\.rawValue))
}

@MainActor
final class SubscriptionManager: ObservableObject {

    // MARK: - Debug Override

    /// Set to `true` to simulate a subscribed state on device (DEBUG only).
    #if DEBUG
    static let forceSubscribed = false
    #else
    static let forceSubscribed = false
    #endif

    // MARK: - Published State

    @Published private(set) var isSubscribed: Bool = false
    @Published private(set) var expirationDate: Date?
    @Published private(set) var isPurchasing: Bool = false
    @Published private(set) var isRestoring: Bool = false
    @Published var purchaseError: String?

    /// Currently selected plan for purchase.
    @Published var selectedPlan: SubscriptionPlan = .annual

    /// Per-plan display prices (localized with currency code).
    @Published private(set) var monthlyDisplayPrice: String?
    @Published private(set) var annualDisplayPrice: String?

    // MARK: - Private

    private var products: [SubscriptionPlan: Product] = [:]
    private var updateListenerTask: Task<Void, Never>?

    /// Fallback prices when StoreKit products aren't available.
    private static let fallbackMonthlyPrice = "$1.99 USD"
    private static let fallbackAnnualPrice  = "$12.99 USD"

    // MARK: - Init / Deinit

    init() {
        if Self.forceSubscribed { isSubscribed = true }
        updateListenerTask = Task { await listenForUpdates() }
        Task { await refreshProducts() }
        Task { await checkCurrentEntitlements() }
    }

    deinit { updateListenerTask?.cancel() }

    // MARK: - Product Loading

    func refreshProducts() async {
        do {
            let loaded = try await Product.products(for: SubscriptionPlan.allProductIDs)
            let currencyCode = Locale.current.currency?.identifier ?? ""

            for p in loaded {
                guard let plan = SubscriptionPlan(rawValue: p.id) else { continue }
                products[plan] = p
                let price = "\(p.displayPrice) \(currencyCode)"
                switch plan {
                case .monthly: monthlyDisplayPrice = price
                case .annual:  annualDisplayPrice = price
                }
                print("[SubscriptionManager] loaded: \(p.id) → \(price)")
            }

            // Fallback prices
            if monthlyDisplayPrice == nil {
                monthlyDisplayPrice = Self.fallbackMonthlyPrice
                print("[SubscriptionManager] no monthly product returned, using fallback")
            }
            if annualDisplayPrice == nil {
                annualDisplayPrice = Self.fallbackAnnualPrice
                print("[SubscriptionManager] no annual product returned, using fallback")
            }
        } catch {
            print("[SubscriptionManager] products error: \(error)")
            if monthlyDisplayPrice == nil { monthlyDisplayPrice = Self.fallbackMonthlyPrice }
            if annualDisplayPrice == nil  { annualDisplayPrice = Self.fallbackAnnualPrice }
        }
    }

    /// Display price for the currently selected plan.
    var displayPrice: String? {
        switch selectedPlan {
        case .monthly: return monthlyDisplayPrice
        case .annual:  return annualDisplayPrice
        }
    }

    // MARK: - Entitlement Checking

    func checkCurrentEntitlements() async {
        if Self.forceSubscribed {
            isSubscribed = true
            expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
            return
        }
        var foundActive = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result,
               SubscriptionPlan.allProductIDs.contains(t.productID) {
                let active = t.revocationDate == nil &&
                             (t.expirationDate ?? .distantFuture) > Date()
                isSubscribed = active
                expirationDate = active ? t.expirationDate : nil
                foundActive = active
                await t.finish()
            }
        }
        if !foundActive {
            isSubscribed = false
            expirationDate = nil
        }
    }

    private func listenForUpdates() async {
        for await result in Transaction.updates {
            await handle(result)
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let t) = result,
              SubscriptionPlan.allProductIDs.contains(t.productID) else { return }
        let active = t.revocationDate == nil &&
                     (t.expirationDate ?? .distantFuture) > Date()
        isSubscribed = active
        expirationDate = active ? t.expirationDate : nil
        await t.finish()
    }

    // MARK: - Purchase

    func purchase() async {
        guard let p = products[selectedPlan], !isPurchasing else { return }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }
        do {
            let result = try await p.purchase()
            switch result {
            case .success(let verification): await handle(verification)
            case .userCancelled:             break
            case .pending:                   break
            @unknown default:                break
            }
        } catch StoreKitError.userCancelled {
            // user dismissed sheet — no error needed
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Restore

    func restore() async {
        isRestoring = true
        purchaseError = nil
        defer { isRestoring = false }
        do {
            try await AppStore.sync()
            await checkCurrentEntitlements()
        } catch {
            purchaseError = error.localizedDescription
        }
    }
}
