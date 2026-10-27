import SwiftData
import SwiftUI

/// Capacity Map overview. Shows the latest scored value per dimension, or an explicit
/// "not enough measurements" state. Comparisons and charts arrive in Phase 4.
struct ProgressDashboardView: View {
    @Query(sort: \CapacityMetric.computedAt, order: .reverse)
    private var metrics: [CapacityMetric]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SSSpacing.l) {
                    Text("progress.capacityMap")
                        .font(SSFont.title)
                        .foregroundStyle(SSColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    ForEach(CapacityDimension.allCases, id: \.self) { dimension in
                        CapacityDimensionRow(
                            dimension: dimension,
                            score: latestScore(for: dimension)
                        )
                    }

                    Text("progress.capacityMap.footnote")
                        .font(SSFont.footnote)
                        .foregroundStyle(SSColor.textSecondary)
                }
                .padding(.horizontal, SSSpacing.l)
                .padding(.vertical, SSSpacing.m)
            }
            .background(SSColor.background.ignoresSafeArea())
            .navigationTitle("progress.title")
        }
    }

    private func latestScore(for dimension: CapacityDimension) -> Double? {
        metrics.first { $0.dimension == dimension && $0.score != nil }?.score
    }
}

private struct CapacityDimensionRow: View {
    let dimension: CapacityDimension
    let score: Double?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: SSSpacing.m) {
                title
                Spacer(minLength: SSSpacing.s)
                value
            }
            VStack(alignment: .leading, spacing: SSSpacing.s) {
                title
                value
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SSSpacing.l)
        .ssCardBackground()
        .accessibilityElement(children: .combine)
    }

    private var title: some View {
        Label {
            Text(dimension.title)
                .font(SSFont.headline)
                .foregroundStyle(SSColor.textPrimary)
        } icon: {
            Image(systemName: dimension.systemImage)
                .foregroundStyle(SSColor.accent)
        }
    }

    @ViewBuilder
    private var value: some View {
        if let score {
            Text(score, format: .number.precision(.fractionLength(0)))
                .font(SSFont.metric)
                .foregroundStyle(SSColor.textPrimary)
        } else {
            Text("progress.metric.insufficient")
                .font(SSFont.callout)
                .foregroundStyle(SSColor.textSecondary)
        }
    }
}

#if DEBUG
#Preview {
    ProgressDashboardView()
        .modelContainer(PreviewSupport.container(populated: true))
}
#endif
