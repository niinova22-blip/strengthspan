import Foundation

/// Why a frame can't be used for measurement. Raw values are stored as quality flags.
enum FrameIssue: String, CaseIterable, Sendable {
    case noPerson
    case multiplePeople
    case jointsNotVisible
    case outOfFrame
}

/// Decides whether frames and whole measurements are trustworthy (docs/04 §3).
/// When in doubt the gate rejects: no result is better than a wrong one.
enum QualityGate {
    static let minimumConfidence = 0.3
    static let frameMargin = 0.03

    /// The body side whose required joints are seen most confidently, if any side is usable.
    static func bestSide(in frame: PoseFrame, joints: (BodySide) -> [PoseJoint]) -> BodySide? {
        var best: (side: BodySide, confidence: Double)?
        for side in BodySide.allCases {
            var total = 0.0
            var usable = true
            for joint in joints(side) {
                guard let confidence = frame.joints[joint]?.confidence, confidence >= minimumConfidence else {
                    usable = false
                    break
                }
                total += confidence
            }
            if usable, total > (best?.confidence ?? -1) {
                best = (side, total)
            }
        }
        return best?.side
    }

    static func issue(in frame: PoseFrame, joints: (BodySide) -> [PoseJoint]) -> FrameIssue? {
        guard frame.personCount > 0 else { return .noPerson }
        guard frame.personCount == 1 else { return .multiplePeople }
        guard let side = bestSide(in: frame, joints: joints) else { return .jointsNotVisible }
        let margin = frameMargin
        let inside = joints(side).allSatisfy { joint in
            guard let point = frame.joints[joint] else { return false }
            return (margin...(1 - margin)).contains(point.x) && (margin...(1 - margin)).contains(point.y)
        }
        return inside ? nil : .outOfFrame
    }

    /// Maps the share of usable frames to a reliability level.
    static func reliability(validFrames: Int, totalFrames: Int) -> MeasurementReliability {
        guard totalFrames >= 10 else { return .insufficient }
        let ratio = Double(validFrames) / Double(totalFrames)
        switch ratio {
        case 0.95...: return .high
        case 0.85..<0.95: return .moderate
        case 0.6..<0.85: return .low
        default: return .insufficient
        }
    }
}
