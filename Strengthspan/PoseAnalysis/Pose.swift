import Foundation

/// The subset of Vision body-pose joints the analyzers use.
enum PoseJoint: String, CaseIterable, Sendable {
    case neck
    case leftShoulder, rightShoulder
    case leftElbow, rightElbow
    case leftWrist, rightWrist
    case leftHip, rightHip
    case leftKnee, rightKnee
    case leftAnkle, rightAnkle
}

/// A joint position in normalized image coordinates (0…1, origin bottom-left, as Vision reports).
struct JointPoint: Equatable, Sendable {
    var x: Double
    var y: Double
    var confidence: Double
}

/// One analysed camera frame. Only numbers are kept; the image itself is discarded immediately.
struct PoseFrame: Equatable, Sendable {
    let timestamp: TimeInterval
    let joints: [PoseJoint: JointPoint]
    let personCount: Int
}

enum BodySide: CaseIterable, Sendable {
    case left, right

    var shoulder: PoseJoint { self == .left ? .leftShoulder : .rightShoulder }
    var elbow: PoseJoint { self == .left ? .leftElbow : .rightElbow }
    var wrist: PoseJoint { self == .left ? .leftWrist : .rightWrist }
    var hip: PoseJoint { self == .left ? .leftHip : .rightHip }
    var knee: PoseJoint { self == .left ? .leftKnee : .rightKnee }
    var ankle: PoseJoint { self == .left ? .leftAnkle : .rightAnkle }
}

enum PoseGeometry {
    /// Angle at `vertex` between the segments to `a` and `c`, in degrees (0…180).
    static func angle(_ a: JointPoint, vertex b: JointPoint, _ c: JointPoint) -> Double {
        let v1 = (a.x - b.x, a.y - b.y)
        let v2 = (c.x - b.x, c.y - b.y)
        let lengths = hypot(v1.0, v1.1) * hypot(v2.0, v2.1)
        guard lengths > 0 else { return 0 }
        let cosine = max(-1, min(1, (v1.0 * v2.0 + v1.1 * v2.1) / lengths))
        return acos(cosine) * 180 / .pi
    }

    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }
}
