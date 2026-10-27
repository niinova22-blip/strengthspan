import Observation
import OSLog
import SwiftData
import SwiftUI

@Observable
@MainActor
final class AssessmentFlowModel {
    enum Step: Equatable {
        case overview
        case intro(Int)
        case measuring(Int, MeasurementMethod)
        case summary
        case safetyCheck
        case stopped(SafetyDecision)
        case saved
    }

    let definitions = AssessmentCatalog.all
    private(set) var step: Step = .overview
    private(set) var outcomes: [String: (MeasurementMethod, MeasurementOutcome)] = [:]
    private var session: AssessmentSession?
    private var stepBeforeSafetyCheck: Step = .overview
    private let store: AssessmentStore
    private let training: TrainingStore
    private let clock: any AppClock

    init(store: AssessmentStore, training: TrainingStore, clock: any AppClock) {
        self.store = store
        self.training = training
        self.clock = clock
    }

    var isFinished: Bool {
        switch step {
        case .saved, .stopped: true
        default: false
        }
    }

    func begin() {
        session = perform { try store.startSession(now: clock.now) }
        step = .intro(0)
    }

    func choose(_ method: MeasurementMethod, at index: Int) {
        step = .measuring(index, method)
    }

    func accept(_ outcome: MeasurementOutcome, method: MeasurementMethod, at index: Int) {
        let definition = definitions[index]
        if let session {
            perform { try store.record(outcome, for: definition, method: method, in: session, now: clock.now) }
        }
        outcomes[definition.key] = (method, outcome)
        advance(from: index)
    }

    func skip(at index: Int) {
        if let session {
            perform { try store.recordSkipped(definitions[index], in: session, now: clock.now) }
        }
        advance(from: index)
    }

    func save() {
        if let session {
            perform { try store.complete(session, now: clock.now) }
        }
        step = .saved
    }

    func reportUnwell() {
        stepBeforeSafetyCheck = step
        step = .safetyCheck
    }

    func cancelSafetyCheck() {
        step = stepBeforeSafetyCheck
    }

    func stop(reason: SafetyStopReason) {
        let decision = perform { try training.report(reason, now: clock.now) } ?? .none
        discardIfUnfinished()
        step = .stopped(decision)
    }

    /// Leaves no half-finished session behind when the user closes the flow.
    func discardIfUnfinished() {
        guard let session, session.status != .completed else { return }
        perform { try store.discard(session) }
        self.session = nil
    }

    private func advance(from index: Int) {
        step = index + 1 < definitions.count ? .intro(index + 1) : .summary
    }

    @discardableResult
    private func perform<T>(_ work: () throws -> T) -> T? {
        do {
            return try work()
        } catch {
            Logger.persistence.error("Assessment update failed: \(String(describing: error))")
            return nil
        }
    }
}

struct AssessmentFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: AssessmentFlowModel
    private let voiceEnabled: Bool
    private let cameraAvailable = PoseCaptureSession.isCameraAvailable

    init(model: AssessmentFlowModel, voiceEnabled: Bool) {
        _model = State(initialValue: model)
        self.voiceEnabled = voiceEnabled
    }

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(SSColor.background.ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("common.close") {
                            model.discardIfUnfinished()
                            dismiss()
                        }
                        .accessibilityIdentifier("assessment.close")
                    }
                    ToolbarItem(placement: .principal) {
                        if case .intro(let index) = model.step {
                            Text("assessment.progress \(index + 1) \(model.definitions.count)")
                                .font(SSFont.callout)
                                .foregroundStyle(SSColor.textSecondary)
                        }
                    }
                }
        }
        .interactiveDismissDisabled()
    }

    @ViewBuilder
    private var content: some View {
        switch model.step {
        case .overview:
            overview
        case .intro(let index):
            intro(model.definitions[index], index: index)
        case .measuring(let index, let method):
            measuring(model.definitions[index], index: index, method: method)
        case .summary:
            summary
        case .safetyCheck:
            SafetyCheckView(onSelect: { model.stop(reason: $0) }, onCancel: { model.cancelSafetyCheck() })
        case .stopped(let decision):
            SessionOutcomeView(kind: .stopped, decision: decision) { dismiss() }
        case .saved:
            saved
        }
    }

    // MARK: Steps

    private var overview: some View {
        scrollingPage {
            Image(systemName: "ruler")
                .font(.system(size: 48))
                .foregroundStyle(SSColor.accent)
                .accessibilityHidden(true)
            Text("assessment.overview.title")
                .font(SSFont.largeTitle)
                .foregroundStyle(SSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("assessment.overview.message")
                .font(SSFont.body)
                .foregroundStyle(SSColor.textSecondary)
            SSCard("assessment.overview.prepare", systemImage: "chair") {
                Text("assessment.overview.prepareList")
                    .font(SSFont.body)
                    .foregroundStyle(SSColor.textPrimary)
            }
            Text("settings.disclaimer")
                .font(SSFont.footnote)
                .foregroundStyle(SSColor.textSecondary)
        } actions: {
            Button("assessment.overview.start") { model.begin() }
                .buttonStyle(.ssPrimary)
                .accessibilityIdentifier("assessment.overview.start")
        }
    }

    private func intro(_ definition: AssessmentDefinition, index: Int) -> some View {
        scrollingPage {
            Text(definition.dimension.title)
                .font(SSFont.callout.weight(.semibold))
                .foregroundStyle(SSColor.accent)
            Text(LocalizedStringKey(definition.nameKey))
                .font(SSFont.largeTitle)
                .foregroundStyle(SSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(LocalizedStringKey(definition.instructionKey))
                .font(SSFont.body)
                .foregroundStyle(SSColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if definition.usesSupport {
                Label("player.useSupport", systemImage: "chair")
                    .font(SSFont.callout)
                    .foregroundStyle(SSColor.textSecondary)
            }
            if definition.supportsCamera && cameraAvailable {
                SSCard("assessment.intro.cameraSetup", systemImage: "iphone") {
                    Text(LocalizedStringKey(definition.setupKey))
                        .font(SSFont.body)
                        .foregroundStyle(SSColor.textPrimary)
                    if definition.camera == .beta {
                        Text("assessment.intro.beta")
                            .font(SSFont.footnote)
                            .foregroundStyle(SSColor.caution)
                    }
                }
            }
            Button {
                model.reportUnwell()
            } label: {
                Label("player.unwell", systemImage: "exclamationmark.triangle")
            }
            .buttonStyle(UnwellButtonStyle())
        } actions: {
            if definition.supportsCamera && cameraAvailable {
                Button("assessment.intro.useCamera") { model.choose(.camera, at: index) }
                    .buttonStyle(.ssPrimary)
                Button("assessment.useManual") { model.choose(.manual, at: index) }
                    .buttonStyle(.ssSecondary)
                    .accessibilityIdentifier("assessment.intro.manual")
            } else {
                Button("assessment.useManual") { model.choose(.manual, at: index) }
                    .buttonStyle(.ssPrimary)
                    .accessibilityIdentifier("assessment.intro.manual")
            }
            Button("assessment.intro.skip") { model.skip(at: index) }
                .buttonStyle(.ssSecondary)
                .accessibilityIdentifier("assessment.intro.skip")
        }
    }

    @ViewBuilder
    private func measuring(_ definition: AssessmentDefinition, index: Int, method: MeasurementMethod) -> some View {
        switch method {
        case .camera:
            CameraMeasurementView(
                definition: definition,
                voiceEnabled: voiceEnabled,
                onComplete: { model.accept($0, method: .camera, at: index) },
                onUseManual: { model.choose(.manual, at: index) }
            )
            .id("camera-\(definition.key)")
        case .manual:
            ManualFlow(definition: definition, voiceEnabled: voiceEnabled) { outcome in
                model.accept(outcome, method: .manual, at: index)
            }
            .id("manual-\(definition.key)")
        }
    }

    private var summary: some View {
        scrollingPage {
            Text("assessment.summary.title")
                .font(SSFont.largeTitle)
                .foregroundStyle(SSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            ForEach(model.definitions) { definition in
                HStack(alignment: .firstTextBaseline) {
                    Text(LocalizedStringKey(definition.nameKey))
                        .font(SSFont.body)
                        .foregroundStyle(SSColor.textPrimary)
                    Spacer()
                    Text(summaryValue(for: definition))
                        .font(SSFont.headline.monospacedDigit())
                        .foregroundStyle(SSColor.textPrimary)
                        .multilineTextAlignment(.trailing)
                }
                .padding(SSSpacing.l)
                .ssCardBackground()
                .accessibilityElement(children: .combine)
            }
            Text("assessment.summary.note")
                .font(SSFont.footnote)
                .foregroundStyle(SSColor.textSecondary)
        } actions: {
            Button("assessment.summary.save") { model.save() }
                .buttonStyle(.ssPrimary)
                .accessibilityIdentifier("assessment.summary.save")
        }
    }

    private var saved: some View {
        scrollingPage {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 56))
                .foregroundStyle(SSColor.accent)
                .accessibilityHidden(true)
            Text("assessment.saved.title")
                .font(SSFont.largeTitle)
                .foregroundStyle(SSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("assessment.saved.message")
                .font(SSFont.body)
                .foregroundStyle(SSColor.textSecondary)
        } actions: {
            Button("common.done") { dismiss() }
                .buttonStyle(.ssPrimary)
                .accessibilityIdentifier("assessment.saved.done")
        }
    }

    private func summaryValue(for definition: AssessmentDefinition) -> String {
        guard let outcome = model.outcomes[definition.key]?.1 else { return String(localized: "assessment.summary.skipped") }
        guard outcome.status == .valid, let value = outcome.value else { return String(localized: "assessment.summary.noResult") }
        return MeasurementText.value(value, unit: outcome.unit)
    }

    private func scrollingPage<Content: View, Actions: View>(
        @ViewBuilder _ content: () -> Content,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: SSSpacing.l) {
                    content()
                }
                .padding(SSSpacing.l)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(spacing: SSSpacing.s) {
                actions()
            }
            .padding(SSSpacing.l)
            .background(SSColor.background)
        }
    }
}

/// Manual measurement followed by its result screen.
private struct ManualFlow: View {
    let definition: AssessmentDefinition
    let voiceEnabled: Bool
    let onAccept: (MeasurementOutcome) -> Void
    @State private var outcome: MeasurementOutcome?
    @State private var attempt = 0

    var body: some View {
        if let outcome {
            MeasurementResultView(definition: definition, method: .manual, outcome: outcome, onAccept: { onAccept(outcome) }, onRetry: {
                self.outcome = nil
                attempt += 1
            })
        } else {
            ManualMeasurementView(definition: definition, voiceEnabled: voiceEnabled) { outcome = $0 }
                .id(attempt)
        }
    }
}
