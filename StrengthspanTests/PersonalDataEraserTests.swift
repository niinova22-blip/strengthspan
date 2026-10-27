import Foundation
import SwiftData
import Testing
@testable import Strengthspan

@Suite("Personal data eraser")
@MainActor
struct PersonalDataEraserTests {
    @Test func erasesEveryUserModel() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        insertOneOfEverything(into: context)
        try context.save()
        #expect(try totalCount(in: context) > 0)

        try PersonalDataEraser(context: context).eraseAll()

        #expect(try totalCount(in: context) == 0)
    }

    @Test func erasingAnEmptyStoreSucceeds() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        try PersonalDataEraser(context: container.mainContext).eraseAll()
        #expect(try totalCount(in: container.mainContext) == 0)
    }

    private func insertOneOfEverything(into context: ModelContext) {
        let profile = UserProfile(
            ageRange: .age55to59,
            activityLevel: .moderatelyActive,
            experienceLevel: .regular,
            primaryGoal: .improveBalance
        )
        context.insert(profile)
        profile.preferences = UserPreferences(
            weeklySessionTarget: 3,
            sessionLength: .long,
            equipment: [.dumbbells],
            preferredWeekdays: [2, 4, 6]
        )
        profile.safetyConstraints.append(SafetyConstraint(kind: .pain, bodyRegion: .back, source: .onboarding))

        let plan = WorkoutPlan(weekStartDate: .now, generatorVersion: "test")
        context.insert(plan)
        let session = WorkoutSession(scheduledDate: .now, plannedDurationMinutes: 30)
        plan.sessions.append(session)
        session.sets.append(
            WorkoutSet(exerciseKey: "calf-raise", variantKey: "calf-raise.supported", block: .mainStrength,
                       orderIndex: 0, setNumber: 1, targetReps: 10, restSeconds: 45)
        )
        session.feedback = WorkoutFeedback(rpe: 5, discomfort: .noDiscomfort, dizzinessReported: false, completion: .full)

        let assessment = AssessmentSession(isBaseline: true, deviceModel: "test", appVersion: "test")
        context.insert(assessment)
        assessment.results.append(
            AssessmentResult(assessmentKey: "chair-stand-30s", definitionVersion: 1, method: .manual,
                             status: .valid, value: 11, unit: .repetitions, durationSeconds: 30,
                             reliability: .moderate, usedSupport: false, setupVariant: "standard-chair")
        )
        assessment.metrics.append(
            CapacityMetric(dimension: .strength, score: 40, reliability: .moderate, scoringModelVersion: "test")
        )

        context.insert(
            ProgressSnapshot(periodStart: .now, periodEnd: .now, baselineSessionID: assessment.id,
                             currentSessionID: nil, plannedSessions: 12, completedSessions: 9)
        )
    }

    private func totalCount(in context: ModelContext) throws -> Int {
        try context.fetchCount(FetchDescriptor<UserProfile>())
            + context.fetchCount(FetchDescriptor<UserPreferences>())
            + context.fetchCount(FetchDescriptor<SafetyConstraint>())
            + context.fetchCount(FetchDescriptor<WorkoutPlan>())
            + context.fetchCount(FetchDescriptor<WorkoutSession>())
            + context.fetchCount(FetchDescriptor<WorkoutSet>())
            + context.fetchCount(FetchDescriptor<WorkoutFeedback>())
            + context.fetchCount(FetchDescriptor<AssessmentSession>())
            + context.fetchCount(FetchDescriptor<AssessmentResult>())
            + context.fetchCount(FetchDescriptor<CapacityMetric>())
            + context.fetchCount(FetchDescriptor<ProgressSnapshot>())
    }
}
