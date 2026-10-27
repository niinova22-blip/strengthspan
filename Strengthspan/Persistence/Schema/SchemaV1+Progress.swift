import Foundation
import SwiftData

extension SchemaV1 {
    /// A capacity-dimension summary derived from one assessment session.
    /// `score` is `nil` when there isn't enough valid data; the UI must then say so instead of
    /// showing a number. Scores compare the user with themselves only and are not clinical.
    @Model
    final class CapacityMetric {
        @Attribute(.unique) var id: UUID
        var computedAt: Date
        var dimensionRaw: String
        /// 0–100 when present.
        var score: Double?
        var reliabilityRaw: String
        var scoringModelVersion: String
        var sourceSession: AssessmentSession?

        init(
            id: UUID = UUID(),
            computedAt: Date = .now,
            dimension: CapacityDimension,
            score: Double?,
            reliability: MeasurementReliability,
            scoringModelVersion: String
        ) {
            self.id = id
            self.computedAt = computedAt
            self.dimensionRaw = dimension.rawValue
            self.score = score.map { min(max($0, 0), 100) }
            self.reliabilityRaw = reliability.rawValue
            self.scoringModelVersion = scoringModelVersion
        }

        var dimension: CapacityDimension? { CapacityDimension(rawValue: dimensionRaw) }
        var reliability: MeasurementReliability { MeasurementReliability(rawValue: reliabilityRaw) ?? .insufficient }
    }

    /// Summary of a closed four-week period, kept for history and the progress report.
    /// Sessions are referenced by id because one assessment can anchor several snapshots.
    @Model
    final class ProgressSnapshot {
        @Attribute(.unique) var id: UUID
        var createdAt: Date
        var periodStart: Date
        var periodEnd: Date
        var baselineSessionID: UUID?
        var currentSessionID: UUID?
        var plannedSessions: Int
        var completedSessions: Int

        init(
            id: UUID = UUID(),
            createdAt: Date = .now,
            periodStart: Date,
            periodEnd: Date,
            baselineSessionID: UUID?,
            currentSessionID: UUID?,
            plannedSessions: Int,
            completedSessions: Int
        ) {
            self.id = id
            self.createdAt = createdAt
            self.periodStart = periodStart
            self.periodEnd = periodEnd
            self.baselineSessionID = baselineSessionID
            self.currentSessionID = currentSessionID
            self.plannedSessions = plannedSessions
            self.completedSessions = completedSessions
        }
    }
}
