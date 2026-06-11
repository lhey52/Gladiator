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
    /// Product IDs the user is currently eligible to start a free trial on.
    /// Empty when the trial has been used, no intro offer is configured, or
    /// products haven't loaded yet.
    @Published private(set) var trialEligibleProductIDs: Set<String> = []
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
            await refreshTrialEligibility()
        } catch {
            errorMessage = "Unable to load products. Check your internet connection."
        }
        isLoadingProducts = false
    }

    // MARK: - Free trial / intro offer

    /// True if any loaded plan still offers this user a free trial.
    var hasTrialAvailable: Bool { !trialEligibleProductIDs.isEmpty }

    /// Whether `productID` currently offers this user an unused free trial.
    func isTrialEligible(_ productID: String) -> Bool {
        trialEligibleProductIDs.contains(productID)
    }

    /// Human-readable length of a product's free-trial intro offer (e.g. "7-day",
    /// "3-day", "1-month"), or nil if it has no free trial. Weeks are expressed in
    /// days to match the paywall's "N-day free trial" copy.
    func trialDurationText(for productID: String) -> String? {
        guard let product = products.first(where: { $0.id == productID }),
              let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        let value = offer.period.value
        switch offer.period.unit {
        case .day: return "\(value)-day"
        case .week: return "\(value * 7)-day"
        case .month: return "\(value)-month"
        case .year: return "\(value)-year"
        @unknown default: return "\(value)-day"
        }
    }

    /// Recomputes which products the user can still start a free trial on by
    /// querying StoreKit intro-offer eligibility for each loaded subscription.
    private func refreshTrialEligibility() async {
        var eligible: Set<String> = []
        for product in products {
            guard let subscription = product.subscription,
                  let offer = subscription.introductoryOffer,
                  offer.paymentMode == .freeTrial else { continue }
            if await subscription.isEligibleForIntroOffer {
                eligible.insert(product.id)
            }
        }
        if eligible != trialEligibleProductIDs {
            trialEligibleProductIDs = eligible
        }
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

        // Trial eligibility can change with entitlements (e.g. a trial consumed
        // on another device), so refresh it whenever products are available.
        if !products.isEmpty {
            await refreshTrialEligibility()
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
