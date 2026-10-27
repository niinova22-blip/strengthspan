import Foundation

enum PlanBlockReason: Equatable, Sendable {
    case notScreened
    case professionalReviewRecommended
    case dizzinessReported
}

enum PlanPermission: Equatable, Sendable {
    case allowed
    case blocked(PlanBlockReason)
}

/// What the user reported at the end of, or while stopping, a session.
struct SessionFeedbackInput: Equatable, Sendable {
    var rpe: Int?
    var discomfort: Discomfort
    var discomfortRegions: Set<BodyRegion>
    var dizzinessReported: Bool
}

/// Why the user pressed "I don't feel well".
enum SafetyStopReason: Equatable, Sendable {
    /// Chest pain, dizziness, faintness or severe breathlessness.
    case warningSigns
    case pain(Set<BodyRegion>)
    case generallyUnwell
}

struct SafetyDecision: Equatable, Sendable {
    var newConstraints: [ConstraintSpec]
    var recommendProfessional: Bool
    var showEmergencyAdvice: Bool

    static let none = SafetyDecision(newConstraints: [], recommendProfessional: false, showEmergencyAdvice: false)
}

/// Deterministic safety rules (docs/05). Every planning and progression decision passes through here;
/// the most restrictive rule wins. No model or heuristic outside this file may relax these rules.
enum SafetyEngine {
    static let rulesVersion = "safety-1"

    static func planPermission(screening: ScreeningOutcome, constraints: [ConstraintSpec]) -> PlanPermission {
        switch screening {
        case .notScreened: return .blocked(.notScreened)
        case .professionalReviewRecommended: return .blocked(.professionalReviewRecommended)
        case .cleared: break
        }
        if constraints.contains(where: { $0.kind == .dizziness }) {
            return .blocked(.dizzinessReported)
        }
        return .allowed
    }

    static func painRegions(in constraints: [ConstraintSpec]) -> Set<BodyRegion> {
        Set(constraints.filter { $0.kind == .pain }.compactMap(\.region))
    }

    /// SAF-01: never load a region the user reported pain in.
    static func isAllowed(_ variant: ExerciseVariant, constraints: [ConstraintSpec]) -> Bool {
        variant.loadedRegions.isDisjoint(with: painRegions(in: constraints))
    }

    /// SAF-03: with a balance concern, balance work stays at the easiest, fully supported level.
    static func maxLevel(for exercise: Exercise, constraints: [ConstraintSpec]) -> Int {
        let hasBalanceConcern = constraints.contains { $0.kind == .balanceConcern }
        if hasBalanceConcern && exercise.dimension == .balance {
            return 1
        }
        return exercise.maxLevel
    }

    /// SAF-01 / SAF-02: what end-of-session feedback means for safety.
    static func evaluate(_ feedback: SessionFeedbackInput) -> SafetyDecision {
        var decision = SafetyDecision.none
        if feedback.dizzinessReported {
            decision.newConstraints.append(ConstraintSpec(kind: .dizziness, region: nil))
            decision.recommendProfessional = true
        }
        if feedback.discomfort == .newOrSharp {
            decision.newConstraints += painConstraints(feedback.discomfortRegions)
        }
        return decision
    }

    static func evaluate(_ stop: SafetyStopReason) -> SafetyDecision {
        switch stop {
        case .warningSigns:
            SafetyDecision(
                newConstraints: [ConstraintSpec(kind: .dizziness, region: nil)],
                recommendProfessional: true,
                showEmergencyAdvice: true
            )
        case .pain(let regions):
            SafetyDecision(newConstraints: painConstraints(regions), recommendProfessional: false, showEmergencyAdvice: false)
        case .generallyUnwell:
            .none
        }
    }

    private static func painConstraints(_ regions: Set<BodyRegion>) -> [ConstraintSpec] {
        let regions = regions.isEmpty ? [.other] : regions.sorted { $0.rawValue < $1.rawValue }
        return regions.map { ConstraintSpec(kind: .pain, region: $0) }
    }
}
