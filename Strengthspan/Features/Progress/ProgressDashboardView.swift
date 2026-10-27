import Charts
import SwiftData
import SwiftUI

/// Capacity map, proof of progress and consistency. Values are real test results compared only
/// with the user's own earlier, comparable results (docs/01 §5.3, §5.6, §5.7).
struct ProgressDashboardView: View {
    @Environment(\.appClock) private var clock
    @Environment(\.calendar) private var calendar
    @Environment(\.subscriptions) private var subscriptions

    @Query(sort: \AssessmentSession.startedAt) private var assessments: [AssessmentSession]
    @Query(sort: \WorkoutSession.scheduledDate) private var sessions: [WorkoutSession]
    @State private var showsPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SSSpacing.l) {
                    Text("progress.capacityMap")
                        .font(SSFont.title)
                        .foregroundStyle(SSColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    ForEach(CapacityDimension.allCases, id: \.self) { dimension in
                        let definition = AssessmentCatalog.primary(for: dimension)
                        DimensionCard(
                            dimension: dimension,
                            definition: definition,
                            history: snapshots(for: definition),
                            isPro: isPro,
                            onUnlock: { showsPaywall = true }
                        )
                    }

                    Text("progress.capacityMap.footnote")
                        .font(SSFont.footnote)
                        .foregroundStyle(SSColor.textSecondary)

                    consistencyCard
                    proofCard
                }
                .padding(.horizontal, SSSpacing.l)
                .padding(.vertical, SSSpacing.m)
            }
            .background(SSColor.background.ignoresSafeArea())
            .navigationTitle("progress.title")
            .sheet(isPresented: $showsPaywall) {
                PaywallView()
                    .environment(\.subscriptions, subscriptions)
            }
        }
    }

    // MARK: Cards

    private var consistencyCard: some View {
        let figures = ConsistencySummary.lastDays(30, records: sessionRecords, now: clock.now, calendar: calendar)
        return SSCard("progress.consistency.title", systemImage: "calendar") {
            if figures.planned == 0 {
                SSEmptyState("progress.consistency.empty")
            } else {
                Text("progress.consistency.last30 \(figures.completed) \(figures.planned)")
                    .font(SSFont.headline)
                    .foregroundStyle(SSColor.textPrimary)
                Text("progress.consistency.note")
                    .font(SSFont.footnote)
                    .foregroundStyle(SSColor.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var proofCard: some View {
        SSCard("progress.proof.title", systemImage: "checkmark.seal") {
            if isPro {
                let figures = ConsistencySummary.lastDays(28, records: sessionRecords, now: clock.now, calendar: calendar)
                Text("progress.proof.workouts \(figures.completed) \(figures.planned)")
                    .font(SSFont.body)
                    .foregroundStyle(SSColor.textPrimary)
                let loads = loadProgress
                if loads.isEmpty {
                    Text("progress.proof.noLoads")
                        .font(SSFont.callout)
                        .foregroundStyle(SSColor.textSecondary)
                } else {
                    ForEach(loads, id: \.variantKey) { load in
                        HStack {
                            Text(LocalizedStringKey("exercise.\(load.variantKey)" as String))
                                .font(SSFont.callout)
                                .foregroundStyle(SSColor.textPrimary)
                            Spacer()
                            Text(verbatim: "\(load.first.formatted()) → \(load.latest.formatted()) kg")
                                .font(SSFont.callout.monospacedDigit())
                                .foregroundStyle(SSColor.textPrimary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            } else {
                LockedTeaser(message: "progress.locked.proof", onUnlock: { showsPaywall = true })
            }
        }
    }

    // MARK: Data

    private var isPro: Bool { subscriptions?.isPro ?? false }

    private func snapshots(for definition: AssessmentDefinition) -> [ResultSnapshot] {
        assessments
            .filter { $0.status == .completed }
            .flatMap(\.results)
            .filter { $0.assessmentKey == definition.key }
            .compactMap(\.snapshot)
    }

    private var sessionRecords: [ConsistencySummary.SessionRecord] {
        sessions.map { .init(scheduledDate: $0.scheduledDate, status: $0.status, completedAt: $0.completedAt) }
    }

    private struct LoadProgress {
        let variantKey: String
        let first: Double
        let latest: Double
    }

    /// First and latest weight used per dumbbell exercise, from completed sessions only.
    private var loadProgress: [LoadProgress] {
        let loaded = sessions
            .filter { $0.status == .completed }
            .sorted { ($0.completedAt ?? $0.scheduledDate) < ($1.completedAt ?? $1.scheduledDate) }
            .flatMap { session in session.sets.compactMap { set in set.actualLoadKg.map { (set.variantKey, $0) } } }
        var first: [String: Double] = [:]
        var latest: [String: Double] = [:]
        var order: [String] = []
        for (key, load) in loaded {
            if first[key] == nil {
                first[key] = load
                order.append(key)
            }
            latest[key] = load
        }
        return order.compactMap { key in
            guard let start = first[key], let end = latest[key] else { return nil }
            return LoadProgress(variantKey: key, first: start, latest: end)
        }
    }
}

// MARK: - Dimension card

private struct DimensionCard: View {
    let dimension: CapacityDimension
    let definition: AssessmentDefinition
    let history: [ResultSnapshot]
    let isPro: Bool
    let onUnlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SSSpacing.m) {
            Label {
                Text(dimension.title)
                    .font(SSFont.headline)
                    .foregroundStyle(SSColor.textPrimary)
            } icon: {
                Image(systemName: dimension.systemImage)
                    .foregroundStyle(SSColor.accent)
            }
            .accessibilityAddTraits(.isHeader)

            Text(LocalizedStringKey(definition.nameKey))
                .font(SSFont.footnote)
                .foregroundStyle(SSColor.textSecondary)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SSSpacing.l)
        .ssCardBackground()
    }

    @ViewBuilder
    private var content: some View {
        switch ProgressComparison.compare(history, higherIsBetter: definition.higherIsBetter) {
        case .none:
            Text("progress.metric.insufficient")
                .font(SSFont.callout)
                .foregroundStyle(SSColor.textSecondary)
        case .single(let latest):
            value(latest)
            methodNote(latest)
            Text("progress.metric.first")
                .font(SSFont.footnote)
                .foregroundStyle(SSColor.textSecondary)
        case .notComparable(let latest):
            value(latest)
            methodNote(latest)
            Text("progress.metric.notComparable")
                .font(SSFont.footnote)
                .foregroundStyle(SSColor.textSecondary)
        case .compared(let comparison):
            value(comparison.latest)
            methodNote(comparison.latest)
            if isPro {
                change(comparison)
                chart(for: comparison.latest)
            } else {
                LockedTeaser(message: "progress.locked.change", onUnlock: onUnlock)
            }
        }
    }

    private func value(_ snapshot: ResultSnapshot) -> some View {
        Text(snapshot.value.map { MeasurementText.value($0, unit: snapshot.unit) } ?? "–")
            .font(SSFont.metric)
            .foregroundStyle(SSColor.textPrimary)
    }

    private func methodNote(_ snapshot: ResultSnapshot) -> some View {
        Text(snapshot.method == .camera ? LocalizedStringKey("progress.metric.camera") : "progress.metric.manual")
            .font(SSFont.footnote)
            .foregroundStyle(SSColor.textSecondary)
    }

    private func change(_ comparison: ResultComparison) -> some View {
        let unit = comparison.latest.unit
        let sign = comparison.delta > 0 ? "+" : (comparison.delta < 0 ? "−" : "")
        let amount = "\(sign)\(MeasurementText.value(abs(comparison.delta), unit: unit))"
        let percent = comparison.percentChange.map { " (\($0 > 0 ? "+" : "")\(Int($0))%)" } ?? ""
        let baseline = comparison.baseline.value.map { MeasurementText.value($0, unit: unit) } ?? "–"
        return VStack(alignment: .leading, spacing: SSSpacing.xs) {
            Label {
                Text(verbatim: amount + percent)
                    .font(SSFont.headline)
            } icon: {
                Image(systemName: comparison.improved == true ? "arrow.up.right.circle.fill" : "equal.circle")
            }
            .foregroundStyle(comparison.improved == true ? SSColor.accent : SSColor.textSecondary)
            Text("progress.metric.baseline \(baseline) \(comparison.baseline.date.formatted(date: .abbreviated, time: .omitted))")
                .font(SSFont.footnote)
                .foregroundStyle(SSColor.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func chart(for latest: ResultSnapshot) -> some View {
        let points = history.filter { ProgressComparison.areComparable($0, latest) }.sorted { $0.date < $1.date }
        if points.count >= 2 {
            Chart(points, id: \.date) { point in
                LineMark(x: .value("Date", point.date), y: .value("Value", point.value ?? 0))
                    .foregroundStyle(SSColor.accent)
                PointMark(x: .value("Date", point.date), y: .value("Value", point.value ?? 0))
                    .foregroundStyle(SSColor.accent)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .frame(height: 140)
            .accessibilityLabel(Text("progress.chart.label"))
        }
    }
}

private struct LockedTeaser: View {
    let message: LocalizedStringKey
    let onUnlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SSSpacing.s) {
            Label(message, systemImage: "lock")
                .font(SSFont.callout)
                .foregroundStyle(SSColor.textSecondary)
            Button("progress.locked.action", action: onUnlock)
                .buttonStyle(.ssSecondary)
        }
    }
}

#if DEBUG
#Preview {
    ProgressDashboardView()
        .modelContainer(PreviewSupport.container(populated: true))
}
#endif
