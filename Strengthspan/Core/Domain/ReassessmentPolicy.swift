import Foundation

enum ReassessmentStatus: Equatable, Sendable {
    case neverAssessed
    case scheduled(Date, daysRemaining: Int)
    case due(since: Date)
}

/// Decides when the next capacity check should be suggested.
/// Days are counted in the user's calendar so the answer doesn't change with the time of day.
struct ReassessmentPolicy: Sendable {
    static let standard = ReassessmentPolicy(intervalDays: 28)

    let intervalDays: Int

    func nextDate(afterAssessmentOn date: Date, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: intervalDays, to: start) ?? start
    }

    func status(lastCompletedAssessment: Date?, now: Date, calendar: Calendar) -> ReassessmentStatus {
        guard let lastCompletedAssessment else { return .neverAssessed }

        let next = nextDate(afterAssessmentOn: lastCompletedAssessment, calendar: calendar)
        let today = calendar.startOfDay(for: now)
        let daysRemaining = calendar.dateComponents([.day], from: today, to: next).day ?? 0

        return daysRemaining > 0 ? .scheduled(next, daysRemaining: daysRemaining) : .due(since: next)
    }
}
