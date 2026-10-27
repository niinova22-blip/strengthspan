import Foundation
import SwiftData
import Testing
@testable import Strengthspan

@Suite("Persistence")
@MainActor
struct PersistenceTests {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init() throws {
        container = try PersistenceController.makeContainer(inMemory: true)
    }

    @Test func schemaV1RegistersEveryModel() {
        #expect(container.schema.entities.count == SchemaV1.models.count)
    }

    @Test func profileRoundTripsWithPreferencesAndConstraints() throws {
        let profile = UserProfile(
            ageRange: .age50to54,
            activityLevel: .lightlyActive,
            experienceLevel: .returning,
            primaryGoal: .stayIndependent
        )
        context.insert(profile)
        profile.preferences = UserPreferences(
            weeklySessionTarget: 3,
            sessionLength: .standard,
            equipment: [.dumbbells, .resistanceBand],
            preferredWeekdays: [6, 2, 4]
        )
        profile.safetyConstraints.append(
            SafetyConstraint(kind: .pain, bodyRegion: .knee, source: .onboarding)
        )
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<UserProfile>()).first)
        #expect(fetched.ageRange == .age50to54)
        #expect(fetched.screeningOutcome == .notScreened)
        #expect(fetched.preferences?.sessionLength == .standard)
        #expect(fetched.preferences?.equipment == [.dumbbells, .resistanceBand])
        #expect(fetched.preferences?.preferredWeekdays == [2, 4, 6])
        #expect(fetched.safetyConstraints.first?.bodyRegion == .knee)
        #expect(fetched.safetyConstraints.first?.isActive == true)
    }

    @Test func deletingProfileCascadesToPreferencesAndConstraints() throws {
        let profile = UserProfile(
            ageRange: .age45to49,
            activityLevel: .mostlySedentary,
            experienceLevel: .new,
            primaryGoal: .buildStrength
        )
        context.insert(profile)
        profile.preferences = UserPreferences(
            weeklySessionTarget: 2,
            sessionLength: .short,
            equipment: [.bodyweightOnly],
            preferredWeekdays: [2, 5]
        )
        profile.safetyConstraints.append(SafetyConstraint(kind: .balanceConcern, source: .onboarding))
        try context.save()

        context.delete(profile)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<UserPreferences>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SafetyConstraint>()) == 0)
    }

    @Test func deletingWorkoutSessionCascadesToSetsAndFeedback() throws {
        let session = WorkoutSession(scheduledDate: .now, plannedDurationMinutes: 20)
        context.insert(session)
        session.sets.append(
            WorkoutSet(
                exerciseKey: "sit-to-stand",
                variantKey: "sit-to-stand.chair",
                block: .mainStrength,
                orderIndex: 0,
                setNumber: 1,
                targetReps: 8,
                restSeconds: 60
            )
        )
        session.feedback = WorkoutFeedback(
            rpe: 6,
            discomfort: .noDiscomfort,
            dizzinessReported: false,
            completion: .full
        )
        try context.save()

        context.delete(session)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<WorkoutSet>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutFeedback>()) == 0)
    }

    @Test func assessmentCompletionKeepsStatusAndDateInSync() {
        let session = AssessmentSession(isBaseline: true, deviceModel: "test", appVersion: "test")
        #expect(session.status == .inProgress)
        #expect(session.completedAt == nil)

        let completion = Date(timeIntervalSince1970: 1_800_000_000)
        session.markCompleted(at: completion)
        #expect(session.status == .completed)
        #expect(session.completedAt == completion)

        session.markAbandoned()
        #expect(session.status == .abandoned)
        #expect(session.completedAt == nil)
    }

    @Test func invalidResultsNeverStoreAValue() {
        let result = AssessmentResult(
            assessmentKey: "chair-stand-30s",
            definitionVersion: 1,
            method: .camera,
            status: .rejectedLowQuality,
            value: 12,
            unit: .repetitions,
            durationSeconds: 30,
            reliability: .insufficient,
            usedSupport: false,
            setupVariant: "standard-chair"
        )
        #expect(result.value == nil)
    }

    @Test func valuesAreClampedToTheirScales() {
        let feedback = WorkoutFeedback(rpe: 14, discomfort: .mildFamiliar, dizzinessReported: false, completion: .full)
        #expect(feedback.rpe == 10)

        // Untrustworthy values are never stored as capacity values.
        let metric = CapacityMetric(dimension: .balance, assessmentKey: "supportedSemiTandem", value: 20, unit: .seconds, method: .manual, reliability: .low)
        #expect(metric.value == nil)
    }
}
