import SwiftUI

struct WorkoutPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: WorkoutPlayerModel
    private let hapticsEnabled: Bool

    init(model: WorkoutPlayerModel, hapticsEnabled: Bool) {
        _model = State(initialValue: model)
        self.hapticsEnabled = hapticsEnabled
    }

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(SSColor.background.ignoresSafeArea())
                .toolbar { toolbar }
                .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
        .sensoryFeedback(.success, trigger: model.completedSetCount) { _, _ in hapticsEnabled }
        .onDisappear { model.close() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .checkIn:
            CheckInView(model: model)
        case .exercise:
            ExerciseStepView(model: model)
        case .rest(let secondsLeft):
            RestView(model: model, secondsLeft: secondsLeft)
        case .feedback:
            FeedbackView { input, note in model.submitFeedback(input, note: note) }
        case .safetyCheck:
            SafetyCheckView(
                onSelect: { model.stop(reason: $0) },
                onCancel: { model.cancelSafetyCheck() }
            )
        case .stopped(let decision):
            SessionOutcomeView(kind: .stopped, decision: decision) { dismiss() }
        case .finished(let decision):
            SessionOutcomeView(kind: .finished, decision: decision) { dismiss() }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            switch model.phase {
            case .checkIn, .stopped, .finished:
                Button("common.close") { dismiss() }
            case .exercise, .rest:
                Button("player.end") { model.endEarly() }
            case .feedback, .safetyCheck:
                EmptyView()
            }
        }
        ToolbarItem(placement: .principal) {
            if model.phase == .exercise || isResting {
                ProgressView(value: model.progressFraction)
                    .tint(SSColor.accent)
                    .frame(width: 140, height: 44)
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("player.progress"))
                    .accessibilityValue(Text(model.progressFraction, format: .percent.precision(.fractionLength(0))))
            }
        }
    }

    private var isResting: Bool {
        if case .rest = model.phase { return true }
        return false
    }
}

// MARK: - Check-in

private struct CheckInView: View {
    let model: WorkoutPlayerModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: SSSpacing.l) {
                    Text("player.checkIn.title")
                        .font(SSFont.largeTitle)
                        .foregroundStyle(SSColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text("player.checkIn.question")
                        .font(SSFont.body)
                        .foregroundStyle(SSColor.textSecondary)

                    SSCard("player.checkIn.plan", systemImage: "list.bullet") {
                        ForEach(overview, id: \.order) { row in
                            HStack(alignment: .firstTextBaseline) {
                                Text(row.variant.nameText)
                                    .font(SSFont.body)
                                    .foregroundStyle(SSColor.textPrimary)
                                Spacer()
                                Text(row.summary)
                                    .font(SSFont.callout.monospacedDigit())
                                    .foregroundStyle(SSColor.textSecondary)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
                .padding(SSSpacing.l)
            }
            VStack(spacing: SSSpacing.s) {
                Button("player.checkIn.ok") { model.confirmCheckIn() }
                    .buttonStyle(.ssPrimary)
                    .accessibilityIdentifier("player.checkIn.ok")
                Button("player.checkIn.notOk") { model.reportUnwell() }
                    .buttonStyle(.ssSecondary)
            }
            .padding(SSSpacing.l)
        }
    }

    private struct Row {
        let order: Int
        let variant: ExerciseVariant
        let summary: String
    }

    private var overview: [Row] {
        Dictionary(grouping: model.orderedSets, by: \.orderIndex)
            .sorted { $0.key < $1.key }
            .compactMap { order, sets in
                guard let first = sets.first, let variant = ExerciseCatalog.variant(first.variantKey)?.variant else { return nil }
                let amount = first.targetReps.map { String(localized: "player.reps \($0)") }
                    ?? first.targetDurationSeconds.map { String(localized: "player.seconds \($0)") }
                    ?? ""
                return Row(order: order, variant: variant, summary: "\(sets.count) × \(amount)")
            }
    }
}

// MARK: - Exercise

private struct ExerciseStepView: View {
    @Bindable var model: WorkoutPlayerModel

    var body: some View {
        if let set = model.currentSet, let variant = model.currentVariant {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: SSSpacing.l) {
                        Text(set.block.titleKey)
                            .font(SSFont.callout.weight(.semibold))
                            .foregroundStyle(SSColor.accent)
                        Text(variant.nameText)
                            .font(SSFont.largeTitle)
                            .foregroundStyle(SSColor.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        Text("player.setOf \(set.setNumber) \(model.setCountOfCurrentExercise)")
                            .font(SSFont.headline)
                            .foregroundStyle(SSColor.textSecondary)

                        target(set: set)

                        if variant.tracksLoad {
                            loadStepper
                        }
                        if variant.usesSupport {
                            Label("player.useSupport", systemImage: "chair")
                                .font(SSFont.callout)
                                .foregroundStyle(SSColor.textSecondary)
                        }
                        Text(variant.instructionText)
                            .font(SSFont.body)
                            .foregroundStyle(SSColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        secondaryActions
                    }
                    .padding(SSSpacing.l)
                }
                primaryActions(set: set)
            }
            .overlay {
                if model.isPaused { pausedOverlay }
            }
        }
    }

    @ViewBuilder
    private func target(set: WorkoutSet) -> some View {
        if let seconds = model.timerSecondsLeft {
            Text(Duration.seconds(seconds), format: .time(pattern: .minuteSecond))
                .font(.system(size: 64, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(SSColor.textPrimary)
                .contentTransition(.numericText(countsDown: true))
                .accessibilityLabel(Text("player.secondsLeft \(seconds)"))
        } else if let reps = set.targetReps {
            Text("player.reps \(reps)")
                .font(SSFont.metric)
                .foregroundStyle(SSColor.textPrimary)
        }
    }

    private var loadStepper: some View {
        Stepper(value: $model.loadKg, in: 0...40, step: 0.5) {
            Text("player.load \(model.loadKg.formatted(.number.precision(.fractionLength(0...1))))")
                .font(SSFont.headline)
                .foregroundStyle(SSColor.textPrimary)
        }
        .frame(minHeight: SSLayout.minTouchTarget)
        .padding(.horizontal, SSSpacing.l)
        .ssCardBackground()
    }

    private var secondaryActions: some View {
        VStack(spacing: SSSpacing.s) {
            if model.easierVariant != nil {
                Button("player.easier") { model.switchToEasier() }
                    .buttonStyle(.ssSecondary)
            }
            HStack(spacing: SSSpacing.s) {
                Button("player.skipExercise") { model.skipExercise() }
                    .buttonStyle(.ssSecondary)
                Button("player.pause") { model.togglePause() }
                    .buttonStyle(.ssSecondary)
            }
            Button {
                model.reportUnwell()
            } label: {
                Label("player.unwell", systemImage: "exclamationmark.triangle")
            }
            .buttonStyle(UnwellButtonStyle())
            .accessibilityIdentifier("player.unwell")
        }
        .padding(.top, SSSpacing.m)
    }

    private func primaryActions(set: WorkoutSet) -> some View {
        VStack(spacing: SSSpacing.s) {
            if set.targetDurationSeconds != nil {
                Button(model.isTimerRunning ? LocalizedStringKey("player.timer.pause") : "player.timer.start") {
                    model.toggleTimer()
                }
                .buttonStyle(.ssPrimary)
                Button("player.setDone") { model.completeSet() }
                    .buttonStyle(.ssSecondary)
                    .accessibilityIdentifier("player.setDone")
            } else {
                Button("player.setDone") { model.completeSet() }
                    .buttonStyle(.ssPrimary)
                    .accessibilityIdentifier("player.setDone")
            }
        }
        .padding(SSSpacing.l)
        .background(SSColor.background)
    }

    private var pausedOverlay: some View {
        VStack(spacing: SSSpacing.l) {
            Text("player.paused")
                .font(SSFont.title)
                .foregroundStyle(SSColor.textPrimary)
            Button("player.resume") { model.togglePause() }
                .buttonStyle(.ssPrimary)
        }
        .padding(SSSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}

// MARK: - Rest

private struct RestView: View {
    let model: WorkoutPlayerModel
    let secondsLeft: Int

    var body: some View {
        VStack(spacing: SSSpacing.xl) {
            Spacer()
            Text("player.rest")
                .font(SSFont.title)
                .foregroundStyle(SSColor.textSecondary)
            Text(Duration.seconds(secondsLeft), format: .time(pattern: .minuteSecond))
                .font(.system(size: 72, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(SSColor.textPrimary)
                .contentTransition(.numericText(countsDown: true))
                .accessibilityLabel(Text("player.secondsLeft \(secondsLeft)"))
            if let next = model.currentVariant {
                VStack(spacing: SSSpacing.xs) {
                    Text("player.next")
                        .font(SSFont.callout)
                        .foregroundStyle(SSColor.textSecondary)
                    Text(next.nameText)
                        .font(SSFont.headline)
                        .foregroundStyle(SSColor.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .accessibilityElement(children: .combine)
            }
            Spacer()
            VStack(spacing: SSSpacing.s) {
                Button("player.skipRest") { model.skipRest() }
                    .buttonStyle(.ssPrimary)
                Button {
                    model.reportUnwell()
                } label: {
                    Label("player.unwell", systemImage: "exclamationmark.triangle")
                }
                .buttonStyle(UnwellButtonStyle())
            }
        }
        .padding(SSSpacing.l)
    }
}

/// Always-visible, clearly distinct safety exit. Uses the reserved stop color.
struct UnwellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SSFont.headline)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(SSColor.stop)
            .frame(maxWidth: .infinity, minHeight: SSLayout.minTouchTarget)
            .overlay(
                RoundedRectangle(cornerRadius: SSRadius.button, style: .continuous)
                    .strokeBorder(SSColor.stop, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
            .contentShape(Rectangle())
    }
}
