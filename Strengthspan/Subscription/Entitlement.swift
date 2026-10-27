import Foundation

/// A verified StoreKit transaction reduced to the fields that decide access.
struct EntitlementSnapshot: Equatable, Sendable {
    let productID: String
    let expirationDate: Date?
    let revocationDate: Date?
    let isUpgraded: Bool
}

enum EntitlementResolver {
    /// Pro is active when any verified, unrevoked, unexpired transaction is for a Strengthspan Pro product.
    static func hasPro(_ snapshots: [EntitlementSnapshot], now: Date) -> Bool {
        let productIDs = Set(SubscriptionProduct.allCases.map(\.rawValue))
        return snapshots.contains { snapshot in
            productIDs.contains(snapshot.productID)
                && snapshot.revocationDate == nil
                && !snapshot.isUpgraded
                && (snapshot.expirationDate.map { $0 > now } ?? true)
        }
    }
}

/// Free / Pro rules (docs/01 §6). Safety features are never gated.
enum FeatureAccess {
    /// Free users can try this many workouts from their plan.
    static let freeWorkoutLimit = 3

    static func canStartWorkout(isPro: Bool, completedWorkouts: Int) -> Bool {
        isPro || completedWorkouts < freeWorkoutLimit
    }

    /// The first capacity check is free; reassessments are Pro.
    static func canStartAssessment(isPro: Bool, completedAssessments: Int) -> Bool {
        isPro || completedAssessments == 0
    }

    static func canSeeComparisons(isPro: Bool) -> Bool { isPro }
    static func canUseHealthKit(isPro: Bool) -> Bool { isPro }
}
