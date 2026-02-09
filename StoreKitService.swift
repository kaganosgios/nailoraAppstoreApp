//
//  StoreKitService.swift
//  nailApp


import Foundation
import StoreKit
import RevenueCat
import Combine
import Firebase
import FirebaseStorage
import FirebaseFirestore
import SwiftUI
import Swift


@MainActor
class StoreKitService: NSObject, ObservableObject {
    static let shared = StoreKitService()
    
    @Published var creditPacks: [CreditPack] = CreditPack.defaultPacks
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var purchaseSuccess = false
    
    private var products: [Product] = []
    private let authService = AuthService.shared
    private let firebaseService = FirebaseService.shared
    
    private override init() {
        super.init()
        Purchases.configure(withAPIKey: APIKeys.revenueCatAPIKey)
        Purchases.shared.delegate = self
        
        Task {
            await loadProducts()
        }
    }
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        let productIds = CreditPack.defaultPacks.map { $0.productId }
        
        do {
            // Load products from StoreKit (native)
            products = try await Product.products(for: Set(productIds))
            
            // Update credit packs with StoreKit product info
            for (index, pack) in creditPacks.enumerated() {
                if let product = products.first(where: { $0.id == pack.productId }) {
                    creditPacks[index].skProduct = product
                    creditPacks[index].price = product.displayPrice
                }
            }
            
            await syncWithRevenueCat()
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func syncWithRevenueCat() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            print("RevenueCat connected. User ID: \(customerInfo.originalAppUserId)")
            
            let offerings = try await Purchases.shared.offerings()
            if let currentOffering = offerings.current {
                print("RevenueCat offering found: \(currentOffering.identifier)")
                print("Packages: \(currentOffering.availablePackages.map { $0.storeProduct.productIdentifier })")
            } else {
                print("RevenueCat: No current offering configured")
            }
        } catch {
            print("RevenueCat sync error (non-critical): \(error)")
        }
    }
    
    func purchase(_ pack: CreditPack) async {
        guard let user = authService.currentUser, !user.isGuest else {
            errorMessage = """
            Create an account to securely save your credits.
            Signing in allows your credits to be safely stored and restored across devices.
            """
            return
        }

        
        guard let product = pack.skProduct else {
            errorMessage = "Product not available"
            return
        }
 
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await handleSuccessfulPurchase(transaction: transaction, pack: pack)
                    
                    await notifyRevenueCatOfPurchase(transaction: transaction, pack: pack)
                    
                    await transaction.finish()
                case .unverified(_, let error):
                    self.errorMessage = "Purchase verification failed: \(error.localizedDescription)"
                }
            case .userCancelled:
                break
            case .pending:
                self.errorMessage = "Purchase pending approval"
            @unknown default:
                break
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func notifyRevenueCatOfPurchase(transaction: StoreKit.Transaction, pack: CreditPack) async {
        do {
            let customerInfo = try await Purchases.shared.syncPurchases()
            print("RevenueCat synced purchase: \(customerInfo.originalAppUserId)")
        } catch {
            print("RevenueCat sync error (non-critical): \(error)")
        }
    }
    
    private func handleSuccessfulPurchase(transaction: StoreKit.Transaction, pack: CreditPack) async {
        guard let user = authService.currentUser else { return }
        
        authService.addCredits(pack.credits)
        
        let priceDouble: Double = {
            if let dec = transaction.price {
                return NSDecimalNumber(decimal: dec).doubleValue
            } else {
                return 0.0
            }
        }()
        let currencyCode = transaction.currencyCode ?? "USD"
        
        let purchaseTransaction = PurchaseTransaction(
            id: UUID().uuidString,
            userId: user.id,
            productId: pack.productId,
            creditsAdded: pack.credits,
            price: priceDouble,
            currency: currencyCode,
            timestamp: Date(),
            transactionId: String(transaction.id),
            isRestored: false
        )
        
        do {
            try await firebaseService.recordPurchase(purchaseTransaction)
            
            let creditTransaction = CreditTransaction(
                id: UUID().uuidString,
                userId: user.id,
                amount: pack.credits,
                type: .purchase,
                description: "Purchased \(pack.name)",
                timestamp: Date()
            )
            
            try await firebaseService.recordCreditTransaction(creditTransaction)
            
            purchaseSuccess = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
   
}

extension StoreKitService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        print("RevenueCat customer info updated: \(customerInfo.originalAppUserId)")
    }
}
