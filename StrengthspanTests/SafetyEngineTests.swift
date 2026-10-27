import Foundation
import Testing
@testable import Strengthspan

@Suite("Screening")
struct ScreeningTests {
    @Test(arguments: ScreeningQuestion.allCases.filter(\.isRedFlag))
    func anyRedFlagRecommendsProfessionalReview(question: ScreeningQuestion) {
        let result = ScreeningEvaluator.evaluate(yesAnswers: [question], painRegions: [])
        #expect(result.outcome == .professionalReviewRecommended)
    }

    @Test func noYesAnswersClearsTheUser() {
        let result = ScreeningEvaluator.evaluate(yesAnswers: [], painRegions: [])
        #expect(result == ScreeningResult(outcome: .cleared, constraints: []))
    }

    @Test func orangeAnswersClearButCreateConstraints() {
        let result = ScreeningEvaluator.evaluate(yesAnswers: [.recentFall, .jointPain], painRegions: [.knee, .back])
        #expect(result.outcome == .cleared)
        #expect(Set(result.constraints) == [
            ConstraintSpec(kind: .balanceConcern, region: nil),
            ConstraintSpec(kind: .pain, region: .knee),
            ConstraintSpec(kind: .pain, region: .back),
        ])
    }

    @Test func jointPainWithoutRegionIsStillRecorded() {
        let result = ScreeningEvaluator.evaluate(yesAnswers: [.jointPain], painRegions: [])
        #expect(result.constraints == [ConstraintSpec(kind: .pain, region: .other)])
    }
}

@Suite("Safety engine")
struct SafetyEngineTests {
    private let sitToStand = ExerciseCatalog.exercise("sitToStand")!
    private let tandem = ExerciseCatalog.exercise("tandemStance")!

    @Test func onlyClearedUsersWithoutDizzinessGetAPlan() {
        #expect(SafetyEngine.planPermission(screening: .notScreened, constraints: []) == .blocked(.notScreened))
        #expect(SafetyEngine.planPermission(screening: .professionalReviewRecommended, constraints: []) == .blocked(.professionalReviewRecommended))
        #expect(SafetyEngine.planPermission(screening: .cleared, constraints: [ConstraintSpec(kind: .dizziness, region: nil)]) == .blocked(.dizzinessReported))
        #expect(SafetyEngine.planPermission(screening: .cleared, constraints: [ConstraintSpec(kind: .pain, region: .knee)]) == .allowed)
    }

    @Test func painfulRegionsAreNeverLoaded() {
        let knee = [ConstraintSpec(kind: .pain, region: .knee)]
        #expect(sitToStand.variants.allSatisfy { !SafetyEngine.isAllowed($0, constraints: knee) })
        #expect(SafetyEngine.isAllowed(ExerciseCatalog.variant("pushUp.wall")!.variant, constraints: knee))
    }

    @Test func balanceConcernCapsBalanceWorkAtLevelOne() {
        let concern = [ConstraintSpec(kind: .balanceConcern, region: nil)]
        #expect(SafetyEngine.maxLevel(for: tandem, constraints: concern) == 1)
        #expect(SafetyEngine.maxLevel(for: tandem, constraints: []) == 2)
        #expect(SafetyEngine.maxLevel(for: sitToStand, constraints: concern) == sitToStand.maxLevel)
    }

    @Test func dizzinessStopsTrainingAndRecommendsAProfessional() {
        let decision = SafetyEngine.evaluate(SessionFeedbackInput(rpe: 5, discomfort: .noDiscomfort, discomfortRegions: [], dizzinessReported: true))
        #expect(decision.newConstraints == [ConstraintSpec(kind: .dizziness, region: nil)])
        #expect(decision.recommendProfessional)
    }

    @Test func newPainCreatesRegionConstraints() {
        let decision = SafetyEngine.evaluate(SessionFeedbackInput(rpe: 6, discomfort: .newOrSharp, discomfortRegions: [.shoulder], dizzinessReported: false))
        #expect(decision.newConstraints == [ConstraintSpec(kind: .pain, region: .shoulder)])
        #expect(!decision.recommendProfessional)
    }

    @Test func familiarMildDiscomfortChangesNothing() {
        let decision = SafetyEngine.evaluate(SessionFeedbackInput(rpe: 6, discomfort: .mildFamiliar, discomfortRegions: [.knee], dizzinessReported: false))
        #expect(decision == .none)
    }

    @Test func warningSignsShowEmergencyAdvice() {
        let decision = SafetyEngine.evaluate(SafetyStopReason.warningSigns)
        #expect(decision.showEmergencyAdvice)
        #expect(decision.recommendProfessional)
        #expect(SafetyEngine.evaluate(SafetyStopReason.generallyUnwell) == .none)
    }
}
