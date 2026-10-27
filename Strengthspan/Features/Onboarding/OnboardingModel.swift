import Foundation
import Observation

@Observable
@MainActor
final class OnboardingModel {
    enum Step: Int, CaseIterable {
        case welcome
        case ageRange
        case activity
        case experience
        case goal
        case days
        case sessionLength
        case equipment
        case screening
        case painRegions
        case result
    }

    var step: Step = .welcome
    var ageRange: AgeRange?
    var activity: ActivityLevel?
    var experience: ExperienceLevel?
    var goal: PrimaryGoal?
    var weekdays: Set<Int> = []
    var sessionLength: SessionLength?
    /// Owned equipment; empty means bodyweight only.
    var equipment: Set<Equipment> = []
    var hasChosenEquipment = false
    var screeningAnswers: [ScreeningQuestion: Bool] = [:]
    var painRegions: Set<BodyRegion> = []

    var canContinue: Bool {
        switch step {
        case .welcome, .result: true
        case .ageRange: ageRange != nil
        case .activity: activity != nil
        case .experience: experience != nil
        case .goal: goal != nil
        case .days: !weekdays.isEmpty
        case .sessionLength: sessionLength != nil
        case .equipment: hasChosenEquipment
        case .screening: screeningAnswers.count == ScreeningQuestion.allCases.count
        case .painRegions: !painRegions.isEmpty
        }
    }

    var progress: Double {
        Double(step.rawValue) / Double(Step.allCases.count - 1)
    }

    var screeningYes: Set<ScreeningQuestion> {
        Set(screeningAnswers.filter(\.value).map(\.key))
    }

    var screeningResult: ScreeningResult {
        ScreeningEvaluator.evaluate(yesAnswers: screeningYes, painRegions: painRegions)
    }

    var answers: OnboardingAnswers? {
        guard let ageRange, let activity, let experience, let goal, let sessionLength else { return nil }
        return OnboardingAnswers(
            ageRange: ageRange,
            activityLevel: activity,
            experienceLevel: experience,
            primaryGoal: goal,
            weekdays: weekdays,
            sessionLength: sessionLength,
            equipment: equipment,
            screeningYes: screeningYes,
            painRegions: screeningYes.contains(.jointPain) ? painRegions : []
        )
    }

    func next() {
        guard canContinue, let following = Step(rawValue: step.rawValue + 1) else { return }
        step = (following == .painRegions && !screeningYes.contains(.jointPain)) ? .result : following
    }

    func back() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = (previous == .painRegions && !screeningYes.contains(.jointPain)) ? .screening : previous
    }

    func toggleWeekday(_ weekday: Int) {
        if weekdays.contains(weekday) { weekdays.remove(weekday) } else { weekdays.insert(weekday) }
    }

    func chooseBodyweightOnly() {
        equipment = []
        hasChosenEquipment = true
    }

    func toggleEquipment(_ item: Equipment) {
        if equipment.contains(item) { equipment.remove(item) } else { equipment.insert(item) }
        hasChosenEquipment = !equipment.isEmpty
    }

    func togglePainRegion(_ region: BodyRegion) {
        if painRegions.contains(region) { painRegions.remove(region) } else { painRegions.insert(region) }
    }
}
