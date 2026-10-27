import Observation
import OSLog
import StoreKit
import SwiftUI

/// StoreKit 2 products and entitlement state. Access is decided only from verified transactions.
@Observable
@MainActor
final class SubscriptionStore {
    enum PurchaseOutcome: Equatable { case purchased, pending, cancelled, failed }

    private(set) var products: [Product] = []
    private(set) var isPro = false
    private(set) var isLoading = false
    private(set) var loadFailed = false
    private(set) var introEligibleProductIDs: Set<String> = []
    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
                await self?.refreshEntitlements()
            }
        }
    }

    func load() async {
        guard products.isEmpty, !isLoading else { return }
        isLoading = true
        loadFailed = false
        defer { isLoading = false }
        do {
            let loaded = try await Product.products(for: SubscriptionProduct.allCases.map(\.rawValue))
            // Annual first: it is the better value and the default choice.
            products = loaded.sorted { lhs, _ in lhs.id == SubscriptionProduct.annualPro.rawValue }
            var eligible: Set<String> = []
            for product in loaded {
                if await product.subscription?.isEligibleForIntroOffer == true {
                    eligible.insert(product.id)
                }
            }
            introEligibleProductIDs = eligible
            loadFailed = loaded.isEmpty
        } catch {
            Logger.subscription.error("Loading products failed: \(String(describing: error))")
            loadFailed = true
        }
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var snapshots: [EntitlementSnapshot] = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            snapshots.append(EntitlementSnapshot(
                productID: transaction.productID,
                expirationDate: transaction.expirationDate,
                revocationDate: transaction.revocationDate,
                isUpgraded: transaction.isUpgraded
            ))
        }
        isPro = EntitlementResolver.hasPro(snapshots, now: .now)
    }

    func purchase(_ product: Product) async -> PurchaseOutcome {
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await transaction.finish()
                await refreshEntitlements()
                return .purchased
            case .success(.unverified):
                return .failed
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .failed
            }
        } catch {
            Logger.subscription.error("Purchase failed: \(String(describing: error))")
            return .failed
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            Logger.subscription.error("Restore failed: \(String(describing: error))")
        }
        await refreshEntitlements()
    }

    func isEligibleForTrial(_ product: Product) -> Bool {
        introEligibleProductIDs.contains(product.id) && product.subscription?.introductoryOffer?.paymentMode == .freeTrial
    }
}

extension EnvironmentValues {
    /// Optional so previews and tests without a store simply behave as Free.
    @Entry var subscriptions: SubscriptionStore? = nil
}

extension Logger {
    static let subscription = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.strengthspan.app", category: "subscription")
}

extension Product.SubscriptionPeriod {
    /// "2 weeks", "1 year", … in the app language.
    var localizedDuration: String {
        switch unit {
        case .day: String(localized: "period.days \(value)")
        case .week: String(localized: "period.weeks \(value)")
        case .month: String(localized: "period.months \(value)")
        case .year: String(localized: "period.years \(value)")
        @unknown default: String(localized: "period.days \(value)")
        }
    }
}
