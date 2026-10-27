import Foundation

/// A stored test result as plain values.
struct ResultSnapshot: Equatable, Sendable {
    let date: Date
    let assessmentKey: String
    let definitionVersion: Int
    let method: MeasurementMethod
    let status: AssessmentResultStatus
    let value: Double?
    let unit: MeasurementUnit
    let reliability: MeasurementReliability
    let usedSupport: Bool
    let setupVariant: String

    /// Only valid, trustworthy results can be shown as a capacity value or compared.
    var isUsable: Bool { status == .valid && value != nil && reliability.isComparable }
}

struct ResultComparison: Equatable, Sendable {
    let baseline: ResultSnapshot
    let latest: ResultSnapshot
    let delta: Double
    /// `nil` when the baseline is zero.
    let percentChange: Double?
    /// `nil` when unchanged.
    let improved: Bool?
}

enum ComparisonResult: Equatable, Sendable {
    /// No usable result yet: show "Not enough measurements yet".
    case none
    /// Exactly one usable result (or none comparable to it yet).
    case single(ResultSnapshot)
    case compared(ResultComparison)
    /// There are earlier results, but none measured the same way as the latest.
    case notComparable(latest: ResultSnapshot)
}

/// Proof-of-progress rules (docs/01 §5.6): changes are only claimed between results of the same test,
/// version, method, setup and support, both valid with at least moderate reliability.
enum ProgressComparison {
    static func areComparable(_ a: ResultSnapshot, _ b: ResultSnapshot) -> Bool {
        a.isUsable && b.isUsable
            && a.assessmentKey == b.assessmentKey
            && a.definitionVersion == b.definitionVersion
            && a.method == b.method
            && a.unit == b.unit
            && a.setupVariant == b.setupVariant
            && a.usedSupport == b.usedSupport
    }

    static func compare(_ history: [ResultSnapshot], higherIsBetter: Bool) -> ComparisonResult {
        let usable = history.filter(\.isUsable).sorted { $0.date < $1.date }
        guard let latest = usable.last else { return .none }
        guard let baseline = usable.first(where: { areComparable($0, latest) }), baseline.date < latest.date,
              let start = baseline.value, let end = latest.value else {
            return usable.count > 1 ? .notComparable(latest: latest) : .single(latest)
        }
        let delta = end - start
        let percent = start == 0 ? nil : (delta / abs(start) * 100).rounded(toPlaces: 0)
        let improved: Bool? = delta == 0 ? nil : (higherIsBetter ? delta > 0 : delta < 0)
        return .compared(ResultComparison(baseline: baseline, latest: latest, delta: delta, percentChange: percent, improved: improved))
    }
}

/// Non-punishing consistency figures (docs/01 §5.7).
enum ConsistencySummary {
    struct SessionRecord: Equatable, Sendable {
        let scheduledDate: Date
        let status: SessionStatus
        let completedAt: Date?
    }

    struct Figures: Equatable, Sendable {
        /// Sessions completed in the window.
        let completed: Int
        /// Sessions that were planned for days in the window up to today.
        let planned: Int
    }

    static func lastDays(_ days: Int, records: [SessionRecord], now: Date, calendar: Calendar) -> Figures {
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        let start = calendar.date(byAdding: .day, value: -days, to: endOfToday) ?? now
        let startOfToday = calendar.startOfDay(for: now)
        let window = start..<endOfToday

        var completed = 0
        var planned = 0
        for record in records {
            if record.status == .completed, let done = record.completedAt, window.contains(done) {
                completed += 1
            }
            // Today's session only counts as planned once it has been dealt with, so the figure
            // never reads as "missed" while the day is still open.
            let isOpenToday = record.status == .planned && record.scheduledDate >= startOfToday
            if window.contains(record.scheduledDate) && !isOpenToday {
                planned += 1
            }
        }
        return Figures(completed: completed, planned: max(planned, completed))
    }
}
