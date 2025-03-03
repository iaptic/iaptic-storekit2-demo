import StoreKit
import Iaptic

@MainActor
class SubscriptionsManager: NSObject, ObservableObject {
    // iaptic configuration
    private let iaptic: Iaptic
    
    let userID: String = "swift_user"
    let productIDs: [String] = ["monthly_with_intro", "weekly_with_intro"]

    @Published var products: [Product] = []
    
    private var entitlementManager: EntitlementManager? = nil
    private var updates: Task<Void, Never>? = nil
    
    init(entitlementManager: EntitlementManager) {
        print("🚀 Initializing SubscriptionsManager")
        self.iaptic = Iaptic(
            appName: "demo",
            publicKey: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        )
        self.entitlementManager = entitlementManager
        super.init()
        
        // Start observing transactions
        self.updates = observeTransactionUpdates()
        print("👀 Transaction observer task created")
        
        // Add self as payment queue observer
        SKPaymentQueue.default().add(self)
        print("➕ Added as payment queue observer")
        
        // Check for existing transactions
        Task {
            print("🔍 Checking for existing transactions")
            for await result in Transaction.currentEntitlements {
                print("⚙️ Processing initial entitlement")
                
                // Try to get the transaction regardless of verification status
                switch result {
                case .verified(let transaction):
                    print("✅ Initial entitlement verified for product: \(transaction.productID)")
                    await self.verifyWithIaptic(jwsRepresentation: result.jwsRepresentation, productID: transaction.productID)
                case .unverified(let transaction, let error):
                    print("❌ Initial entitlement local verification failed: \(error.localizedDescription)")
                    print("⚠️ Unverified product ID: \(transaction.productID)")
                    await self.verifyWithIaptic(jwsRepresentation: result.jwsRepresentation, productID: transaction.productID)
                }
            }
            
            print("✨ Finished checking existing transactions")
        }
    }
    
    deinit {
        print("🔄 SubscriptionsManager is being deinitialized")
        updates?.cancel()
        SKPaymentQueue.default().remove(self)
    }
    
    func verifyWithIaptic(jwsRepresentation: String, productID: String) async {
        let response = await iaptic.validateWithJWS(
            productId: productID,
            jwsRepresentation: jwsRepresentation,
            applicationUsername: userID
        )
            
        if response.isValid {
            print("✅ Transaction validated successfully with iaptic")
            // Process the verified transaction
            self.updateEntitlements()
        } else {
            print("❌ Transaction validation failed with iaptic: \(response)")
        }
    }
    
    func observeTransactionUpdates() -> Task<Void, Never> {
        print("👀 Starting to observe transaction updates")
        return Task(priority: .background) { [unowned self] in
            print("🎯 Transaction updates observer task started")
            print("⏳ Waiting for transaction updates...")
            for await verificationResult in Transaction.updates {
                print("📬 Received a transaction update!")
                
                // First, verify the transaction
                switch verificationResult {
                case .verified(let transaction):
                    print("✅ Transaction verified by StoreKit for product: \(transaction.productID)")
                    print("🔑 Transaction ID: \(transaction.id)")
                    print("📅 Purchase date: \(transaction.purchaseDate)")
                    await self.verifyWithIaptic(jwsRepresentation: verificationResult.jwsRepresentation, productID: transaction.productID)
                    
                case .unverified(_, let verificationError):
                    print("❌ Transaction local verification failed with error: \(verificationError.localizedDescription)")
                    // Even with verification failure, we might want to check the transaction details
                    if let transaction = try? verificationResult.payloadValue {
                        print("⚠️ Unverified transaction product ID: \(transaction.productID)")
                        print("⚠️ Unverified transaction ID: \(transaction.id)")
                    }
                    await self.verifyWithIaptic(jwsRepresentation: verificationResult.jwsRepresentation, productID: verificationResult.jwsRepresentation)
                }
                
                self.updateEntitlements()
            }
            print("👋 Transaction updates observer task ended")
        }
    }
    
    private func updateEntitlements() {
        if let verifiedPurchases = self.iaptic.getVerifiedPurchases() {
            self.entitlementManager?.hasPro = verifiedPurchases.contains { !($0.isExpired ?? false) }
        } else {
            self.entitlementManager?.hasPro = false
        }
    }
    
    // MARK: - Debugging Helpers
    
    /// Restore purchases from the App Store
    /// IMPORTANT: This method calls AppStore.sync() which displays a system prompt for App Store authentication.
    /// Only call this method in response to an explicit user action (e.g., tapping a "Restore Purchases" button).
    func restorePurchases() async {
        print("🔄 Restoring purchases")
        
        do {
            // Sync with the App Store - this will prompt for authentication
            print("🔄 Syncing with App Store for purchase restoration")
            try await AppStore.sync()
            print("✅ Sync completed")
            
            // Print current state
            print("💫 Has Pro after restore: \(entitlementManager?.hasPro ?? false)")
        } catch {
            print("❌ Error restoring purchases: \(error.localizedDescription)")
        }
    }
}

// MARK: StoreKit2 API
extension SubscriptionsManager {
    func loadProducts() async {
        do {
            self.products = try await Product.products(for: productIDs)
                .sorted(by: { $0.price > $1.price })
        } catch {
            print("❌ Failed to fetch products!")
        }
    }
    
    func buyProduct(_ product: Product) async {
        print("🛍️ Attempting to purchase product: \(product.id)")
        do {
            print("💰 Calling product.purchase() for \(product.id)")
            let result = try await product.purchase()
            print("📦 Purchase result received for \(product.id)")
            
            switch result {
            case .success(let verificationResult):
                print("✅ Purchase success for \(product.id)")
                
                switch verificationResult {
                case .verified(let transaction):
                    print("✅ Purchase verified for \(product.id), transaction ID: \(transaction.id)")
                    await self.verifyWithIaptic(jwsRepresentation: verificationResult.jwsRepresentation, productID: transaction.productID)

                case .unverified(let transaction, let error):
                    print("❌ Purchase local verification failed: \(error.localizedDescription)")
                    print("⚠️ Unverified transaction product ID: \(transaction.productID)")
                    print("⚠️ Unverified transaction ID: \(transaction.id)")
                    await self.verifyWithIaptic(jwsRepresentation: verificationResult.jwsRepresentation, productID: transaction.productID)
                }
                
            case .pending:
                print("⏳ Purchase pending - waiting on approval")
                break
            case .userCancelled:
                print("🚫 User cancelled purchase")
                break
            @unknown default:
                print("❓ Unknown purchase result")
                break
            }
        } catch {
            print("❌ Failed to purchase the product: \(error.localizedDescription)")
        }
    }
}

extension SubscriptionsManager: SKPaymentTransactionObserver {
    nonisolated func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    }
    
    nonisolated func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true
    }
}
