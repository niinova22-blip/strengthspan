import Foundation
import SwiftData

extension SchemaV1 {
    /// One sitting in which the user performs one or more capacity tests.
    @Model
    final class AssessmentSession {
        @Attribute(.unique) var id: UUID
        var startedAt: Date
        /// Set only through `markCompleted(at:)`; non-nil exactly when status is `.completed`.
        private(set) var completedAt: Date?
        private(set) var statusRaw: String
        var isBaseline: Bool
        var deviceModel: String
        var appVersion: String

        @Relationship(deleteRule: .cascade, inverse: \AssessmentResult.session)
        var results: [AssessmentResult] = []

        @Relationship(deleteRule: .cascade, inverse: \CapacityMetric.sourceSession)
        var metrics: [CapacityMetric] = []

        init(
            id: UUID = UUID(),
            startedAt: Date = .now,
            isBaseline: Bool,
            deviceModel: String,
            appVersion: String
        ) {
            self.id = id
            self.startedAt = startedAt
            self.statusRaw = AssessmentStatus.inProgress.rawValue
            self.isBaseline = isBaseline
            self.deviceModel = deviceModel
            self.appVersion = appVersion
        }

        var status: AssessmentStatus {
            AssessmentStatus(rawValue: statusRaw) ?? .abandoned
        }

        func markCompleted(at date: Date) {
            completedAt = date
            statusRaw = AssessmentStatus.completed.rawValue
        }

        func markAbandoned() {
            completedAt = nil
            statusRaw = AssessmentStatus.abandoned.rawValue
        }
    }

    /// The outcome of a single test. Treated as immutable once recorded.
    ///
    /// Two results are comparable only when `assessmentKey`, `definitionVersion`, `method`,
    /// `setupVariant` and `usedSupport` match and both are valid with comparable reliability.
    @Model
    final class AssessmentResult {
        @Attribute(.unique) var id: UUID
        var recordedAt: Date
        var assessmentKey: String
        var definitionVersion: Int
        var methodRaw: String
        var statusRaw: String
        /// Repetitions, seconds or degrees depending on `unit`. `nil` unless status is `.valid`.
        var value: Double?
        var unitRaw: String
        var durationSeconds: Double
        var reliabilityRaw: String
        var qualityFlagsRaw: [String]
        var usedSupport: Bool
        /// Protocol details that affect comparability, e.g. "standard-chair".
        var setupVariant: String
        var session: AssessmentSession?

        init(
            id: UUID = UUID(),
            recordedAt: Date = .now,
            assessmentKey: String,
            definitionVersion: Int,
            method: MeasurementMethod,
            status: AssessmentResultStatus,
            value: Double?,
            unit: MeasurementUnit,
            durationSeconds: Double,
            reliability: MeasurementReliability,
            qualityFlags: [String] = [],
            usedSupport: Bool,
            setupVariant: String
        ) {
            self.id = id
            self.recordedAt = recordedAt
            self.assessmentKey = assessmentKey
            self.definitionVersion = definitionVersion
            self.methodRaw = method.rawValue
            self.statusRaw = status.rawValue
            self.value = status == .valid ? value : nil
            self.unitRaw = unit.rawValue
            self.durationSeconds = durationSeconds
            self.reliabilityRaw = reliability.rawValue
            self.qualityFlagsRaw = qualityFlags
            self.usedSupport = usedSupport
            self.setupVariant = setupVariant
        }

        var method: MeasurementMethod? { MeasurementMethod(rawValue: methodRaw) }
        var status: AssessmentResultStatus { AssessmentResultStatus(rawValue: statusRaw) ?? .rejectedLowQuality }
        var unit: MeasurementUnit? { MeasurementUnit(rawValue: unitRaw) }
        var reliability: MeasurementReliability { MeasurementReliability(rawValue: reliabilityRaw) ?? .insufficient }
    }
}
