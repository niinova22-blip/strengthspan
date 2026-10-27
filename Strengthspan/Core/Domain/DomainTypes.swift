import Foundation

// Value types persisted by raw value. Raw values are part of the stored data format:
// never rename or reuse them. `DomainTypesTests` guards against accidental changes.

// MARK: - Profile

enum AgeRange: String, Codable, CaseIterable, Sendable {
    case under45
    case age45to49
    case age50to54
    case age55to59
    case age60to64
    case age65to69
    case age70plus
}

enum ActivityLevel: String, Codable, CaseIterable, Sendable {
    case mostlySedentary
    case lightlyActive
    case moderatelyActive
    case veryActive
}

enum ExperienceLevel: String, Codable, CaseIterable, Sendable {
    case new
    case returning
    case regular
}

enum PrimaryGoal: String, Codable, CaseIterable, Sendable {
    case buildStrength
    case improveBalance
    case moveMoreEasily
    case stayIndependent
    case generalFitness
}

enum Equipment: String, Codable, CaseIterable, Sendable {
    case bodyweightOnly
    case dumbbells
    case resistanceBand
}

enum SessionLength: Int, Codable, CaseIterable, Sendable {
    case short = 10
    case standard = 20
    case long = 30
}

// MARK: - Safety

enum ScreeningOutcome: String, Codable, CaseIterable, Sendable {
    case notScreened
    case cleared
    case professionalReviewRecommended
}

enum SafetyConstraintKind: String, Codable, CaseIterable, Sendable {
    case pain
    case recentSurgeryOrInjury
    case dizziness
    case balanceConcern
    case movementLimitation
    case professionalRestriction
    case other
}

enum BodyRegion: String, Codable, CaseIterable, Sendable {
    case neck
    case shoulder
    case back
    case hip
    case knee
    case ankleFoot
    case wristHand
    case other
}

enum ConstraintSource: String, Codable, CaseIterable, Sendable {
    case onboarding
    case workoutFeedback
    case settings
}

// MARK: - Workout

enum PlanStatus: String, Codable, CaseIterable, Sendable {
    case active
    case superseded
    case archived
}

enum SessionStatus: String, Codable, CaseIterable, Sendable {
    case planned
    case inProgress
    case completed
    case skipped
    case stoppedForSafety
}

enum WorkoutBlock: String, Codable, CaseIterable, Sendable {
    case warmUp
    case mainStrength
    case balanceControl
    case cooldown
}

enum Discomfort: String, Codable, CaseIterable, Sendable {
    // Not named `none` to avoid ambiguity with `Optional.none`.
    case noDiscomfort = "none"
    case mildFamiliar
    case newOrSharp
}

enum CompletionLevel: String, Codable, CaseIterable, Sendable {
    case full
    case partial
    case stoppedEarly
}

// MARK: - Assessment

enum AssessmentStatus: String, Codable, CaseIterable, Sendable {
    case inProgress
    case completed
    case abandoned
}

enum AssessmentResultStatus: String, Codable, CaseIterable, Sendable {
    case valid
    case skipped
    case rejectedLowQuality
    case stoppedForSafety
    /// The user couldn't finish the test (e.g. five stands within the time limit). Not a quality problem.
    case notCompleted
}

enum MeasurementMethod: String, Codable, CaseIterable, Sendable {
    case camera
    case manual
}

enum MeasurementUnit: String, Codable, CaseIterable, Sendable {
    case repetitions
    case seconds
    case degrees
    /// Self-reported reach level 1…3 (manual mobility check).
    case level
}

/// How much a measurement can be trusted. Only `high` and `moderate` results may drive
/// progression or percentage comparisons.
enum MeasurementReliability: String, Codable, CaseIterable, Sendable {
    case high
    case moderate
    case low
    case insufficient

    var isComparable: Bool {
        self == .high || self == .moderate
    }
}

// MARK: - Capacity

enum CapacityDimension: String, Codable, CaseIterable, Sendable {
    case strength
    case balance
    case mobility
    case movementControl

    var title: LocalizedStringResource {
        switch self {
        case .strength: "dimension.strength"
        case .balance: "dimension.balance"
        case .mobility: "dimension.mobility"
        case .movementControl: "dimension.movementControl"
        }
    }

    var systemImage: String {
        switch self {
        case .strength: "dumbbell"
        case .balance: "figure.stand"
        case .mobility: "figure.flexibility"
        case .movementControl: "scope"
        }
    }
}
