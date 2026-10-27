import Foundation

/// A limitation the safety engine must respect. Value-type mirror of the persisted `SafetyConstraint`.
struct ConstraintSpec: Hashable, Sendable {
    let kind: SafetyConstraintKind
    let region: BodyRegion?
}

/// Pre-exercise screening questions (docs/05 §2). Wording lives in the string catalog.
/// Not a diagnostic tool: a "yes" only changes what the app is willing to plan.
enum ScreeningQuestion: String, CaseIterable, Sendable {
    case supervisedOnly
    case chestPain
    case dizziness
    case recentSurgery
    case recentFall
    case jointPain
    case movementLimitation

    /// A "yes" to a red-flag question means no automatic plan until the user confirms
    /// they have been cleared by a health professional.
    var isRedFlag: Bool {
        switch self {
        case .supervisedOnly, .chestPain, .dizziness, .recentSurgery: true
        case .recentFall, .jointPain, .movementLimitation: false
        }
    }

    var textKey: String { "screening.\(rawValue)" }
}

struct ScreeningResult: Equatable, Sendable {
    let outcome: ScreeningOutcome
    let constraints: [ConstraintSpec]
}

enum ScreeningEvaluator {
    static func evaluate(yesAnswers: Set<ScreeningQuestion>, painRegions: Set<BodyRegion>) -> ScreeningResult {
        let outcome: ScreeningOutcome = yesAnswers.contains(where: \.isRedFlag) ? .professionalReviewRecommended : .cleared

        var constraints: [ConstraintSpec] = []
        if yesAnswers.contains(.recentFall) {
            constraints.append(ConstraintSpec(kind: .balanceConcern, region: nil))
        }
        if yesAnswers.contains(.jointPain) {
            let regions = painRegions.isEmpty ? [.other] : painRegions.sorted { $0.rawValue < $1.rawValue }
            constraints += regions.map { ConstraintSpec(kind: .pain, region: $0) }
        }
        if yesAnswers.contains(.movementLimitation) {
            constraints.append(ConstraintSpec(kind: .movementLimitation, region: nil))
        }
        return ScreeningResult(outcome: outcome, constraints: constraints)
    }
}
