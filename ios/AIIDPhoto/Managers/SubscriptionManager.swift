import Foundation
import StoreKit

/// One finished photo order: 3 AI generation attempts, then HD export and print layout.
enum PaidProduct: String, CaseIterable, Identifiable {
    case photoTask3 = "com.yufeicn.aiidphoto.photo_task_3"

    var id: String { rawValue }

    static let allProductIDs: Set<String> = Set(allCases.map(\.rawValue))
}

@MainActor
final class SubscriptionManager: ObservableObject {

    static let attemptsPerPhotoTask = 3

    // Keep this disabled for release parity. StoreKit config should be used for local purchase tests.
    static var forceSubscribed: Bool { false }

    // MARK: - Published State

    @Published private(set) var generationAttemptsLeft: Int = 0
    @Published private(set) var isPurchasing: Bool = false
    @Published private(set) var isRestoring: Bool = false
    @Published var purchaseError: String?

    @Published private(set) var photoTaskDisplayPrice: String?

    // MARK: - Private

    private var products: [PaidProduct: Product] = [:]
    private var updateListenerTask: Task<Void, Never>?

    private static let fallbackPhotoTaskPrice = "¥3.80"
    private let kGenerationAttemptsLeft = "aiid.photoTask.generationAttemptsLeft"

    // MARK: - Init / Deinit

    init() {
        generationAttemptsLeft = UserDefaults.standard.integer(forKey: kGenerationAttemptsLeft)
        updateListenerTask = Task { await listenForUpdates() }
        Task { await refreshProducts() }
    }

    deinit { updateListenerTask?.cancel() }

    // MARK: - Product Loading

    func refreshProducts() async {
        do {
            let loaded = try await Product.products(for: PaidProduct.allProductIDs)
            for product in loaded {
                guard let paidProduct = PaidProduct(rawValue: product.id) else { continue }
                products[paidProduct] = product
                let price = product.displayPrice

                switch paidProduct {
                case .photoTask3:
                    photoTaskDisplayPrice = price
                }

                #if DEBUG
                print("[PurchaseManager] loaded: \(product.id) -> \(price)")
                #endif
            }

            applyFallbackPricesIfNeeded()
        } catch {
            #if DEBUG
            print("[PurchaseManager] products error: \(error)")
            #endif
            applyFallbackPricesIfNeeded()
        }
    }

    var hasGenerationAttempts: Bool {
        Self.forceSubscribed || generationAttemptsLeft > 0
    }

    var remainingAttemptsText: String {
        "\(generationAttemptsLeft)"
    }

    // MARK: - Generation Attempts

    func canGenerate() -> Bool {
        hasGenerationAttempts
    }

    func consumeGenerationAttempt() {
        guard !Self.forceSubscribed, generationAttemptsLeft > 0 else { return }
        generationAttemptsLeft -= 1
        persistAttempts()
    }

    private func grantPhotoTask() {
        generationAttemptsLeft += Self.attemptsPerPhotoTask
        persistAttempts()
    }

    private func persistAttempts() {
        UserDefaults.standard.set(generationAttemptsLeft, forKey: kGenerationAttemptsLeft)
    }

    private func applyFallbackPricesIfNeeded() {
        if photoTaskDisplayPrice == nil { photoTaskDisplayPrice = Self.fallbackPhotoTaskPrice }
    }

    // MARK: - Purchase

    func purchasePhotoTask() async {
        guard !isPurchasing else { return }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        let product: Product
        if let loadedProduct = products[.photoTask3] {
            product = loadedProduct
        } else {
            await refreshProducts()
            guard let loadedProduct = products[.photoTask3] else {
                purchaseError = "购买商品暂时不可用，请稍后重试。"
                return
            }
            product = loadedProduct
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(verification)
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch StoreKitError.userCancelled {
            // User dismissed the purchase sheet.
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
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Transaction Updates

    private func listenForUpdates() async {
        for await result in Transaction.updates {
            await handle(result)
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }

        if transaction.productID == PaidProduct.photoTask3.rawValue {
            grantPhotoTask()
        }

        await transaction.finish()
    }
}
