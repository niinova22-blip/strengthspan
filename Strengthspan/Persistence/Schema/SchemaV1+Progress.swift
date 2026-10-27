import Foundation
import SwiftData

extension SchemaV1 {
    /// The value that represents one capacity dimension after an assessment session.
    ///
    /// Strengthspan deliberately shows real test values (e.g. "14 stands in 30 s") instead of an
    /// invented 0–100 score. `value` is `nil` when there was no usable result; the UI must then say
    /// "Not enough measurements yet". Values compare the user with themselves only and are not clinical.
    @Model
    final class CapacityMetric {
        @Attribute(.unique) var id: UUID
        var computedAt: Date
        var dimensionRaw: String
        var assessmentKey: String
        var value: Double?
        var unitRaw: String
        var methodRaw: String
        var reliabilityRaw: String
        var sourceSession: AssessmentSession?

        init(
            id: UUID = UUID(),
            computedAt: Date = .now,
            dimension: CapacityDimension,
            assessmentKey: String,
            value: Double?,
            unit: MeasurementUnit,
            method: MeasurementMethod,
            reliability: MeasurementReliability
        ) {
            self.id = id
            self.computedAt = computedAt
            self.dimensionRaw = dimension.rawValue
            self.assessmentKey = assessmentKey
            self.value = reliability.isComparable ? value : nil
            self.unitRaw = unit.rawValue
            self.methodRaw = method.rawValue
            self.reliabilityRaw = reliability.rawValue
        }

        var dimension: CapacityDimension? { CapacityDimension(rawValue: dimensionRaw) }
        var unit: MeasurementUnit? { MeasurementUnit(rawValue: unitRaw) }
        var method: MeasurementMethod? { MeasurementMethod(rawValue: methodRaw) }
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
