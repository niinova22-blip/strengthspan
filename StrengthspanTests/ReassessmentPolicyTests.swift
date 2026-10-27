import Foundation
import Testing
@testable import Strengthspan

@Suite("Reassessment policy")
struct ReassessmentPolicyTests {
    private let policy = ReassessmentPolicy.standard
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test func withoutAssessmentTheUserHasNeverBeenAssessed() {
        #expect(policy.status(lastCompletedAssessment: nil, now: date(2026, 3, 1), calendar: calendar) == .neverAssessed)
    }

    @Test func nextCheckIsSuggestedTwentyEightDaysLater() {
        let status = policy.status(lastCompletedAssessment: date(2026, 3, 1), now: date(2026, 3, 11), calendar: calendar)
        #expect(status == .scheduled(date(2026, 3, 29, hour: 0), daysRemaining: 18))
    }

    @Test func checkIsDueOnTheTwentyEighthDay() {
        let status = policy.status(lastCompletedAssessment: date(2026, 3, 1), now: date(2026, 3, 29, hour: 7), calendar: calendar)
        #expect(status == .due(since: date(2026, 3, 29, hour: 0)))
    }

    @Test func checkStaysDueAfterTheInterval() {
        let status = policy.status(lastCompletedAssessment: date(2026, 3, 1), now: date(2026, 5, 2), calendar: calendar)
        #expect(status == .due(since: date(2026, 3, 29, hour: 0)))
    }

    @Test func timeOfDayDoesNotChangeTheRemainingDays() {
        let lateAssessment = date(2026, 3, 1, hour: 23)
        let early = policy.status(lastCompletedAssessment: lateAssessment, now: date(2026, 3, 28, hour: 0), calendar: calendar)
        let late = policy.status(lastCompletedAssessment: lateAssessment, now: date(2026, 3, 28, hour: 23), calendar: calendar)
        #expect(early == late)
        #expect(early == .scheduled(date(2026, 3, 29, hour: 0), daysRemaining: 1))
    }
}
