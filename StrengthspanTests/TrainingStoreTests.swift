import Foundation
import SwiftData
import Testing
@testable import Strengthspan

@Suite("Training store")
@MainActor
struct TrainingStoreTests {
    private let container: ModelContainer
    private let store: TrainingStore
    private let calendar: Calendar
    /// Monday, 2 March 2026, 09:00.
    private let monday: Date

    init() throws {
        container = try PersistenceController.makeContainer(inMemory: true)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        self.calendar = calendar
        store = TrainingStore(context: container.mainContext, calendar: calendar)
        monday = calendar.date(from: DateComponents(year: 2026, month: 3, day: 2, hour: 9))!
    }

    private func answers(screeningYes: Set<ScreeningQuestion> = [], painRegions: Set<BodyRegion> = []) -> OnboardingAnswers {
        OnboardingAnswers(
            ageRange: .age50to54,
            activityLevel: .lightlyActive,
            experienceLevel: .new,
            primaryGoal: .stayIndependent,
            weekdays: [2, 4, 6],
            sessionLength: .standard,
            equipment: [.dumbbells],
            screeningYes: screeningYes,
            painRegions: painRegions
        )
    }

    private func plan(at date: Date) throws -> WorkoutPlan? {
        if case .ready(let plan) = try store.ensureCurrentPlan(now: date) { return plan }
        return nil
    }

    private func loadedRegions(_ plan: WorkoutPlan) -> Set<BodyRegion> {
        plan.sessions.filter { $0.status == .planned }.flatMap(\.sets)
            .compactMap { ExerciseCatalog.variant($0.variantKey)?.variant.loadedRegions }
            .reduce(into: Set<BodyRegion>()) { $0.formUnion($1) }
    }

    @Test func onboardingCreatesProfileAndFirstWeek() throws {
        try store.completeOnboarding(answers(), now: monday)
        let plan = try #require(try plan(at: monday))
        #expect(plan.sessions.count == 3)
        #expect(plan.sessions.allSatisfy { !$0.sets.isEmpty })
        #expect(plan.generatorVersion == PlanGenerator.version)
    }

    @Test func theSamePlanIsReturnedWithinThePeriod() throws {
        try store.completeOnboarding(answers(), now: monday)
        let first = try #require(try plan(at: monday))
        let later = try #require(try plan(at: calendar.date(byAdding: .day, value: 3, to: monday)!))
        #expect(first.id == later.id)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<WorkoutPlan>()) == 1)
    }

    @Test func redFlagsBlockThePlanUntilClearance() throws {
        try store.completeOnboarding(answers(screeningYes: [.chestPain]), now: monday)
        guard case .blocked(.professionalReviewRecommended) = try store.ensureCurrentPlan(now: monday) else {
            Issue.record("expected a blocked plan")
            return
        }
        try store.confirmProfessionalClearance(now: monday)
        #expect(try plan(at: monday) != nil)
        #expect(try store.profile()?.professionalClearanceConfirmedAt == monday)
    }

    @Test func onboardingPainIsRespected() throws {
        try store.completeOnboarding(answers(screeningYes: [.jointPain], painRegions: [.knee]), now: monday)
        let plan = try #require(try plan(at: monday))
        #expect(!loadedRegions(plan).contains(.knee))
    }

    @Test func newPainInFeedbackReplansWithoutThatRegion() throws {
        try store.completeOnboarding(answers(), now: monday)
        let plan = try #require(try plan(at: monday))
        #expect(loadedRegions(plan).contains(.shoulder))
        let session = try #require(plan.sessions.min { $0.scheduledDate < $1.scheduledDate })

        let decision = try store.finish(
            session,
            feedback: SessionFeedbackInput(rpe: 6, discomfort: .newOrSharp, discomfortRegions: [.shoulder], dizzinessReported: false),
            note: nil,
            now: monday
        )

        #expect(decision.newConstraints == [ConstraintSpec(kind: .pain, region: .shoulder)])
        let replanned = try #require(try plan(at: monday))
        #expect(replanned.id != plan.id)
        #expect(!loadedRegions(replanned).contains(.shoulder))
        // Trained today, so the new plan starts tomorrow.
        #expect(replanned.weekStartDate == calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: monday)))
    }

    @Test func warningSignsPauseTrainingUntilResolved() throws {
        try store.completeOnboarding(answers(), now: monday)
        let session = try #require(try plan(at: monday)?.sessions.first)
        try store.start(session, now: monday)

        let decision = try store.stop(session, reason: .warningSigns, now: monday)

        #expect(decision.showEmergencyAdvice)
        #expect(session.status == .stoppedForSafety)
        guard case .blocked(.dizzinessReported) = try store.ensureCurrentPlan(now: monday) else {
            Issue.record("expected training to be paused")
            return
        }
        try store.resolveDizziness(now: monday)
        #expect(try plan(at: monday) != nil)
    }

    @Test func notFeelingUpToItBeforeStartingSkipsTheSession() throws {
        try store.completeOnboarding(answers(), now: monday)
        let session = try #require(try plan(at: monday)?.sessions.first)
        let decision = try store.stop(session, reason: .generallyUnwell, now: monday)
        #expect(decision == .none)
        #expect(session.status == .skipped)
    }

    @Test func completedWorkoutsDriveProgression() throws {
        try store.completeOnboarding(answers(), now: monday)
        var day = monday
        for _ in 0..<2 {
            let plan = try #require(try plan(at: day))
            let session = try #require(plan.sessions.filter { $0.status == .planned }.min { $0.scheduledDate < $1.scheduledDate })
            for set in session.sets { try store.completeSet(set, loadKg: nil, now: session.scheduledDate) }
            try store.finish(session, feedback: SessionFeedbackInput(rpe: 6, discomfort: .noDiscomfort, discomfortRegions: [], dizzinessReported: false), note: nil, now: session.scheduledDate)
            day = session.scheduledDate
        }

        // Sit-to-stand is in both sessions: two easy, complete sessions add two reps.
        let training = try store.trainingProfile(for: try #require(try store.profile()))
        let progress = try store.progressByExercise(for: training)
        #expect(progress["sitToStand"] == ExerciseProgress(level: 1, targetReps: 8))
    }

    @Test func replanningAfterTodaysWorkoutIsStable() throws {
        try store.completeOnboarding(answers(), now: monday)
        let session = try #require(try plan(at: monday)?.sessions.first)
        try store.finish(session, feedback: SessionFeedbackInput(rpe: 6, discomfort: .newOrSharp, discomfortRegions: [.knee], dizzinessReported: false), note: nil, now: monday)

        let first = try #require(try plan(at: monday))
        let again = try #require(try plan(at: monday.addingTimeInterval(3_600)))
        #expect(first.id == again.id)
    }
}
