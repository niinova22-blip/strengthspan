import Foundation

/// How the camera can be used for a test (docs/04 §2).
enum CameraSupport: Sendable {
    case unsupported
    case supported
    /// Works, but accuracy is not yet validated on real devices; labelled "beta" in the UI.
    case beta
}

/// How a test is measured by hand when the camera isn't used.
enum ManualProtocol: Sendable {
    /// Count repetitions during a fixed time.
    case countReps
    /// Stopwatch until the target number of repetitions is done.
    case timeToTarget
    /// Stopwatch for how long a position is held, up to the time limit.
    case holdTime
    /// The user picks how far they reach.
    case reachLevel
}

/// A capacity test. Definitions are app content; results reference them by `key` and `version`.
struct AssessmentDefinition: Sendable, Identifiable, Hashable {
    let key: String
    let version: Int
    let dimension: CapacityDimension
    let higherIsBetter: Bool
    let timeLimitSeconds: Int
    let targetReps: Int?
    let camera: CameraSupport
    let manual: ManualProtocol
    let usesSupport: Bool
    let setupVariant: String

    var id: String { key }
    var nameKey: String { "assessment.\(key)" }
    var instructionKey: String { "assessment.\(key).how" }
    var setupKey: String { "assessment.\(key).setup" }

    var supportsCamera: Bool { camera != .unsupported }

    func unit(for method: MeasurementMethod) -> MeasurementUnit {
        switch (manual, method) {
        case (.reachLevel, .manual): .level
        case (.reachLevel, .camera): .degrees
        case (.countReps, _): .repetitions
        case (.timeToTarget, _), (.holdTime, _): .seconds
        }
    }

    static func == (lhs: AssessmentDefinition, rhs: AssessmentDefinition) -> Bool { lhs.key == rhs.key && lhs.version == rhs.version }
    func hash(into hasher: inout Hasher) { hasher.combine(key); hasher.combine(version) }
}

enum AssessmentCatalog {
    static let chairStand = AssessmentDefinition(
        key: "chairStand30s", version: 1, dimension: .strength, higherIsBetter: true,
        timeLimitSeconds: 30, targetReps: nil, camera: .supported, manual: .countReps,
        usesSupport: false, setupVariant: "standard-chair"
    )
    static let fiveTimesSitToStand = AssessmentDefinition(
        key: "fiveTimesSitToStand", version: 1, dimension: .movementControl, higherIsBetter: false,
        timeLimitSeconds: 60, targetReps: 5, camera: .supported, manual: .timeToTarget,
        usesSupport: false, setupVariant: "standard-chair"
    )
    static let calfRaise = AssessmentDefinition(
        key: "calfRaise30s", version: 1, dimension: .strength, higherIsBetter: true,
        timeLimitSeconds: 30, targetReps: nil, camera: .unsupported, manual: .countReps,
        usesSupport: true, setupVariant: "supported-both-feet"
    )
    static let supportedBalance = AssessmentDefinition(
        key: "supportedSemiTandem", version: 1, dimension: .balance, higherIsBetter: true,
        timeLimitSeconds: 30, targetReps: nil, camera: .unsupported, manual: .holdTime,
        usesSupport: true, setupVariant: "semi-tandem-hand-on-counter"
    )
    static let overheadReach = AssessmentDefinition(
        key: "overheadReach", version: 1, dimension: .mobility, higherIsBetter: true,
        timeLimitSeconds: 10, targetReps: nil, camera: .beta, manual: .reachLevel,
        usesSupport: false, setupVariant: "standing-side-on"
    )

    static let all: [AssessmentDefinition] = [chairStand, fiveTimesSitToStand, calfRaise, supportedBalance, overheadReach]

    /// The test that represents each dimension on the capacity map.
    static func primary(for dimension: CapacityDimension) -> AssessmentDefinition {
        switch dimension {
        case .strength: chairStand
        case .balance: supportedBalance
        case .mobility: overheadReach
        case .movementControl: fiveTimesSitToStand
        }
    }

    static func definition(_ key: String) -> AssessmentDefinition? {
        all.first { $0.key == key }
    }
}
