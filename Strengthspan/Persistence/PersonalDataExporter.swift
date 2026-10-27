import Foundation
import SwiftData

/// Exports all personal data as human-readable JSON (privacy: right of access / portability).
@MainActor
struct PersonalDataExporter {
    let context: ModelContext

    struct Export: Codable {
        struct Profile: Codable {
            let createdAt: Date
            let ageRange: String
            let activityLevel: String
            let experienceLevel: String
            let primaryGoal: String
            let screeningOutcome: String
            let professionalClearanceConfirmedAt: Date?
            let sessionLengthMinutes: Int?
            let equipment: [String]
            let preferredWeekdays: [Int]
        }

        struct Constraint: Codable {
            let kind: String
            let bodyRegion: String?
            let source: String
            let reportedAt: Date
            let resolvedAt: Date?
        }

        struct WorkoutSet: Codable {
            let exercise: String
            let variant: String
            let setNumber: Int
            let targetReps: Int?
            let actualReps: Int?
            let durationSeconds: Int?
            let loadKg: Double?
            let completedAt: Date?
        }

        struct Workout: Codable {
            let scheduledDate: Date
            let status: String
            let startedAt: Date?
            let completedAt: Date?
            let rpe: Int?
            let discomfort: String?
            let discomfortRegions: [String]
            let dizzinessReported: Bool?
            let note: String?
            let sets: [WorkoutSet]
        }

        struct Result: Codable {
            let test: String
            let version: Int
            let method: String
            let status: String
            let value: Double?
            let unit: String
            let reliability: String
            let recordedAt: Date
        }

        struct Assessment: Codable {
            let startedAt: Date
            let completedAt: Date?
            let isBaseline: Bool
            let results: [Result]
        }

        let exportedAt: Date
        let appVersion: String
        let profile: Profile?
        let safetyConstraints: [Constraint]
        let workouts: [Workout]
        let assessments: [Assessment]
    }

    func makeExport(now: Date) throws -> Export {
        let profile = try context.fetch(FetchDescriptor<UserProfile>()).first
        let constraints = try context.fetch(FetchDescriptor<SafetyConstraint>()).sorted { $0.reportedAt < $1.reportedAt }
        let workouts = try context.fetch(FetchDescriptor<WorkoutSession>())
            .filter { $0.status != .planned }
            .sorted { $0.scheduledDate < $1.scheduledDate }
        let assessments = try context.fetch(FetchDescriptor<AssessmentSession>()).sorted { $0.startedAt < $1.startedAt }

        return Export(
            exportedAt: now,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            profile: profile.map { profile in
                Export.Profile(
                    createdAt: profile.createdAt,
                    ageRange: profile.ageRangeRaw,
                    activityLevel: profile.activityLevelRaw,
                    experienceLevel: profile.experienceLevelRaw,
                    primaryGoal: profile.primaryGoalRaw,
                    screeningOutcome: profile.screeningOutcomeRaw,
                    professionalClearanceConfirmedAt: profile.professionalClearanceConfirmedAt,
                    sessionLengthMinutes: profile.preferences?.sessionLengthMinutes,
                    equipment: profile.preferences?.equipmentRaw ?? [],
                    preferredWeekdays: profile.preferences?.preferredWeekdays ?? []
                )
            },
            safetyConstraints: constraints.map {
                Export.Constraint(kind: $0.kindRaw, bodyRegion: $0.bodyRegionRaw, source: $0.sourceRaw, reportedAt: $0.reportedAt, resolvedAt: $0.resolvedAt)
            },
            workouts: workouts.map { session in
                Export.Workout(
                    scheduledDate: session.scheduledDate,
                    status: session.statusRaw,
                    startedAt: session.startedAt,
                    completedAt: session.completedAt,
                    rpe: session.feedback?.rpe,
                    discomfort: session.feedback?.discomfortRaw,
                    discomfortRegions: session.feedback?.discomfortRegionsRaw ?? [],
                    dizzinessReported: session.feedback?.dizzinessReported,
                    note: session.feedback?.note,
                    sets: session.sets
                        .sorted { ($0.orderIndex, $0.setNumber) < ($1.orderIndex, $1.setNumber) }
                        .map { set in
                            Export.WorkoutSet(
                                exercise: set.exerciseKey,
                                variant: set.variantKey,
                                setNumber: set.setNumber,
                                targetReps: set.targetReps,
                                actualReps: set.actualReps,
                                durationSeconds: set.actualDurationSeconds ?? set.targetDurationSeconds,
                                loadKg: set.actualLoadKg,
                                completedAt: set.completedAt
                            )
                        }
                )
            },
            assessments: assessments.map { session in
                Export.Assessment(
                    startedAt: session.startedAt,
                    completedAt: session.completedAt,
                    isBaseline: session.isBaseline,
                    results: session.results.sorted { $0.recordedAt < $1.recordedAt }.map {
                        Export.Result(test: $0.assessmentKey, version: $0.definitionVersion, method: $0.methodRaw, status: $0.statusRaw, value: $0.value, unit: $0.unitRaw, reliability: $0.reliabilityRaw, recordedAt: $0.recordedAt)
                    }
                )
            }
        )
    }

    func encodedData(now: Date) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(makeExport(now: now))
    }

    /// Writes the export to a temporary file for the share sheet.
    func writeFile(now: Date) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Strengthspan-data.json")
        try encodedData(now: now).write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }
}
