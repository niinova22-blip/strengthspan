import SwiftUI

/// An enum whose cases are shown to the user. The string catalog holds "<prefix>.<rawValue>" for each case.
protocol LocalizedOption: CaseIterable, Hashable, RawRepresentable where RawValue == String {
    static var localizationPrefix: String { get }
}

extension LocalizedOption {
    var localizationKey: String { "\(Self.localizationPrefix).\(rawValue)" }
    var titleKey: LocalizedStringKey { LocalizedStringKey(localizationKey) }
}

extension AgeRange: LocalizedOption { static var localizationPrefix: String { "option.ageRange" } }
extension ActivityLevel: LocalizedOption { static var localizationPrefix: String { "option.activity" } }
extension ExperienceLevel: LocalizedOption { static var localizationPrefix: String { "option.experience" } }
extension PrimaryGoal: LocalizedOption { static var localizationPrefix: String { "option.goal" } }
extension Equipment: LocalizedOption { static var localizationPrefix: String { "option.equipment" } }
extension BodyRegion: LocalizedOption { static var localizationPrefix: String { "option.region" } }
extension WorkoutBlock: LocalizedOption { static var localizationPrefix: String { "option.block" } }

extension SessionLength {
    var titleKey: LocalizedStringKey {
        switch self {
        case .short: "option.sessionLength.short"
        case .standard: "option.sessionLength.standard"
        case .long: "option.sessionLength.long"
        }
    }
}

extension ScreeningQuestion {
    var titleKey: LocalizedStringKey { LocalizedStringKey(textKey) }
}

extension ExerciseVariant {
    var nameText: LocalizedStringKey { LocalizedStringKey(nameKey) }
    var instructionText: LocalizedStringKey { LocalizedStringKey(instructionKey) }
    var localizedName: String { String(localized: String.LocalizationValue(nameKey)) }
}

extension Calendar {
    /// Weekday numbers in the order this calendar displays them (e.g. Monday first in Türkiye).
    var orderedWeekdays: [Int] {
        (0..<7).map { (firstWeekday - 1 + $0) % 7 + 1 }
    }

    func weekdayName(_ weekday: Int) -> String {
        weekdaySymbols[weekday - 1]
    }
}
