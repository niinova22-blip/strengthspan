import OSLog
import SwiftData
import SwiftUI

/// Home screen. Answers three questions at a glance: what to do today, how far the user has
/// come, and when the next capacity check is.
struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appClock) private var clock
    @Environment(\.calendar) private var calendar
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.reassessmentPolicy) private var reassessmentPolicy
    @Environment(\.subscriptions) private var subscriptions

    @Query private var profiles: [UserProfile]
    @Query(sort: \WorkoutSession.scheduledDate) private var sessions: [WorkoutSession]
    // Filtered in memory: a #Predicate on the optional `completedAt` key path triggers
    // Sendable warnings under strict concurrency, and a user has only a few sessions.
    @Query(sort: \AssessmentSession.startedAt, order: .reverse) private var assessments: [AssessmentSession]
    @Query(sort: \CapacityMetric.computedAt, order: .reverse) private var metrics: [CapacityMetric]

    @State private var blockReason: PlanBlockReason?
    @State private var refreshID = 0
    @State private var activeSession: WorkoutSession?
    @State private var confirmingClearance = false
    @State private var confirmingRecovery = false
    @State private var showsPaywall = false
    @State private var showsAssessment = false
    @State private var playedSession: WorkoutSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SSSpacing.l) {
                    workoutCard
                    progressCard
                    assessmentCard
                }
                .padding(.horizontal, SSSpacing.l)
                .padding(.vertical, SSSpacing.m)
            }
            .background(SSColor.background.ignoresSafeArea())
            .navigationTitle("today.title")
        }
        .task(id: refreshID) { refreshPlan() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshID += 1 }
        }
        .fullScreenCover(item: $activeSession, onDismiss: workoutDismissed) { session in
            WorkoutPlayerView(
                model: WorkoutPlayerModel(
                    session: session,
                    store: store,
                    clock: clock,
                    voiceEnabled: preferences?.voiceGuidanceEnabled ?? true
                ),
                hapticsEnabled: preferences?.hapticsEnabled ?? true
            )
        }
        .fullScreenCover(isPresented: $showsAssessment, onDismiss: { refreshID += 1 }) {
            AssessmentFlowView(
                model: AssessmentFlowModel(store: AssessmentStore(context: modelContext, calendar: calendar), training: store, clock: clock),
                voiceEnabled: preferences?.voiceGuidanceEnabled ?? true
            )
        }
        .sheet(isPresented: $showsPaywall) {
            PaywallView()
                .environment(\.subscriptions, subscriptions)
        }
        .confirmationDialog("today.blocked.review.confirm", isPresented: $confirmingClearance, titleVisibility: .visible) {
            Button("today.blocked.review.action") { update { try $0.confirmProfessionalClearance(now: clock.now) } }
        }
        .confirmationDialog("today.blocked.dizziness.confirm", isPresented: $confirmingRecovery, titleVisibility: .visible) {
            Button("today.blocked.dizziness.action") { update { try $0.resolveDizziness(now: clock.now) } }
        }
    }

    // MARK: Cards

    private var workoutCard: some View {
        SSCard("today.workout.title", systemImage: "figure.strengthtraining.functional") {
            switch blockReason {
            case .professionalReviewRecommended:
                blockedContent("today.blocked.review.message", action: "today.blocked.review.action") { confirmingClearance = true }
            case .dizzinessReported:
                blockedContent("today.blocked.dizziness.message", action: "today.blocked.dizziness.action") { confirmingRecovery = true }
            case .notScreened:
                SSEmptyState("today.workout.empty.message", systemImage: "calendar.badge.clock")
            case nil:
                sessionContent
            }
        }
    }

    @ViewBuilder
    private var sessionContent: some View {
        if let session = todaysSession {
            VStack(alignment: .leading, spacing: SSSpacing.m) {
                if isReturnWeek {
                    Label("today.workout.returnWeek", systemImage: "arrow.uturn.backward.circle")
                        .font(SSFont.callout)
                        .foregroundStyle(SSColor.accent)
                }
                Text("today.workout.planned \(session.plannedDurationMinutes)")
                    .font(SSFont.headline)
                    .foregroundStyle(SSColor.textPrimary)
                Text("today.workout.exerciseCount \(Set(session.sets.map(\.orderIndex)).count)")
                    .font(SSFont.callout)
                    .foregroundStyle(SSColor.textSecondary)
                Button(session.status == .inProgress ? LocalizedStringKey("today.workout.continue") : "today.workout.start") {
                    startWorkout(session)
                }
                .buttonStyle(.ssPrimary)
                .accessibilityIdentifier("today.workout.start")
            }
        } else if finishedToday {
            Label("today.workout.done", systemImage: "checkmark.circle.fill")
                .font(SSFont.body)
                .foregroundStyle(SSColor.textPrimary)
            nextSessionText
        } else if nextSession != nil {
            nextSessionText
        } else {
            SSEmptyState("today.workout.empty.message", systemImage: "calendar.badge.clock")
        }
    }

    @ViewBuilder
    private var nextSessionText: some View {
        if let next = nextSession {
            Text("today.workout.next \(next.scheduledDate.formatted(.dateTime.weekday(.wide).day().month(.wide)))")
                .font(SSFont.body)
                .foregroundStyle(SSColor.textSecondary)
        }
    }

    private func blockedContent(_ message: LocalizedStringKey, action: LocalizedStringKey, perform: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: SSSpacing.m) {
            Text(message)
                .font(SSFont.body)
                .foregroundStyle(SSColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Button(action, action: perform)
                .buttonStyle(.ssSecondary)
        }
    }

    private var progressCard: some View {
        SSCard("today.progress.title", systemImage: "chart.line.uptrend.xyaxis") {
            VStack(alignment: .leading, spacing: SSSpacing.s) {
                if !isPro {
                    Text("today.progress.freeWorkouts \(max(0, FeatureAccess.freeWorkoutLimit - completedWorkoutCount))")
                        .font(SSFont.footnote)
                        .foregroundStyle(SSColor.textSecondary)
                }
                if !currentPlanSessions.isEmpty {
                    Text("today.progress.week \(currentPlanSessions.filter { $0.status == .completed }.count) \(currentPlanSessions.count)")
                        .font(SSFont.body)
                        .foregroundStyle(SSColor.textPrimary)
                }
                if measuredDimensionCount > 0 {
                    Text("today.progress.measured \(measuredDimensionCount)")
                        .font(SSFont.body)
                        .foregroundStyle(SSColor.textPrimary)
                } else {
                    SSEmptyState("today.progress.empty.message")
                }
            }
        }
    }

    private var assessmentCard: some View {
        SSCard("today.assessment.title", systemImage: "ruler") {
            VStack(alignment: .leading, spacing: SSSpacing.s) {
                switch reassessmentStatus {
                case .neverAssessed:
                    Text("today.assessment.never")
                        .foregroundStyle(SSColor.textPrimary)
                case .scheduled(let date, _):
                    Text("today.assessment.scheduled \(date.formatted(date: .long, time: .omitted))")
                        .foregroundStyle(SSColor.textPrimary)
                case .due:
                    Text("today.assessment.due")
                        .foregroundStyle(SSColor.textPrimary)
                }

                Text("today.assessment.cadence")
                    .font(SSFont.footnote)
                    .foregroundStyle(SSColor.textSecondary)

                Button(completedAssessmentCount == 0 ? LocalizedStringKey("today.assessment.start") : "today.assessment.reassess") {
                    startAssessment()
                }
                .buttonStyle(reassessmentStatus == .neverAssessed || isDue ? AnyButtonStyle(.ssPrimary) : AnyButtonStyle(.ssSecondary))
                .accessibilityIdentifier("today.assessment.start")
            }
            .font(SSFont.body)
        }
    }

    // MARK: Derived state

    private var store: TrainingStore {
        TrainingStore(context: modelContext, calendar: calendar)
    }

    private var preferences: UserPreferences? {
        profiles.first?.preferences
    }

    private var currentPlanSessions: [WorkoutSession] {
        sessions.filter { $0.plan?.status == .active }
    }

    private var isReturnWeek: Bool {
        currentPlanSessions.first?.plan?.isReturnWeek ?? false
    }

    private var todaysSession: WorkoutSession? {
        currentPlanSessions.first {
            ($0.status == .planned || $0.status == .inProgress) && calendar.isDate($0.scheduledDate, inSameDayAs: clock.now)
        }
    }

    private var finishedToday: Bool {
        sessions.contains { $0.status == .completed && calendar.isDate($0.completedAt ?? .distantPast, inSameDayAs: clock.now) }
    }

    private var nextSession: WorkoutSession? {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: clock.now)) ?? clock.now
        return currentPlanSessions.first { $0.status == .planned && $0.scheduledDate >= tomorrow }
    }

    private var measuredDimensionCount: Int {
        Set(metrics.filter { $0.value != nil }.compactMap(\.dimension)).count
    }

    private var reassessmentStatus: ReassessmentStatus {
        reassessmentPolicy.status(
            lastCompletedAssessment: assessments.lazy.compactMap(\.completedAt).first,
            now: clock.now,
            calendar: calendar
        )
    }

    private var isPro: Bool { subscriptions?.isPro ?? false }

    private var completedWorkoutCount: Int {
        sessions.filter { $0.status == .completed }.count
    }

    private var completedAssessmentCount: Int {
        assessments.filter { $0.completedAt != nil }.count
    }

    private var isDue: Bool {
        if case .due = reassessmentStatus { return true }
        return false
    }

    // MARK: Actions

    private func startWorkout(_ session: WorkoutSession) {
        // A workout already under way can always be finished.
        guard session.status == .inProgress || FeatureAccess.canStartWorkout(isPro: isPro, completedWorkouts: completedWorkoutCount) else {
            showsPaywall = true
            return
        }
        playedSession = session
        activeSession = session
    }

    private func startAssessment() {
        guard FeatureAccess.canStartAssessment(isPro: isPro, completedAssessments: completedAssessmentCount) else {
            showsPaywall = true
            return
        }
        showsAssessment = true
    }

    private func workoutDismissed() {
        refreshID += 1
        guard let session = playedSession else { return }
        playedSession = nil
        guard FeatureAccess.canUseHealthKit(isPro: isPro),
              preferences?.saveToHealthEnabled == true,
              session.status == .completed,
              session.exportedToHealthAt == nil,
              let start = session.startedAt, let end = session.completedAt else { return }
        Task {
            do {
                try await HealthKitService.shared.saveStrengthWorkout(start: start, end: end)
                session.exportedToHealthAt = clock.now
                try modelContext.save()
            } catch {
                Logger.persistence.error("Saving to Apple Health failed: \(String(describing: error))")
            }
        }
    }

    private func refreshPlan() {
        do {
            switch try store.ensureCurrentPlan(now: clock.now) {
            case .blocked(let reason): blockReason = reason
            case .ready: blockReason = nil
            }
        } catch {
            Logger.persistence.error("Preparing the plan failed: \(String(describing: error))")
        }
    }

    private func update(_ change: (TrainingStore) throws -> Void) {
        do {
            try change(store)
        } catch {
            Logger.persistence.error("Updating safety status failed: \(String(describing: error))")
        }
        refreshID += 1
    }
}

#if DEBUG
#Preview("With data") {
    TodayView()
        .modelContainer(PreviewSupport.container(populated: true))
}

#Preview("Turkish") {
    TodayView()
        .modelContainer(PreviewSupport.container(populated: true))
        .environment(\.locale, Locale(identifier: "tr"))
}
#endif
