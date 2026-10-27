import SwiftData
import SwiftUI

/// Home screen. Answers three questions at a glance: what to do today, how far the user has
/// come, and when the next capacity check is. Each card shows an honest empty state until
/// the corresponding feature has produced real data.
struct TodayView: View {
    @Environment(\.appClock) private var clock
    @Environment(\.calendar) private var calendar
    @Environment(\.reassessmentPolicy) private var reassessmentPolicy

    @Query(sort: \WorkoutSession.scheduledDate)
    private var sessions: [WorkoutSession]

    @Query(filter: #Predicate<AssessmentSession> { $0.completedAt != nil },
           sort: \AssessmentSession.startedAt, order: .reverse)
    private var completedAssessments: [AssessmentSession]

    @Query(sort: \CapacityMetric.computedAt, order: .reverse)
    private var metrics: [CapacityMetric]

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
    }

    // MARK: Cards

    private var workoutCard: some View {
        SSCard("today.workout.title", systemImage: "figure.strengthtraining.functional") {
            if let session = todaysPlannedSession {
                Text("today.workout.planned \(session.plannedDurationMinutes)")
                    .font(SSFont.body)
                    .foregroundStyle(SSColor.textPrimary)
            } else {
                SSEmptyState("today.workout.empty.message", systemImage: "calendar.badge.clock")
            }
        }
    }

    private var progressCard: some View {
        SSCard("today.progress.title", systemImage: "chart.line.uptrend.xyaxis") {
            if measuredDimensionCount > 0 {
                Text("today.progress.measured \(measuredDimensionCount)")
                    .font(SSFont.body)
                    .foregroundStyle(SSColor.textPrimary)
            } else {
                SSEmptyState("today.progress.empty.message")
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
            }
            .font(SSFont.body)
        }
    }

    // MARK: Derived state

    private var todaysPlannedSession: WorkoutSession? {
        sessions.first { $0.status == .planned && calendar.isDate($0.scheduledDate, inSameDayAs: clock.now) }
    }

    private var measuredDimensionCount: Int {
        Set(metrics.filter { $0.score != nil }.compactMap(\.dimension)).count
    }

    private var reassessmentStatus: ReassessmentStatus {
        reassessmentPolicy.status(
            lastCompletedAssessment: completedAssessments.first?.completedAt,
            now: clock.now,
            calendar: calendar
        )
    }
}

#if DEBUG
#Preview("Empty") {
    TodayView()
        .modelContainer(PreviewSupport.container(populated: false))
}

#Preview("With data, Turkish") {
    TodayView()
        .modelContainer(PreviewSupport.container(populated: true))
        .environment(\.locale, Locale(identifier: "tr"))
}
#endif
