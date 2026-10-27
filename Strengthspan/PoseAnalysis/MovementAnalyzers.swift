import Foundation

/// The outcome of one measurement, ready to be stored as an `AssessmentResult`.
struct MeasurementOutcome: Equatable, Sendable {
    var status: AssessmentResultStatus
    var value: Double?
    var unit: MeasurementUnit
    var reliability: MeasurementReliability
    var qualityFlags: [String]
    var durationSeconds: Double

    static func manual(value: Double?, unit: MeasurementUnit, duration: Double, status: AssessmentResultStatus = .valid) -> MeasurementOutcome {
        // Manual counts are the user's own observation; they're comparable with other manual counts.
        MeasurementOutcome(status: value == nil && status == .valid ? .notCompleted : status, value: value, unit: unit, reliability: .moderate, qualityFlags: [], durationSeconds: duration)
    }
}

/// Consumes pose frames during a camera measurement and produces an outcome.
protocol MovementAnalyzer: Sendable {
    /// Required joints for one body side.
    func requiredJoints(_ side: BodySide) -> [PoseJoint]
    mutating func process(_ frame: PoseFrame)
    /// `true` once the measurement has reached its goal before the time limit (e.g. five stands).
    var isGoalReached: Bool { get }
    var liveValue: Double { get }
    func outcome(elapsed: Double) -> MeasurementOutcome
}

/// Counts full sit-to-stand repetitions from the knee angle (hip–knee–ankle).
/// Seated ≈ 90°, standing ≈ 170°; two thresholds (hysteresis) avoid double counting.
struct SitToStandAnalyzer: MovementAnalyzer {
    struct Configuration: Sendable {
        var seatedBelow = 115.0
        var standingAbove = 155.0
        var minimumRepSeconds = 0.6
        var smoothingWindow = 5
    }

    enum Posture: Sendable { case unknown, seated, standing }

    let configuration: Configuration
    /// Stop after this many repetitions (five-times sit-to-stand); `nil` counts for the whole time.
    let targetReps: Int?
    private(set) var posture: Posture = .unknown
    private(set) var repetitionTimes: [TimeInterval] = []
    private(set) var validFrames = 0
    private(set) var totalFrames = 0
    private(set) var startTime: TimeInterval?
    private var recentAngles: [Double] = []
    private var flags: Set<String> = []

    init(targetReps: Int? = nil, configuration: Configuration = Configuration()) {
        self.targetReps = targetReps
        self.configuration = configuration
    }

    static let joints: @Sendable (BodySide) -> [PoseJoint] = { [$0.hip, $0.knee, $0.ankle] }

    func requiredJoints(_ side: BodySide) -> [PoseJoint] { Self.joints(side) }

    var repetitions: Int { repetitionTimes.count }
    var isGoalReached: Bool { targetReps.map { repetitions >= $0 } ?? false }
    var liveValue: Double { Double(repetitions) }

    mutating func process(_ frame: PoseFrame) {
        if startTime == nil { startTime = frame.timestamp }
        totalFrames += 1
        if let issue = QualityGate.issue(in: frame, joints: Self.joints) {
            flags.insert(issue.rawValue)
            return
        }
        guard let side = QualityGate.bestSide(in: frame, joints: Self.joints),
              let hip = frame.joints[side.hip], let knee = frame.joints[side.knee], let ankle = frame.joints[side.ankle] else { return }
        validFrames += 1

        recentAngles.append(PoseGeometry.angle(hip, vertex: knee, ankle))
        if recentAngles.count > configuration.smoothingWindow { recentAngles.removeFirst() }
        guard let angle = PoseGeometry.median(recentAngles) else { return }

        if angle < configuration.seatedBelow {
            posture = .seated
        } else if angle > configuration.standingAbove {
            if posture == .seated && !isGoalReached {
                let lastTime = repetitionTimes.last ?? -.infinity
                if frame.timestamp - lastTime >= configuration.minimumRepSeconds {
                    repetitionTimes.append(frame.timestamp)
                }
            }
            posture = .standing
        }
    }

    func outcome(elapsed: Double) -> MeasurementOutcome {
        let reliability = QualityGate.reliability(validFrames: validFrames, totalFrames: totalFrames)
        let flagList = flags.sorted()
        guard reliability != .insufficient else {
            return MeasurementOutcome(status: .rejectedLowQuality, value: nil, unit: unit, reliability: .insufficient, qualityFlags: flagList, durationSeconds: elapsed)
        }
        if let targetReps {
            guard repetitions >= targetReps, let start = startTime, let done = repetitionTimes.last else {
                return MeasurementOutcome(status: .notCompleted, value: nil, unit: .seconds, reliability: reliability, qualityFlags: flagList, durationSeconds: elapsed)
            }
            let seconds = (done - start).rounded(toPlaces: 1)
            return MeasurementOutcome(status: .valid, value: seconds, unit: .seconds, reliability: reliability, qualityFlags: flagList, durationSeconds: elapsed)
        }
        return MeasurementOutcome(status: .valid, value: Double(repetitions), unit: .repetitions, reliability: reliability, qualityFlags: flagList, durationSeconds: elapsed)
    }

    private var unit: MeasurementUnit { targetReps == nil ? .repetitions : .seconds }
}

/// Highest shoulder flexion (hip–shoulder–wrist angle) reached while raising an arm overhead.
struct ShoulderFlexionAnalyzer: MovementAnalyzer {
    private(set) var maxAngle: Double = 0
    private(set) var validFrames = 0
    private(set) var totalFrames = 0
    private var recentAngles: [Double] = []
    private var flags: Set<String> = []

    static let joints: @Sendable (BodySide) -> [PoseJoint] = { [$0.hip, $0.shoulder, $0.elbow, $0.wrist] }

    func requiredJoints(_ side: BodySide) -> [PoseJoint] { Self.joints(side) }

    var isGoalReached: Bool { false }
    var liveValue: Double { maxAngle.rounded() }

    mutating func process(_ frame: PoseFrame) {
        totalFrames += 1
        if let issue = QualityGate.issue(in: frame, joints: Self.joints) {
            flags.insert(issue.rawValue)
            return
        }
        guard let side = QualityGate.bestSide(in: frame, joints: Self.joints),
              let hip = frame.joints[side.hip], let shoulder = frame.joints[side.shoulder], let wrist = frame.joints[side.wrist] else { return }
        validFrames += 1
        recentAngles.append(PoseGeometry.angle(hip, vertex: shoulder, wrist))
        if recentAngles.count > 3 { recentAngles.removeFirst() }
        if recentAngles.count == 3, let smoothed = PoseGeometry.median(recentAngles) {
            maxAngle = max(maxAngle, smoothed)
        }
    }

    func outcome(elapsed: Double) -> MeasurementOutcome {
        let reliability = QualityGate.reliability(validFrames: validFrames, totalFrames: totalFrames)
        guard reliability != .insufficient, maxAngle > 0 else {
            return MeasurementOutcome(status: .rejectedLowQuality, value: nil, unit: .degrees, reliability: .insufficient, qualityFlags: flags.sorted(), durationSeconds: elapsed)
        }
        // Beta: never better than moderate until validated on real devices (docs/04 §5).
        let capped: MeasurementReliability = reliability == .high ? .moderate : reliability
        return MeasurementOutcome(status: .valid, value: maxAngle.rounded(), unit: .degrees, reliability: capped, qualityFlags: flags.sorted(), durationSeconds: elapsed)
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10, Double(places))
        return (self * factor).rounded() / factor
    }
}
