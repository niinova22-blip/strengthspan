/// Auto-renewable subscriptions configured in App Store Connect (group "Strengthspan Pro").
/// Product IDs can never be reused once created, so these raw values must not change.
/// Prices and trial terms are read from StoreKit at runtime, never hard-coded.
enum SubscriptionProduct: String, CaseIterable, Sendable {
    case monthlyPro = "com.strengthspan.app.pro.monthly"
    case annualPro = "com.strengthspan.app.pro.annual"

    static let subscriptionGroupID = "22520215"
}
