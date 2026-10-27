import Foundation
import Testing
@testable import Strengthspan

/// Synthetic pose sequences: a side-on person whose knee angle moves between seated and standing.
private enum PoseFixtures {
    /// Builds a frame whose knee angle (hip–knee–ankle) is `kneeAngle` degrees on the left side.
    static func sitToStandFrame(time: TimeInterval, kneeAngle: Double, confidence: Double = 0.9, people: Int = 1, x: Double = 0.5) -> PoseFrame {
        let knee = JointPoint(x: x, y: 0.4, confidence: confidence)
        let ankle = JointPoint(x: x, y: 0.15, confidence: confidence)
        // Hip placed on a circle around the knee so the angle at the knee equals kneeAngle.
        let radians = (180 - kneeAngle) * .pi / 180
        let hip = JointPoint(x: x + 0.2 * sin(radians), y: 0.4 + 0.2 * cos(radians), confidence: confidence)
        return PoseFrame(timestamp: time, joints: [.leftHip: hip, .leftKnee: knee, .leftAnkle: ankle], personCount: people)
    }

    /// Alternates seated (90°) and standing (170°) every `period / 2` seconds, at 15 frames per second.
    static func sitToStandSequence(reps: Int, period: Double = 2, fps: Double = 15, extraSeconds: Double = 0) -> [PoseFrame] {
        let duration = Double(reps) * period + extraSeconds
        return stride(from: 0.0, to: duration, by: 1 / fps).map { time in
            let phase = (time.truncatingRemainder(dividingBy: period)) / period
            let angle = phase < 0.5 ? 90.0 : 170.0
            return sitToStandFrame(time: time, kneeAngle: angle)
        }
    }

    static func shoulderFrame(time: TimeInterval, flexion: Double) -> PoseFrame {
        let shoulder = JointPoint(x: 0.5, y: 0.7, confidence: 0.9)
        let hip = JointPoint(x: 0.5, y: 0.4, confidence: 0.9)
        let radians = flexion * .pi / 180
        let wrist = JointPoint(x: 0.5 + 0.25 * sin(radians), y: 0.7 - 0.25 * cos(radians), confidence: 0.9)
        let elbow = JointPoint(x: (shoulder.x + wrist.x) / 2, y: (shoulder.y + wrist.y) / 2, confidence: 0.9)
        return PoseFrame(timestamp: time, joints: [.rightShoulder: shoulder, .rightHip: hip, .rightWrist: wrist, .rightElbow: elbow], personCount: 1)
    }
}

@Suite("Pose geometry and quality gate")
struct QualityGateTests {
    @Test func angleAtVertex() {
        let a = JointPoint(x: 0, y: 1, confidence: 1)
        let b = JointPoint(x: 0, y: 0, confidence: 1)
        let c = JointPoint(x: 1, y: 0, confidence: 1)
        #expect(abs(PoseGeometry.angle(a, vertex: b, c) - 90) < 0.001)
    }

    @Test func fixtureProducesTheRequestedKneeAngle() {
        let frame = PoseFixtures.sitToStandFrame(time: 0, kneeAngle: 120)
        let angle = PoseGeometry.angle(frame.joints[.leftHip]!, vertex: frame.joints[.leftKnee]!, frame.joints[.leftAnkle]!)
        #expect(abs(angle - 120) < 0.5)
    }

    @Test func framesWithoutAUsablePersonAreRejected() {
        let joints = SitToStandAnalyzer.joints
        #expect(QualityGate.issue(in: PoseFixtures.sitToStandFrame(time: 0, kneeAngle: 90, people: 0), joints: joints) == .noPerson)
        #expect(QualityGate.issue(in: PoseFixtures.sitToStandFrame(time: 0, kneeAngle: 90, people: 2), joints: joints) == .multiplePeople)
        #expect(QualityGate.issue(in: PoseFixtures.sitToStandFrame(time: 0, kneeAngle: 90, confidence: 0.1), joints: joints) == .jointsNotVisible)
        #expect(QualityGate.issue(in: PoseFixtures.sitToStandFrame(time: 0, kneeAngle: 90, x: 0.99), joints: joints) == .outOfFrame)
        #expect(QualityGate.issue(in: PoseFixtures.sitToStandFrame(time: 0, kneeAngle: 90), joints: joints) == nil)
    }

    @Test func reliabilityFollowsTheShareOfUsableFrames() {
        #expect(QualityGate.reliability(validFrames: 100, totalFrames: 100) == .high)
        #expect(QualityGate.reliability(validFrames: 90, totalFrames: 100) == .moderate)
        #expect(QualityGate.reliability(validFrames: 70, totalFrames: 100) == .low)
        #expect(QualityGate.reliability(validFrames: 50, totalFrames: 100) == .insufficient)
        #expect(QualityGate.reliability(validFrames: 5, totalFrames: 5) == .insufficient)
    }
}

@Suite("Movement analyzers")
struct MovementAnalyzerTests {
    @Test(arguments: [3, 8, 14])
    func countsEveryFullStand(reps: Int) {
        var analyzer = SitToStandAnalyzer()
        PoseFixtures.sitToStandSequence(reps: reps).forEach { analyzer.process($0) }
        let outcome = analyzer.outcome(elapsed: 30)
        #expect(outcome.status == .valid)
        #expect(outcome.value == Double(reps))
        #expect(outcome.reliability == .high)
    }

    @Test func briefJitterIsNotCounted() {
        var analyzer = SitToStandAnalyzer()
        var frames = PoseFixtures.sitToStandSequence(reps: 2)
        // A single noisy standing frame while seated must not add a repetition.
        frames.insert(PoseFixtures.sitToStandFrame(time: 0.1, kneeAngle: 175), at: 2)
        frames.forEach { analyzer.process($0) }
        #expect(analyzer.repetitions == 2)
    }

    @Test func fiveTimesSitToStandReportsTheTime() throws {
        var analyzer = SitToStandAnalyzer(targetReps: 5)
        PoseFixtures.sitToStandSequence(reps: 7).forEach { analyzer.process($0) }
        let outcome = analyzer.outcome(elapsed: 12)
        #expect(outcome.status == .valid)
        #expect(outcome.unit == .seconds)
        let seconds = try #require(outcome.value)
        #expect((8.5...9.5).contains(seconds))
        #expect(analyzer.isGoalReached)
    }

    @Test func unfinishedFiveTimesSitToStandIsNotCompleted() {
        var analyzer = SitToStandAnalyzer(targetReps: 5)
        PoseFixtures.sitToStandSequence(reps: 3).forEach { analyzer.process($0) }
        #expect(analyzer.outcome(elapsed: 60).status == .notCompleted)
    }

    @Test func poorTrackingProducesNoResult() {
        var analyzer = SitToStandAnalyzer()
        let frames = PoseFixtures.sitToStandSequence(reps: 10).enumerated().map { index, frame in
            index.isMultiple(of: 2) ? PoseFrame(timestamp: frame.timestamp, joints: [:], personCount: 1) : frame
        }
        frames.forEach { analyzer.process($0) }
        let outcome = analyzer.outcome(elapsed: 30)
        #expect(outcome.status == .rejectedLowQuality)
        #expect(outcome.value == nil)
        #expect(outcome.qualityFlags.contains(FrameIssue.jointsNotVisible.rawValue))
    }

    @Test func shoulderFlexionKeepsTheHighestSmoothedAngle() throws {
        var analyzer = ShoulderFlexionAnalyzer()
        let angles = [10.0, 40, 80, 120, 150, 160, 160, 158, 120, 60, 20] + Array(repeating: 15, count: 10)
        angles.enumerated().forEach { analyzer.process(PoseFixtures.shoulderFrame(time: Double($0.offset) / 15, flexion: $0.element)) }
        let outcome = analyzer.outcome(elapsed: 10)
        let value = try #require(outcome.value)
        #expect(abs(value - 160) <= 1)
        // Beta measurement: never reported as high reliability.
        #expect(outcome.reliability == .moderate)
    }

    @Test func manualOutcomesWithoutValueAreNotCompleted() {
        #expect(MeasurementOutcome.manual(value: nil, unit: .seconds, duration: 60).status == .notCompleted)
        #expect(MeasurementOutcome.manual(value: 12, unit: .repetitions, duration: 30).status == .valid)
    }
}

@Suite("Assessment catalog")
struct AssessmentCatalogTests {
    @Test func everyDimensionHasAPrimaryTest() {
        for dimension in CapacityDimension.allCases {
            #expect(AssessmentCatalog.primary(for: dimension).dimension == dimension)
        }
    }

    @Test func keysAreUniqueAndStable() {
        #expect(AssessmentCatalog.all.map(\.key) == ["chairStand30s", "fiveTimesSitToStand", "calfRaise30s", "supportedSemiTandem", "overheadReach"])
    }

    @Test func balanceTestIsSupportedAndManualOnly() {
        // MVP safety rule: no unsupported single-leg or camera-dependent balance testing.
        #expect(AssessmentCatalog.supportedBalance.usesSupport)
        #expect(!AssessmentCatalog.supportedBalance.supportsCamera)
    }

    @Test func unitsDependOnMethod() {
        #expect(AssessmentCatalog.overheadReach.unit(for: .camera) == .degrees)
        #expect(AssessmentCatalog.overheadReach.unit(for: .manual) == .level)
        #expect(AssessmentCatalog.fiveTimesSitToStand.unit(for: .manual) == .seconds)
    }
}
