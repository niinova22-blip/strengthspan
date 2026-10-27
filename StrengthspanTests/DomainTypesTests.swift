import Testing
@testable import Strengthspan

/// Raw values are persisted. Changing one silently breaks existing users' data,
/// so every stored enum is pinned here. Add new cases at the end of the expected lists.
@Suite("Persisted raw values")
struct DomainTypesTests {
    @Test func capacityDimensions() {
        #expect(CapacityDimension.allCases.map(\.rawValue) == ["strength", "balance", "mobility", "movementControl"])
    }

    @Test func safetyRelevantValues() {
        #expect(ScreeningOutcome.allCases.map(\.rawValue) == ["notScreened", "cleared", "professionalReviewRecommended"])
        #expect(Discomfort.allCases.map(\.rawValue) == ["none", "mildFamiliar", "newOrSharp"])
        #expect(SessionStatus.allCases.map(\.rawValue) == ["planned", "inProgress", "completed", "skipped", "stoppedForSafety"])
        #expect(SafetyConstraintKind.allCases.map(\.rawValue) == [
            "pain", "recentSurgeryOrInjury", "dizziness", "balanceConcern",
            "movementLimitation", "professionalRestriction", "other",
        ])
    }

    @Test func measurementValues() {
        #expect(MeasurementMethod.allCases.map(\.rawValue) == ["camera", "manual"])
        #expect(MeasurementReliability.allCases.map(\.rawValue) == ["high", "moderate", "low", "insufficient"])
        #expect(AssessmentResultStatus.allCases.map(\.rawValue) == ["valid", "skipped", "rejectedLowQuality", "stoppedForSafety", "notCompleted"])
        #expect(MeasurementUnit.allCases.map(\.rawValue) == ["repetitions", "seconds", "degrees", "level"])
    }

    @Test func profileValues() {
        #expect(SessionLength.allCases.map(\.rawValue) == [10, 20, 30])
        #expect(Equipment.allCases.map(\.rawValue) == ["bodyweightOnly", "dumbbells", "resistanceBand"])
    }

    @Test func subscriptionProductIDsMatchAppStoreConnect() {
        #expect(SubscriptionProduct.allCases.map(\.rawValue) == [
            "com.strengthspan.app.pro.monthly", "com.strengthspan.app.pro.annual",
        ])
        #expect(SubscriptionProduct.subscriptionGroupID == "22520215")
    }

    @Test func onlyTrustworthyReliabilityIsComparable() {
        #expect(MeasurementReliability.allCases.filter(\.isComparable) == [.high, .moderate])
    }
}
