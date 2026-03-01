import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published private(set) var isSubscribed: Bool = false
    @Published private(set) var displayPrice: String?

    // TODO: 替换为正式 Product ID
    private let productID = "com.yourcompany.aiidphoto.premium"
    private var product: Product?

    init() {
        Task { await refreshProducts() }
        Task { await checkCurrentEntitlements() }
        Task { await listenForUpdates() }
    }

    private func refreshProducts() async {
        do {
            let products = try await Product.products(for: [productID])
            product = products.first
            if let p = product {
                displayPrice = p.displayPrice
            }
        } catch {
            print("StoreKit products error: \(error)")
        }
    }

    /// Check existing entitlements on launch (finite iteration)
    private func checkCurrentEntitlements() async {
        for await trans in Transaction.currentEntitlements {
            await handle(transaction: trans)
        }
    }

    /// Listen for new transactions (infinite stream, runs for app lifetime)
    private func listenForUpdates() async {
        for await result in Transaction.updates {
            await handle(transaction: result)
        }
    }

    private func handle(transaction: VerificationResult<Transaction>) async {
        guard case .verified(let t) = transaction else { return }
        let active = (t.productID == productID) && (t.revocationDate == nil) && (t.expirationDate ?? .distantFuture) > Date()
        isSubscribed = active
        await t.finish()
    }

    func purchase() async {
        guard let p = product else { return }
        do {
            let result = try await p.purchase()
            switch result {
            case .success(let verification):
                await handle(transaction: verification)
            case .userCancelled, .pending: break
            @unknown default: break
            }
        } catch {
            print("Purchase error: \(error)")
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            print("Restore error: \(error)")
        }
    }
}
