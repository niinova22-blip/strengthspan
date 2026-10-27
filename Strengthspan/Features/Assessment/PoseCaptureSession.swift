@preconcurrency import AVFoundation
import Vision

/// Front-camera capture with on-device body-pose detection.
///
/// Privacy: sample buffers are analysed in memory on a private queue and released immediately.
/// Nothing is written to disk or sent anywhere; only joint coordinates leave this class.
final class PoseCaptureSession: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    enum SetupError: Error { case noCamera, cannotAddInput, cannotAddOutput }

    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "com.strengthspan.pose-capture")
    private let request = VNDetectHumanBodyPoseRequest()
    private var frameIndex = 0
    /// Called on the capture queue for every analysed frame.
    var onFrame: (@Sendable (PoseFrame) -> Void)?

    static var isCameraAvailable: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
    }

    func configure() throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw SetupError.noCamera
        }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .hd1280x720

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw SetupError.cannotAddInput }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        guard session.canAddOutput(output) else { throw SetupError.cannotAddOutput }
        session.addOutput(output)
        if let connection = output.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }

    func start() {
        queue.async { [self] in
            if !session.isRunning { session.startRunning() }
        }
    }

    func stop() {
        queue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameIndex += 1
        // ~15 Hz analysis is enough for these movements and keeps older iPhones cool.
        guard frameIndex.isMultiple(of: 2) else { return }

        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        try? handler.perform([request])
        let observations = request.results ?? []
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds

        var joints: [PoseJoint: JointPoint] = [:]
        if let points = try? observations.first?.recognizedPoints(.all) {
            for (name, joint) in Self.jointNames {
                if let point = points[name] {
                    joints[joint] = JointPoint(x: Double(point.location.x), y: Double(point.location.y), confidence: Double(point.confidence))
                }
            }
        }
        onFrame?(PoseFrame(timestamp: timestamp, joints: joints, personCount: observations.count))
    }

    private static let jointNames: [VNHumanBodyPoseObservation.JointName: PoseJoint] = [
        .neck: .neck,
        .leftShoulder: .leftShoulder, .rightShoulder: .rightShoulder,
        .leftElbow: .leftElbow, .rightElbow: .rightElbow,
        .leftWrist: .leftWrist, .rightWrist: .rightWrist,
        .leftHip: .leftHip, .rightHip: .rightHip,
        .leftKnee: .leftKnee, .rightKnee: .rightKnee,
        .leftAnkle: .leftAnkle, .rightAnkle: .rightAnkle,
    ]
}
