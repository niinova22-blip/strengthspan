import Foundation
import SwiftData

extension SchemaV1 {
    /// The single local user. Created at the end of onboarding; there is no account.
    @Model
    final class UserProfile {
        @Attribute(.unique) var id: UUID
        var createdAt: Date
        var updatedAt: Date
        var ageRangeRaw: String
        var activityLevelRaw: String
        var experienceLevelRaw: String
        var primaryGoalRaw: String
        var screeningOutcomeRaw: String
        var safetyScreeningCompletedAt: Date?
        /// When the user confirmed a health professional cleared them to exercise (docs/05 §2).
        var professionalClearanceConfirmedAt: Date?
        var onboardingCompletedAt: Date?

        @Relationship(deleteRule: .cascade, inverse: \UserPreferences.profile)
        var preferences: UserPreferences?

        @Relationship(deleteRule: .cascade, inverse: \SafetyConstraint.profile)
        var safetyConstraints: [SafetyConstraint] = []

        init(
            id: UUID = UUID(),
            createdAt: Date = .now,
            ageRange: AgeRange,
            activityLevel: ActivityLevel,
            experienceLevel: ExperienceLevel,
            primaryGoal: PrimaryGoal,
            screeningOutcome: ScreeningOutcome = .notScreened
        ) {
            self.id = id
            self.createdAt = createdAt
            self.updatedAt = createdAt
            self.ageRangeRaw = ageRange.rawValue
            self.activityLevelRaw = activityLevel.rawValue
            self.experienceLevelRaw = experienceLevel.rawValue
            self.primaryGoalRaw = primaryGoal.rawValue
            self.screeningOutcomeRaw = screeningOutcome.rawValue
        }

        var ageRange: AgeRange? {
            get { AgeRange(rawValue: ageRangeRaw) }
            set { ageRangeRaw = newValue?.rawValue ?? "" }
        }

        var activityLevel: ActivityLevel? {
            get { ActivityLevel(rawValue: activityLevelRaw) }
            set { activityLevelRaw = newValue?.rawValue ?? "" }
        }

        var experienceLevel: ExperienceLevel? {
            get { ExperienceLevel(rawValue: experienceLevelRaw) }
            set { experienceLevelRaw = newValue?.rawValue ?? "" }
        }

        var primaryGoal: PrimaryGoal? {
            get { PrimaryGoal(rawValue: primaryGoalRaw) }
            set { primaryGoalRaw = newValue?.rawValue ?? "" }
        }

        /// Unknown values fall back to `.notScreened`, the most restrictive state.
        var screeningOutcome: ScreeningOutcome {
            get { ScreeningOutcome(rawValue: screeningOutcomeRaw) ?? .notScreened }
            set { screeningOutcomeRaw = newValue.rawValue }
        }
    }

    @Model
    final class UserPreferences {
        @Attribute(.unique) var id: UUID
        var updatedAt: Date
        var weeklySessionTarget: Int
        var sessionLengthMinutes: Int
        var equipmentRaw: [String]
        /// `Calendar` weekday numbers (1 = Sunday ... 7 = Saturday).
        var preferredWeekdays: [Int]
        var voiceGuidanceEnabled: Bool
        var hapticsEnabled: Bool
        /// Off by default; turned on only after the user grants Apple Health permission.
        var saveToHealthEnabled: Bool = false
        var profile: UserProfile?

        init(
            id: UUID = UUID(),
            updatedAt: Date = .now,
            weeklySessionTarget: Int,
            sessionLength: SessionLength,
            equipment: Set<Equipment>,
            preferredWeekdays: [Int],
            voiceGuidanceEnabled: Bool = true,
            hapticsEnabled: Bool = true
        ) {
            self.id = id
            self.updatedAt = updatedAt
            self.weeklySessionTarget = weeklySessionTarget
            self.sessionLengthMinutes = sessionLength.rawValue
            self.equipmentRaw = equipment.map(\.rawValue).sorted()
            self.preferredWeekdays = preferredWeekdays.sorted()
            self.voiceGuidanceEnabled = voiceGuidanceEnabled
            self.hapticsEnabled = hapticsEnabled
        }

        var sessionLength: SessionLength {
            get { SessionLength(rawValue: sessionLengthMinutes) ?? .short }
            set { sessionLengthMinutes = newValue.rawValue }
        }

        var equipment: Set<Equipment> {
            get { Set(equipmentRaw.compactMap(Equipment.init(rawValue:))) }
            set { equipmentRaw = newValue.map(\.rawValue).sorted() }
        }
    }

    /// A user-reported limitation that the safety engine must respect.
    /// Constraints are resolved rather than deleted so past safety decisions stay explainable.
    @Model
    final class SafetyConstraint {
        @Attribute(.unique) var id: UUID
        var kindRaw: String
        var bodyRegionRaw: String?
        var sourceRaw: String
        var reportedAt: Date
        var resolvedAt: Date?
        var note: String?
        var profile: UserProfile?

        init(
            id: UUID = UUID(),
            kind: SafetyConstraintKind,
            bodyRegion: BodyRegion? = nil,
            source: ConstraintSource,
            reportedAt: Date = .now,
            note: String? = nil
        ) {
            self.id = id
            self.kindRaw = kind.rawValue
            self.bodyRegionRaw = bodyRegion?.rawValue
            self.sourceRaw = source.rawValue
            self.reportedAt = reportedAt
            self.note = note
        }

        /// Unknown kinds are treated as `.other` so they still restrict training.
        var kind: SafetyConstraintKind {
            SafetyConstraintKind(rawValue: kindRaw) ?? .other
        }

        var bodyRegion: BodyRegion? {
            bodyRegionRaw.flatMap(BodyRegion.init(rawValue:))
        }

        var source: ConstraintSource? {
            ConstraintSource(rawValue: sourceRaw)
        }

        var isActive: Bool { resolvedAt == nil }
    }
}
