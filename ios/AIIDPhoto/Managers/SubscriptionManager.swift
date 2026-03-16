import Foundation
import StoreKit

/// Represents a subscription plan option.
enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case monthly = "com.nexus.aiidphoto.pro_monthly"
    case annual  = "com.nexus.aiidphoto.pro_annual"

    var id: String { rawValue }

    static let allProductIDs: Set<String> = Set(allCases.map(\.rawValue))
}

enum ConsumableProduct: String {
    case printLayoutSingle = "com.nexus.aiidphoto.print_layout_single"
}

@MainActor
final class SubscriptionManager: ObservableObject {

    // MARK: - Debug Override

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

    @Published var selectedPlan: SubscriptionPlan = .annual

    @Published private(set) var monthlyDisplayPrice: String?
    @Published private(set) var annualDisplayPrice: String?
    @Published private(set) var printLayoutSingleDisplayPrice: String?

    /// Print layout credits (consumable purchases)
    @Published private(set) var printLayoutCredits: Int = 0

    // MARK: - Private

    private var products: [SubscriptionPlan: Product] = [:]
    private var consumableProducts: [ConsumableProduct: Product] = [:]
    private var updateListenerTask: Task<Void, Never>?

    private static let fallbackMonthlyPrice = "$3.99 USD"
    private static let fallbackAnnualPrice  = "$22.99 USD"
    private static let fallbackPrintSinglePrice = "$3.49 USD"

    private let kPrintLayoutCredits = "aiid.printLayout.credits"

    // MARK: - Init / Deinit

    init() {
        if Self.forceSubscribed { isSubscribed = true }
        printLayoutCredits = UserDefaults.standard.integer(forKey: kPrintLayoutCredits)
        updateListenerTask = Task { await listenForUpdates() }
        Task { await refreshProducts() }
        Task { await checkCurrentEntitlements() }
    }

    deinit { updateListenerTask?.cancel() }

    // MARK: - Product Loading

    func refreshProducts() async {
        let allIDs = SubscriptionPlan.allProductIDs.union([ConsumableProduct.printLayoutSingle.rawValue])
        do {
            let loaded = try await Product.products(for: allIDs)
            let currencyCode = Locale.current.currency?.identifier ?? ""

            for p in loaded {
                let price = "\(p.displayPrice) \(currencyCode)"

                if let plan = SubscriptionPlan(rawValue: p.id) {
                    products[plan] = p
                    switch plan {
                    case .monthly: monthlyDisplayPrice = price
                    case .annual:  annualDisplayPrice = price
                    }
                } else if let consumable = ConsumableProduct(rawValue: p.id) {
                    consumableProducts[consumable] = p
                    switch consumable {
                    case .printLayoutSingle: printLayoutSingleDisplayPrice = price
                    }
                }
                #if DEBUG
                print("[SubscriptionManager] loaded: \(p.id) -> \(price)")
                #endif
            }

            if monthlyDisplayPrice == nil {
                monthlyDisplayPrice = Self.fallbackMonthlyPrice
            }
            if annualDisplayPrice == nil {
                annualDisplayPrice = Self.fallbackAnnualPrice
            }
            if printLayoutSingleDisplayPrice == nil {
                printLayoutSingleDisplayPrice = Self.fallbackPrintSinglePrice
            }
        } catch {
            #if DEBUG
            print("[SubscriptionManager] products error: \(error)")
            #endif
            if monthlyDisplayPrice == nil { monthlyDisplayPrice = Self.fallbackMonthlyPrice }
            if annualDisplayPrice == nil  { annualDisplayPrice = Self.fallbackAnnualPrice }
            if printLayoutSingleDisplayPrice == nil { printLayoutSingleDisplayPrice = Self.fallbackPrintSinglePrice }
        }
    }

    var displayPrice: String? {
        switch selectedPlan {
        case .monthly: return monthlyDisplayPrice
        case .annual:  return annualDisplayPrice
        }
    }

    // MARK: - Print Layout Access

    var canUsePrintLayout: Bool {
        isSubscribed || printLayoutCredits > 0
    }

    func consumePrintLayoutCredit() {
        guard !isSubscribed, printLayoutCredits > 0 else { return }
        printLayoutCredits -= 1
        UserDefaults.standard.set(printLayoutCredits, forKey: kPrintLayoutCredits)
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
        guard case .verified(let t) = result else { return }

        if SubscriptionPlan.allProductIDs.contains(t.productID) {
            let active = t.revocationDate == nil &&
                         (t.expirationDate ?? .distantFuture) > Date()
            isSubscribed = active
            expirationDate = active ? t.expirationDate : nil
        } else if t.productID == ConsumableProduct.printLayoutSingle.rawValue {
            printLayoutCredits += 1
            UserDefaults.standard.set(printLayoutCredits, forKey: kPrintLayoutCredits)
        }

        await t.finish()
    }

    // MARK: - Purchase Subscription

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
            // user dismissed — no error
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Purchase Consumable

    func purchasePrintLayout() async {
        guard let p = consumableProducts[.printLayoutSingle], !isPurchasing else { return }
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
            // user dismissed — no error
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
