import Observation
import SwiftUI

/// Formats a measurement value with its unit for display and speech.
enum MeasurementText {
    static func value(_ value: Double, unit: MeasurementUnit) -> String {
        switch unit {
        case .repetitions: String(localized: "measurement.reps \(Int(value))")
        case .seconds: String(localized: "measurement.seconds \(value.formatted(.number.precision(.fractionLength(0...1))))")
        case .degrees: String(localized: "measurement.degrees \(Int(value))")
        case .level: levelText(Int(value))
        }
    }

    static func levelText(_ level: Int) -> String {
        let key = "measurement.level." + String(level)
        return String(localized: String.LocalizationValue(key))
    }
}

/// Stopwatch / countdown logic for hand-measured tests.
@Observable
@MainActor
final class ManualMeasurementModel {
    enum Stage: Equatable { case ready, running, review }

    let definition: AssessmentDefinition
    private(set) var stage: Stage = .ready
    private(set) var elapsed: Double = 0
    var count = 0
    private var startedAt: Date?
    private var ticker: Task<Void, Never>?
    private let speech: SpeechCoach

    init(definition: AssessmentDefinition, voiceEnabled: Bool) {
        self.definition = definition
        self.speech = SpeechCoach(isEnabled: voiceEnabled)
    }

    var limit: Double { Double(definition.timeLimitSeconds) }
    var secondsLeft: Double { max(0, limit - elapsed) }

    func start() {
        count = 0
        elapsed = 0
        startedAt = .now
        stage = .running
        speech.say(String(localized: "assessment.camera.go"))
        ticker = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, let startedAt = self.startedAt else { return }
                self.elapsed = Date.now.timeIntervalSince(startedAt)
                if self.elapsed >= self.limit {
                    self.stopTimer()
                    return
                }
            }
        }
    }

    func stopTimer() {
        ticker?.cancel()
        ticker = nil
        if let startedAt { elapsed = min(limit, Date.now.timeIntervalSince(startedAt)) }
        stage = .review
        speech.say(String(localized: "assessment.camera.done"))
    }

    func cancel() {
        ticker?.cancel()
        ticker = nil
        speech.stop()
    }

    func addRep() {
        guard stage == .running else { return }
        count += 1
    }

    func removeRep() {
        count = max(0, count - 1)
    }

    /// Five-times sit-to-stand: `completed` is false when the user couldn't finish.
    func outcomeForTimedTarget(completed: Bool) -> MeasurementOutcome {
        let reachedLimit = elapsed >= limit
        let value = completed && !reachedLimit ? elapsed.rounded(toPlaces: 1) : nil
        return .manual(value: value, unit: .seconds, duration: elapsed)
    }

    func outcomeForCount() -> MeasurementOutcome {
        .manual(value: Double(count), unit: .repetitions, duration: limit)
    }

    func outcomeForHold() -> MeasurementOutcome {
        .manual(value: elapsed.rounded(toPlaces: 1), unit: .seconds, duration: elapsed)
    }
}

struct ManualMeasurementView: View {
    @State private var model: ManualMeasurementModel
    let onComplete: (MeasurementOutcome) -> Void

    init(definition: AssessmentDefinition, voiceEnabled: Bool, onComplete: @escaping (MeasurementOutcome) -> Void) {
        _model = State(initialValue: ManualMeasurementModel(definition: definition, voiceEnabled: voiceEnabled))
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: SSSpacing.l) {
            Text(LocalizedStringKey(model.definition.nameKey))
                .font(SSFont.title)
                .foregroundStyle(SSColor.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
        }
        .padding(SSSpacing.l)
        .onDisappear { model.cancel() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.definition.manual {
        case .reachLevel:
            reachChoice
        case .countReps:
            countReps
        case .timeToTarget:
            stopwatch(doneTitle: "assessment.manual.fiveDone") { onComplete(model.outcomeForTimedTarget(completed: true)) }
        case .holdTime:
            stopwatch(doneTitle: "assessment.manual.holdStop") { onComplete(model.outcomeForHold()) }
        }
    }

    private var reachChoice: some View {
        VStack(spacing: SSSpacing.m) {
            Text("assessment.manual.reachQuestion")
                .font(SSFont.body)
                .foregroundStyle(SSColor.textSecondary)
            ForEach([3, 2, 1], id: \.self) { level in
                SSChoiceRow(LocalizedStringKey("measurement.level.\(level)" as String), isSelected: false) {
                    onComplete(.manual(value: Double(level), unit: .level, duration: 0))
                }
                .accessibilityIdentifier("assessment.reach.\(level)")
            }
        }
    }

    @ViewBuilder
    private var countReps: some View {
        switch model.stage {
        case .ready:
            startButton
        case .running:
            VStack(spacing: SSSpacing.l) {
                timeDisplay(model.secondsLeft)
                Button {
                    model.addRep()
                } label: {
                    VStack {
                        Text(model.count.formatted())
                            .font(.system(size: 72, weight: .bold, design: .rounded).monospacedDigit())
                        Text("assessment.manual.tapEach")
                            .font(SSFont.callout)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .foregroundStyle(SSColor.onAccent)
                    .background(SSColor.accent, in: RoundedRectangle(cornerRadius: SSRadius.card, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("assessment.manual.addRep")
                .accessibilityValue(Text(model.count.formatted()))
                Button("assessment.manual.undo") { model.removeRep() }
                    .buttonStyle(.ssSecondary)
            }
        case .review:
            VStack(spacing: SSSpacing.l) {
                Text("assessment.manual.confirmCount")
                    .font(SSFont.body)
                    .foregroundStyle(SSColor.textSecondary)
                Stepper(value: $model.count, in: 0...60) {
                    Text(model.count.formatted())
                        .font(SSFont.metric)
                        .foregroundStyle(SSColor.textPrimary)
                }
                .padding(SSSpacing.l)
                .ssCardBackground()
                Button("assessment.result.save") { onComplete(model.outcomeForCount()) }
                    .buttonStyle(.ssPrimary)
                    .accessibilityIdentifier("assessment.manual.saveCount")
            }
        }
    }

    @ViewBuilder
    private func stopwatch(doneTitle: LocalizedStringKey, onDone: @escaping () -> Void) -> some View {
        switch model.stage {
        case .ready:
            startButton
        case .running:
            VStack(spacing: SSSpacing.l) {
                timeDisplay(model.elapsed)
                Button(doneTitle) {
                    model.stopTimer()
                    onDone()
                }
                .buttonStyle(.ssPrimary)
                .accessibilityIdentifier("assessment.manual.stop")
                if model.definition.manual == .timeToTarget {
                    Button("assessment.manual.couldNotFinish") {
                        model.stopTimer()
                        onComplete(model.outcomeForTimedTarget(completed: false))
                    }
                    .buttonStyle(.ssSecondary)
                }
            }
        case .review:
            // Time ran out.
            Button("assessment.result.continue") {
                onComplete(model.definition.manual == .holdTime ? model.outcomeForHold() : model.outcomeForTimedTarget(completed: false))
            }
            .buttonStyle(.ssPrimary)
        }
    }

    private var startButton: some View {
        Button("assessment.manual.start") { model.start() }
            .buttonStyle(.ssPrimary)
            .accessibilityIdentifier("assessment.manual.start")
    }

    private func timeDisplay(_ seconds: Double) -> some View {
        Text(seconds.formatted(.number.precision(.fractionLength(1))))
            .font(.system(size: 64, weight: .semibold, design: .rounded).monospacedDigit())
            .foregroundStyle(SSColor.textPrimary)
            .accessibilityLabel(Text("player.secondsLeft \(Int(seconds.rounded()))"))
    }
}

/// Shows one test's outcome and lets the user keep it, try again or switch to manual.
struct MeasurementResultView: View {
    let definition: AssessmentDefinition
    let method: MeasurementMethod
    let outcome: MeasurementOutcome
    let onAccept: () -> Void
    let onRetry: () -> Void
    var onUseManual: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: SSSpacing.l) {
            Text(LocalizedStringKey(definition.nameKey))
                .font(SSFont.title)
                .foregroundStyle(SSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)

            switch outcome.status {
            case .valid:
                if let value = outcome.value {
                    Text(MeasurementText.value(value, unit: outcome.unit))
                        .font(SSFont.metric)
                        .foregroundStyle(SSColor.textPrimary)
                }
                Text(method == .camera ? LocalizedStringKey("assessment.result.cameraEstimate") : "assessment.result.manualNote")
                    .font(SSFont.callout)
                    .foregroundStyle(SSColor.textSecondary)
            case .rejectedLowQuality:
                SSEmptyState("assessment.result.lowQuality", systemImage: "exclamationmark.triangle")
            default:
                SSEmptyState("assessment.result.notCompleted", systemImage: "checkmark.circle")
            }

            Spacer(minLength: 0)
            VStack(spacing: SSSpacing.s) {
                if outcome.status != .rejectedLowQuality {
                    Button("assessment.result.save", action: onAccept)
                        .buttonStyle(.ssPrimary)
                        .accessibilityIdentifier("assessment.result.save")
                }
                Button("assessment.result.retry", action: onRetry)
                    .buttonStyle(outcome.status == .rejectedLowQuality ? AnyButtonStyle(.ssPrimary) : AnyButtonStyle(.ssSecondary))
                if let onUseManual {
                    Button("assessment.useManual", action: onUseManual)
                        .buttonStyle(.ssSecondary)
                }
            }
        }
        .padding(SSSpacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Type-erased button style so a style can be chosen at runtime.
struct AnyButtonStyle: ButtonStyle {
    private let make: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        make = { AnyView(style.makeBody(configuration: $0)) }
    }

    func makeBody(configuration: Configuration) -> some View {
        make(configuration)
    }
}
