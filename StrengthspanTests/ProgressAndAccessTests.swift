import Foundation
import Testing
@testable import Strengthspan

@Suite("Progress comparison")
struct ProgressComparisonTests {
    private func result(
        day: Int,
        value: Double?,
        method: MeasurementMethod = .camera,
        status: AssessmentResultStatus = .valid,
        reliability: MeasurementReliability = .high,
        support: Bool = false,
        version: Int = 1
    ) -> ResultSnapshot {
        ResultSnapshot(
            date: Date(timeIntervalSince1970: TimeInterval(day * 86_400)),
            assessmentKey: "chairStand30s",
            definitionVersion: version,
            method: method,
            status: status,
            value: value,
            unit: .repetitions,
            reliability: reliability,
            usedSupport: support,
            setupVariant: "standard-chair"
        )
    }

    @Test func noUsableResultMeansNotEnoughMeasurements() {
        #expect(ProgressComparison.compare([], higherIsBetter: true) == .none)
        #expect(ProgressComparison.compare([result(day: 1, value: nil, status: .rejectedLowQuality, reliability: .insufficient)], higherIsBetter: true) == .none)
    }

    @Test func comparableResultsShowTheChange() {
        guard case .compared(let comparison) = ProgressComparison.compare([result(day: 1, value: 11), result(day: 29, value: 15)], higherIsBetter: true) else {
            Issue.record("expected a comparison")
            return
        }
        #expect(comparison.delta == 4)
        #expect(comparison.percentChange == 36)
        #expect(comparison.improved == true)
    }

    @Test func lowerIsBetterForTimedTests() {
        guard case .compared(let comparison) = ProgressComparison.compare([result(day: 1, value: 14), result(day: 29, value: 12)], higherIsBetter: false) else {
            Issue.record("expected a comparison")
            return
        }
        #expect(comparison.improved == true)
    }

    @Test(arguments: [
        (method: MeasurementMethod.manual, support: false, version: 1),
        (method: .camera, support: true, version: 1),
        (method: .camera, support: false, version: 2),
    ])
    func differentConditionsAreNeverCompared(method: MeasurementMethod, support: Bool, version: Int) {
        let outcome = ProgressComparison.compare([result(day: 1, value: 11), result(day: 29, value: 15, method: method, support: support, version: version)], higherIsBetter: true)
        guard case .notComparable = outcome else {
            Issue.record("expected not comparable, got \(outcome)")
            return
        }
    }

    @Test func lowReliabilityResultsAreIgnored() {
        let outcome = ProgressComparison.compare([result(day: 1, value: 11), result(day: 29, value: 20, reliability: .low)], higherIsBetter: true)
        #expect(outcome == .single(result(day: 1, value: 11)))
    }

    @Test func baselineIsTheEarliestComparableResult() {
        let history = [result(day: 1, value: 9, method: .manual), result(day: 5, value: 11), result(day: 20, value: 13), result(day: 29, value: 15)]
        guard case .compared(let comparison) = ProgressComparison.compare(history, higherIsBetter: true) else {
            Issue.record("expected a comparison")
            return
        }
        #expect(comparison.baseline.value == 11)
    }
}

@Suite("Consistency")
struct ConsistencyTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    @Test func countsCompletedAndDueSessionsWithoutPunishingToday() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 30, hour: 8))!
        let day: (Int) -> Date = { self.calendar.date(byAdding: .day, value: -$0, to: now)! }
        let records: [ConsistencySummary.SessionRecord] = [
            .init(scheduledDate: day(1), status: .completed, completedAt: day(1)),
            .init(scheduledDate: day(3), status: .skipped, completedAt: nil),
            .init(scheduledDate: day(5), status: .completed, completedAt: day(5)),
            .init(scheduledDate: day(40), status: .completed, completedAt: day(40)),
            .init(scheduledDate: now, status: .planned, completedAt: nil),
        ]
        #expect(ConsistencySummary.lastDays(30, records: records, now: now, calendar: calendar) == .init(completed: 2, planned: 3))
    }
}

@Suite("Entitlements and access")
struct EntitlementTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func snapshot(_ product: SubscriptionProduct = .monthlyPro, expires: TimeInterval? = 86_400, revoked: Bool = false, upgraded: Bool = false) -> EntitlementSnapshot {
        EntitlementSnapshot(
            productID: product.rawValue,
            expirationDate: expires.map { now.addingTimeInterval($0) },
            revocationDate: revoked ? now : nil,
            isUpgraded: upgraded
        )
    }

    @Test func activeSubscriptionGrantsPro() {
        #expect(EntitlementResolver.hasPro([snapshot()], now: now))
        #expect(EntitlementResolver.hasPro([snapshot(.annualPro)], now: now))
    }

    @Test func expiredRevokedOrUpgradedTransactionsDoNot() {
        #expect(!EntitlementResolver.hasPro([], now: now))
        #expect(!EntitlementResolver.hasPro([snapshot(expires: -1)], now: now))
        #expect(!EntitlementResolver.hasPro([snapshot(revoked: true)], now: now))
        #expect(!EntitlementResolver.hasPro([snapshot(upgraded: true)], now: now))
        #expect(!EntitlementResolver.hasPro([EntitlementSnapshot(productID: "other.app.product", expirationDate: nil, revocationDate: nil, isUpgraded: false)], now: now))
    }

    @Test func freeUsersGetSampleWorkoutsAndTheirFirstAssessment() {
        #expect(FeatureAccess.canStartWorkout(isPro: false, completedWorkouts: 2))
        #expect(!FeatureAccess.canStartWorkout(isPro: false, completedWorkouts: 3))
        #expect(FeatureAccess.canStartWorkout(isPro: true, completedWorkouts: 50))
        #expect(FeatureAccess.canStartAssessment(isPro: false, completedAssessments: 0))
        #expect(!FeatureAccess.canStartAssessment(isPro: false, completedAssessments: 1))
        #expect(FeatureAccess.canStartAssessment(isPro: true, completedAssessments: 4))
    }
}
