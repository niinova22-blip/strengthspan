import AVFoundation
import Observation
import OSLog
import SwiftUI

/// Drives one camera measurement: permission → framing → countdown → measuring → outcome.
@Observable
@MainActor
final class CameraMeasurementModel {
    enum Stage: Equatable {
        case preparing
        case denied
        case unavailable
        case framing
        case countdown(Int)
        case measuring
        case finished(MeasurementOutcome)
    }

    let definition: AssessmentDefinition
    private(set) var stage: Stage = .preparing
    private(set) var framingIssue: FrameIssue? = .noPerson
    private(set) var liveValue: Double = 0
    private(set) var secondsLeft: Int
    let capture = PoseCaptureSession()

    private var analyzer: any MovementAnalyzer
    private var framedSince: TimeInterval?
    private var measuringStartedAt: Date?
    private var ticker: Task<Void, Never>?
    private let speech: SpeechCoach
    /// Framing must hold this long before the countdown starts.
    private let framingHoldSeconds = 1.5

    init(definition: AssessmentDefinition, voiceEnabled: Bool) {
        self.definition = definition
        self.secondsLeft = definition.timeLimitSeconds
        self.analyzer = Self.makeAnalyzer(for: definition)
        self.speech = SpeechCoach(isEnabled: voiceEnabled)
    }

    private static func makeAnalyzer(for definition: AssessmentDefinition) -> any MovementAnalyzer {
        switch definition.manual {
        case .reachLevel: ShoulderFlexionAnalyzer()
        default: SitToStandAnalyzer(targetReps: definition.targetReps)
        }
    }

    func start() async {
        guard PoseCaptureSession.isCameraAvailable else {
            stage = .unavailable
            return
        }
        var status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            status = await AVCaptureDevice.requestAccess(for: .video) ? .authorized : .denied
        }
        guard status == .authorized else {
            stage = .denied
            return
        }
        do {
            try capture.configure()
        } catch {
            Logger.persistence.error("Camera setup failed: \(String(describing: error))")
            stage = .unavailable
            return
        }
        capture.onFrame = { [weak self] frame in
            Task { @MainActor in self?.handle(frame) }
        }
        capture.start()
        stage = .framing
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
        capture.onFrame = nil
        capture.stop()
        speech.stop()
    }

    func retry() {
        analyzer = Self.makeAnalyzer(for: definition)
        liveValue = 0
        secondsLeft = definition.timeLimitSeconds
        framedSince = nil
        stage = .framing
    }

    private func handle(_ frame: PoseFrame) {
        switch stage {
        case .framing:
            framingIssue = issue(in: frame)
            if framingIssue == nil {
                let since = framedSince ?? frame.timestamp
                framedSince = since
                if frame.timestamp - since >= framingHoldSeconds { beginCountdown() }
            } else {
                framedSince = nil
            }
        case .countdown:
            framingIssue = issue(in: frame)
        case .measuring:
            framingIssue = issue(in: frame)
            let before = analyzer.liveValue
            analyzer.process(frame)
            liveValue = analyzer.liveValue
            if liveValue > before, definition.manual != .reachLevel {
                speech.say(Int(liveValue).formatted())
            }
            if analyzer.isGoalReached { finish() }
        default:
            break
        }
    }

    private func issue(in frame: PoseFrame) -> FrameIssue? {
        let analyzer = self.analyzer
        return QualityGate.issue(in: frame, joints: { analyzer.requiredJoints($0) })
    }

    private func beginCountdown() {
        stage = .countdown(3)
        runTicker { [weak self] in
            guard let self, case .countdown(let value) = self.stage else { return false }
            if value <= 1 {
                self.beginMeasuring()
                return false
            }
            self.stage = .countdown(value - 1)
            self.speech.say((value - 1).formatted())
            return true
        }
        speech.say(3.formatted())
    }

    private func beginMeasuring() {
        stage = .measuring
        measuringStartedAt = .now
        speech.say(String(localized: "assessment.camera.go"))
        runTicker { [weak self] in
            guard let self, self.stage == .measuring else { return false }
            self.secondsLeft = max(0, self.secondsLeft - 1)
            if self.secondsLeft == 0 {
                self.finish()
                return false
            }
            return true
        }
    }

    private func finish() {
        guard stage == .measuring else { return }
        ticker?.cancel()
        ticker = nil
        let elapsed = Date.now.timeIntervalSince(measuringStartedAt ?? .now)
        let outcome = analyzer.outcome(elapsed: elapsed)
        stage = .finished(outcome)
        speech.say(String(localized: "assessment.camera.done"))
    }

    /// Calls `step` every second until it returns `false`.
    private func runTicker(_ step: @escaping @MainActor () -> Bool) {
        ticker?.cancel()
        ticker = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled || !step() { return }
            }
        }
    }
}

/// Live camera preview. Mirrored like a mirror, which people expect from the front camera.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        // swiftlint:disable:next force_cast
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

struct CameraMeasurementView: View {
    @State private var model: CameraMeasurementModel
    let onComplete: (MeasurementOutcome) -> Void
    let onUseManual: () -> Void

    init(definition: AssessmentDefinition, voiceEnabled: Bool, onComplete: @escaping (MeasurementOutcome) -> Void, onUseManual: @escaping () -> Void) {
        _model = State(initialValue: CameraMeasurementModel(definition: definition, voiceEnabled: voiceEnabled))
        self.onComplete = onComplete
        self.onUseManual = onUseManual
    }

    var body: some View {
        VStack(spacing: SSSpacing.l) {
            switch model.stage {
            case .preparing:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .denied:
                fallback("assessment.camera.denied")
            case .unavailable:
                fallback("assessment.camera.unavailable")
            case .framing, .countdown, .measuring:
                livePreview
            case .finished(let outcome):
                MeasurementResultView(definition: model.definition, method: .camera, outcome: outcome, onAccept: { onComplete(outcome) }, onRetry: { model.retry() }, onUseManual: onUseManual)
            }
        }
        .task { await model.start() }
        .onDisappear { model.stop() }
    }

    private var livePreview: some View {
        VStack(spacing: SSSpacing.m) {
            ZStack {
                CameraPreview(session: model.capture.session)
                    .clipShape(RoundedRectangle(cornerRadius: SSRadius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: SSRadius.card, style: .continuous)
                            .strokeBorder(model.framingIssue == nil ? SSColor.accent : SSColor.caution, lineWidth: 4)
                    )
                    .accessibilityHidden(true)
                overlayContent
            }
            Text(statusText)
                .font(SSFont.headline)
                .foregroundStyle(SSColor.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.updatesFrequently)
            Button("assessment.useManual", action: onUseManual)
                .buttonStyle(.ssSecondary)
        }
        .padding(SSSpacing.l)
    }

    @ViewBuilder
    private var overlayContent: some View {
        switch model.stage {
        case .countdown(let value):
            Text(value.formatted())
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(radius: 8)
        case .measuring:
            VStack {
                Spacer()
                HStack {
                    Text(liveValueText)
                        .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                    Spacer()
                    Text(Duration.seconds(model.secondsLeft), format: .time(pattern: .minuteSecond))
                        .font(.system(size: 32, weight: .semibold, design: .rounded).monospacedDigit())
                }
                .foregroundStyle(.white)
                .padding(SSSpacing.l)
                .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: SSRadius.button))
                .padding(SSSpacing.m)
            }
        default:
            EmptyView()
        }
    }

    private var liveValueText: String {
        model.definition.manual == .reachLevel ? "\(Int(model.liveValue))°" : Int(model.liveValue).formatted()
    }

    private var statusText: LocalizedStringKey {
        if case .measuring = model.stage { return "assessment.camera.measuring" }
        switch model.framingIssue {
        case .noPerson: return "assessment.camera.noPerson"
        case .multiplePeople: return "assessment.camera.multiplePeople"
        case .jointsNotVisible: return "assessment.camera.jointsNotVisible"
        case .outOfFrame: return "assessment.camera.outOfFrame"
        case nil: return "assessment.camera.ready"
        }
    }

    private func fallback(_ message: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: SSSpacing.l) {
            SSEmptyState(message, systemImage: "camera")
            Button("assessment.useManual", action: onUseManual)
                .buttonStyle(.ssPrimary)
        }
        .padding(SSSpacing.l)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
