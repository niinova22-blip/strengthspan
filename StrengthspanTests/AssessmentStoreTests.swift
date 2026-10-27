import Foundation
import SwiftData
import Testing
@testable import Strengthspan

@Suite("Assessment store and export")
@MainActor
struct AssessmentStoreTests {
    private let container: ModelContainer
    private let store: AssessmentStore
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    init() throws {
        container = try PersistenceController.makeContainer(inMemory: true)
        store = AssessmentStore(context: container.mainContext)
    }

    private func outcome(_ value: Double?, unit: MeasurementUnit = .repetitions, reliability: MeasurementReliability = .high, status: AssessmentResultStatus = .valid) -> MeasurementOutcome {
        MeasurementOutcome(status: status, value: value, unit: unit, reliability: reliability, qualityFlags: [], durationSeconds: 30)
    }

    @Test func firstSessionIsTheBaseline() throws {
        let first = try store.startSession(now: now)
        #expect(first.isBaseline)
        try store.complete(first, now: now)
        let second = try store.startSession(now: now.addingTimeInterval(86_400 * 28))
        #expect(!second.isBaseline)
    }

    @Test func completingWritesOneMetricPerMeasuredDimension() throws {
        let session = try store.startSession(now: now)
        try store.record(outcome(12), for: AssessmentCatalog.chairStand, method: .camera, in: session, now: now)
        try store.record(outcome(25, unit: .seconds), for: AssessmentCatalog.supportedBalance, method: .manual, in: session, now: now)
        try store.recordSkipped(AssessmentCatalog.overheadReach, in: session, now: now)
        try store.record(outcome(nil, unit: .seconds, reliability: .insufficient, status: .rejectedLowQuality), for: AssessmentCatalog.fiveTimesSitToStand, method: .camera, in: session, now: now)

        try store.complete(session, now: now)

        #expect(session.status == .completed)
        let dimensions = Set(session.metrics.compactMap(\.dimension))
        #expect(dimensions == [.strength, .balance])
        #expect(session.metrics.first { $0.dimension == .strength }?.value == 12)
    }

    @Test func onlyCompletedSessionsFeedProgress() throws {
        let done = try store.startSession(now: now)
        try store.record(outcome(11), for: AssessmentCatalog.chairStand, method: .manual, in: done, now: now)
        try store.complete(done, now: now)
        let open = try store.startSession(now: now.addingTimeInterval(60))
        try store.record(outcome(30), for: AssessmentCatalog.chairStand, method: .manual, in: open, now: now.addingTimeInterval(60))

        let snapshots = try store.snapshots(for: AssessmentCatalog.chairStand.key)
        #expect(snapshots.map(\.value) == [11])
    }

    @Test func discardingRemovesAnUnfinishedSession() throws {
        let session = try store.startSession(now: now)
        try store.record(outcome(9), for: AssessmentCatalog.chairStand, method: .manual, in: session, now: now)
        try store.discard(session)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<AssessmentSession>()) == 0)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<AssessmentResult>()) == 0)
    }

    @Test func exportContainsProfileWorkoutsAndAssessments() throws {
        let training = TrainingStore(context: container.mainContext)
        try training.completeOnboarding(OnboardingAnswers(
            ageRange: .age55to59, activityLevel: .lightlyActive, experienceLevel: .new, primaryGoal: .improveBalance,
            weekdays: [2, 4], sessionLength: .short, equipment: [], screeningYes: [.recentFall], painRegions: []
        ), now: now)
        guard case .ready(let plan) = try training.ensureCurrentPlan(now: now), let workout = plan.sessions.first else {
            Issue.record("expected a plan")
            return
        }
        try training.finish(workout, feedback: SessionFeedbackInput(rpe: 5, discomfort: .noDiscomfort, discomfortRegions: [], dizzinessReported: false), note: "felt good", now: now)
        let session = try store.startSession(now: now)
        try store.record(outcome(10), for: AssessmentCatalog.chairStand, method: .manual, in: session, now: now)
        try store.complete(session, now: now)

        let data = try PersonalDataExporter(context: container.mainContext).encodedData(now: now)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let export = try decoder.decode(PersonalDataExporter.Export.self, from: data)

        #expect(export.profile?.primaryGoal == "improveBalance")
        #expect(export.safetyConstraints.map(\.kind) == ["balanceConcern"])
        #expect(export.workouts.count == 1)
        #expect(export.workouts.first?.note == "felt good")
        #expect(export.assessments.first?.results.first?.value == 10)
    }
}
