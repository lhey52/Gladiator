//
//  IAPManager.swift
//  Gladiator
//

import Foundation
import StoreKit

@MainActor
final class IAPManager: ObservableObject {
    static let shared = IAPManager()

    // MARK: - Product IDs

    static let monthlyID = "com.blackforestcompany.Gladiator.ProMonthly"
    static let annualID = "com.blackforestcompany.Gladiator.ProAnnual"

    // MARK: - Published state

    @Published var isLoading: Bool = false
    @Published var isLoadingProducts: Bool = false
    @Published var errorMessage: String?
    @Published var products: [Product] = []
    @Published var codeGrantedPro: Bool {
        didSet { UserDefaults.standard.set(codeGrantedPro, forKey: "codeGrantedPro") }
    }

    @Published private var subscriptionActive: Bool = false

    var isProUser: Bool {
        subscriptionActive || codeGrantedPro
    }

    var hasStoreKitSubscription: Bool {
        subscriptionActive
    }

    private var updateTask: Task<Void, Never>?
    private var hasStarted = false

    private init() {
        // Cheap, synchronous only — so `isProUser` reflects a code grant
        // immediately. The StoreKit work happens in start().
        codeGrantedPro = UserDefaults.standard.bool(forKey: "codeGrantedPro")
    }

    /// Starts the StoreKit transaction listener and loads initial state. Call
    /// once at app launch (from `GladiatorApp`) so the `Transaction.updates`
    /// listener is alive for the entire app lifetime — catching Ask-to-Buy
    /// approvals, renewals, refunds, and cross-device purchases — instead of
    /// starting lazily whenever a view first touches the singleton. Idempotent.
    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        updateTask = Task { await listenForTransactions() }
        Task { await checkSubscriptionStatus() }
        Task { await loadProducts() }
    }

    // MARK: - Load products

    func loadProducts() async {
        isLoadingProducts = true
        errorMessage = nil
        do {
            products = try await Product.products(for: [Self.monthlyID, Self.annualID])
        } catch {
            errorMessage = "Unable to load products. Check your internet connection."
        }
        isLoadingProducts = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await checkSubscriptionStatus()
            case .userCancelled:
                errorMessage = nil
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                errorMessage = "An unknown error occurred."
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }

        isLoading = false
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            if !isProUser {
                errorMessage = "No active purchases found to restore."
            }
        } catch {
            errorMessage = "Restore failed. Check your internet connection and try again."
        }

        isLoading = false
    }

    // MARK: - Check status

    func checkSubscriptionStatus() async {
        var hasActive = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productID == Self.monthlyID || transaction.productID == Self.annualID {
                    hasActive = true
                }
            }
        }
        // `subscriptionActive` is @Published, so assigning it publishes the
        // change automatically. Guard so a no-op refresh (e.g. the foreground
        // re-check) doesn't needlessly re-render every Pro-gated view.
        if hasActive != subscriptionActive {
            subscriptionActive = hasActive
        }
    }

    // MARK: - Limits

    static let sessionLimit = 10
    static let metricLimit = 12
    static let trackLimit = 3
    static let vehicleLimit = 3

    func checkSessionLimit(currentCount: Int) -> Bool {
        isProUser || currentCount < Self.sessionLimit
    }

    func checkMetricLimit(currentCount: Int) -> Bool {
        isProUser || currentCount < Self.metricLimit
    }

    func checkTrackLimit(currentCount: Int) -> Bool {
        isProUser || currentCount < Self.trackLimit
    }

    func isAtSessionLimit(currentCount: Int) -> Bool {
        !isProUser && currentCount >= Self.sessionLimit
    }

    func isAtMetricLimit(currentCount: Int) -> Bool {
        !isProUser && currentCount >= Self.metricLimit
    }

    func isAtTrackLimit(currentCount: Int) -> Bool {
        !isProUser && currentCount >= Self.trackLimit
    }

    func checkVehicleLimit(currentCount: Int) -> Bool {
        isProUser || currentCount < Self.vehicleLimit
    }

    func isAtVehicleLimit(currentCount: Int) -> Bool {
        !isProUser && currentCount >= Self.vehicleLimit
    }

    // MARK: - Private

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                await transaction.finish()
                await checkSubscriptionStatus()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw StoreError.verificationFailed
        }
    }

    enum StoreError: Error {
        case verificationFailed
    }
}
