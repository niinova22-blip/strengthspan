import Foundation

/// Source of the current time. Injected so date-dependent logic is deterministic in tests.
protocol AppClock: Sendable {
    var now: Date { get }
}

struct SystemClock: AppClock {
    var now: Date { Date() }
}

struct FixedClock: AppClock {
    let now: Date
}
